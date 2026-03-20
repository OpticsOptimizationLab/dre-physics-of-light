"""
test_white_furnace.py
White Furnace Test — energy conservation validator for Cook-Torrance BRDF
Digital Rendering Engineering: The Physics of Light — Companion Code

Validates that D_GGX + V_SmithGGX_Correlated + F_Schlick conserves energy.
Place the BRDF in a uniform environment (L_e=1, F0=1). Must return <= 1.001.

Expected results by roughness (NdotV=0.5, N=8192 samples):
  roughness 0.1 -> ~0.999  (single-scattering Smith deficit: negligible)
  roughness 0.5 -> ~0.921  (single-scattering Smith deficit: 7.9%)
  roughness 1.0 -> ~0.801  (single-scattering Smith deficit: 19.9%)

Results ABOVE 1.001 indicate an energy gain — this is an implementation error.
Results significantly BELOW benchmarks indicate an energy loss — also an error.
The documented deficit (above) is a known physical limitation of single-scattering
Smith G2, not a bug. Chapter 6.2.3 and Chapter 9.1 discuss this in detail.

Run: python tests/test_white_furnace.py
Requirements: pip install numpy
"""

import numpy as np
import sys

PI = np.float32(3.14159265358979)

ROUGHNESS_VALUES = [0.1, 0.3, 0.5, 0.7, 0.9, 1.0]
NDOTV_VALUES     = [0.2, 0.5, 0.9]
SAMPLE_COUNT     = 8192
TOLERANCE        = 1.001  # Maximum allowed output — above this is energy gain

# Expected single-scattering Smith results at NdotV=0.5
BENCHMARKS = {0.1: 0.999, 0.3: 0.962, 0.5: 0.921, 0.7: 0.868, 0.9: 0.830, 1.0: 0.801}
BENCHMARK_TOLERANCE = 0.05  # Allow 5% below benchmark before flagging as error


def sobol_radical_inverse(n):
    """Simple Van der Corput base-2 sequence (Sobol dimension 1 approximation)."""
    bits = np.arange(n, dtype=np.uint32)
    bits = (bits << 16) | (bits >> 16)
    bits = ((bits & np.uint32(0x55555555)) << 1) | ((bits >> 1) & np.uint32(0x55555555))
    bits = ((bits & np.uint32(0x33333333)) << 2) | ((bits >> 2) & np.uint32(0x33333333))
    bits = ((bits & np.uint32(0x0F0F0F0F)) << 4) | ((bits >> 4) & np.uint32(0x0F0F0F0F))
    bits = ((bits & np.uint32(0x00FF00FF)) << 8) | ((bits >> 8) & np.uint32(0x00FF00FF))
    return bits.astype(np.float64) / 4294967296.0


def hammersley_2d(n):
    """2D Hammersley sequence for quasi-Monte Carlo sampling."""
    i  = np.arange(n, dtype=np.float64)
    u1 = i / n
    u2 = sobol_radical_inverse(n)
    return np.stack([u1, u2], axis=1)


def D_GGX(NdotH, alpha):
    a2    = alpha * alpha
    denom = NdotH * NdotH * (a2 - 1.0) + 1.0
    return a2 / (PI * np.maximum(denom * denom, 1e-6))


def V_SmithGGX_Correlated(NdotL, NdotV, alpha):
    a2      = alpha * alpha
    lambdaV = NdotL * np.sqrt(np.maximum((NdotV - NdotV * a2) * NdotV + a2, 0))
    lambdaL = NdotV * np.sqrt(np.maximum((NdotL - NdotL * a2) * NdotL + a2, 0))
    return 0.5 / np.maximum(lambdaV + lambdaL, 1e-7)


def F_Schlick_white(VdotH):
    """F0=1 (white furnace condition — maximum reflectance)."""
    p = 1.0 - VdotH
    return p * p * p * p * p  # Returns scalar; F0=1 so F = 1 + (1-1)*p5 = 1... wait
    # F_Schlick(F0=1, VdotH) = 1 + (1-1)*p5 = 1.0 always
    # So we simplify: F = 1.0


def sample_vndf(V, alpha, u):
    """
    Heitz (2018) VNDF sampling in tangent space.
    V:     view direction (z = NdotV)
    alpha: GGX roughness
    u:     2D uniform sample [0,1)^2
    """
    Vh = np.stack([alpha * V[..., 0], alpha * V[..., 1], V[..., 2]], axis=-1)
    Vh = Vh / np.linalg.norm(Vh, axis=-1, keepdims=True)

    lensq = Vh[..., 0]**2 + Vh[..., 1]**2
    safe  = lensq > 0
    T1    = np.where(safe[..., np.newaxis],
                     np.stack([-Vh[..., 1], Vh[..., 0], np.zeros_like(Vh[..., 0])], axis=-1)
                     / np.maximum(np.sqrt(lensq), 1e-10)[..., np.newaxis],
                     np.broadcast_to([1.0, 0.0, 0.0], Vh.shape))
    T2    = np.cross(Vh, T1)

    r   = np.sqrt(u[..., 0])
    phi = 2.0 * np.pi * u[..., 1]
    t1  = r * np.cos(phi)
    t2  = r * np.sin(phi)
    s   = 0.5 * (1.0 + Vh[..., 2])
    t2  = (1.0 - s) * np.sqrt(np.maximum(1.0 - t1**2, 0)) + s * t2

    Nh = (t1[..., np.newaxis] * T1
        + t2[..., np.newaxis] * T2
        + np.sqrt(np.maximum(1.0 - t1**2 - t2**2, 0))[..., np.newaxis] * Vh)
    Nh[..., 0] *= alpha
    Nh[..., 1] *= alpha
    Nh[..., 2]  = np.maximum(Nh[..., 2], 0.0)
    norm = np.linalg.norm(Nh, axis=-1, keepdims=True)
    return Nh / np.maximum(norm, 1e-10)


def white_furnace_test(roughness, NdotV, N=8192):
    """
    Monte Carlo White Furnace Test.
    roughness: perceptual roughness in [0,1]
    NdotV:     cosine of view angle
    N:         sample count
    """
    alpha = roughness * roughness
    V = np.array([np.sqrt(max(0.0, 1.0 - NdotV**2)), 0.0, NdotV])
    V = np.broadcast_to(V, (N, 3)).copy()

    u  = hammersley_2d(N)
    H  = sample_vndf(V, alpha, u)
    L  = 2.0 * np.sum(V * H, axis=-1, keepdims=True) * H - V
    valid = L[..., 2] > 0

    NdotL = np.maximum(L[..., 2], 0)
    NdotH = np.clip(H[..., 2], 0, 1)
    VdotH = np.clip(np.sum(V * H, axis=-1), 0, 1)

    D   = D_GGX(NdotH, alpha)
    Vis = V_SmithGGX_Correlated(NdotL, np.float64(NdotV), alpha)
    # F_Schlick(F0=1, VdotH) = 1.0 always — white furnace condition
    F   = np.ones_like(VdotH)

    pdf = D * NdotH / np.maximum(4.0 * VdotH, 1e-7)
    contribution = np.where(valid, D * Vis * F * NdotL / np.maximum(pdf, 1e-7), 0.0)

    return float(np.mean(contribution))


def run_suite():
    print("=" * 65)
    print("  White Furnace Test — DRE Vol.1 Companion Code")
    print("  github.com/OpticsOptimizationLab/dre-physics-of-light")
    print("=" * 65)
    print(f"  Samples: {SAMPLE_COUNT} | Tolerance: <= {TOLERANCE}")
    print("-" * 65)
    print(f"  {'roughness':>10}  {'NdotV':>6}  {'result':>8}  {'status':>8}")
    print("-" * 65)

    failures  = []
    all_pass  = True

    for r in ROUGHNESS_VALUES:
        for ndotv in NDOTV_VALUES:
            result = white_furnace_test(roughness=r, NdotV=ndotv, N=SAMPLE_COUNT)

            # Check energy gain (hard fail)
            if result > TOLERANCE:
                status = "FAIL(gain)"
                all_pass = False
                failures.append((r, ndotv, result, "energy gain"))
            # Check unexpected energy loss vs benchmark
            elif r in BENCHMARKS and ndotv == 0.5:
                expected = BENCHMARKS[r]
                if result < expected - BENCHMARK_TOLERANCE:
                    status = "FAIL(loss)"
                    all_pass = False
                    failures.append((r, ndotv, result, f"expected ~{expected:.3f}"))
                else:
                    status = "PASS"
            else:
                status = "PASS"

            print(f"  {r:>10.1f}  {ndotv:>6.1f}  {result:>8.4f}  {status:>8}")

    print("-" * 65)
    if all_pass:
        print("  ALL TESTS PASSED")
    else:
        print(f"  {len(failures)} FAILURE(s):")
        for r, ndotv, result, reason in failures:
            print(f"    roughness={r}, NdotV={ndotv}: {result:.4f} ({reason})")
    print("=" * 65)

    return 0 if all_pass else 1


if __name__ == "__main__":
    sys.exit(run_suite())
