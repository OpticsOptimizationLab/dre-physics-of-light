"""
test_white_furnace.py
White Furnace Test — energy conservation validator for Cook-Torrance BRDF
Digital Rendering Engineering: The Physics of Light — Companion Code

Validates that D_GGX + V_SmithGGX_Correlated + F_Schlick conserves energy.
Method: GGX NDF importance sampling.
  - Sample H from GGX NDF: cos_theta = sqrt((1-u) / ((a2-1)*u + 1))
  - pdf(H) = D(H) * NdotH
  - pdf(L) = D(H) * NdotH / (4 * VdotH)
  - contribution = f_r * NdotL / pdf(L) = Vis * NdotL * 4 * VdotH / NdotH

Expected results (NdotV=0.5, N=8192) — single-scattering Smith G2:
  roughness 0.1 -> ~0.999  | roughness 0.5 -> ~0.921  | roughness 1.0 -> ~0.801
Results > 1.001 = energy gain = implementation error.

Run: python tests/test_white_furnace.py
Requirements: pip install numpy
"""

import numpy as np
import sys

PI = np.pi

ROUGHNESS_VALUES = [0.1, 0.3, 0.5, 0.7, 0.9, 1.0]
NDOTV_VALUES     = [0.2, 0.5, 0.9]
SAMPLE_COUNT     = 8192
# Hard criterion: result > 1.001 means energy gain — always an implementation error.
# Result < 1.0 is the Smith single-scattering deficit — physically correct, not a failure.
# The deficit magnitude depends on the roughness->alpha remapping (alpha = roughness^2 here).
TOLERANCE        = 1.001


# ── Quasi-random sampler (Hammersley) ──────────────────────────────────────────

def radical_inverse_base2(n: int) -> np.ndarray:
    bits = np.arange(n, dtype=np.uint32)
    bits = (bits << 16) | (bits >> 16)
    bits = ((bits & np.uint32(0x55555555)) << 1) | ((bits >> 1) & np.uint32(0x55555555))
    bits = ((bits & np.uint32(0x33333333)) << 2) | ((bits >> 2) & np.uint32(0x33333333))
    bits = ((bits & np.uint32(0x0F0F0F0F)) << 4) | ((bits >> 4) & np.uint32(0x0F0F0F0F))
    bits = ((bits & np.uint32(0x00FF00FF)) << 8) | ((bits >> 8) & np.uint32(0x00FF00FF))
    return bits.astype(np.float64) / 4294967296.0


def hammersley_2d(n: int) -> np.ndarray:
    u1 = np.arange(n, dtype=np.float64) / n
    u2 = radical_inverse_base2(n)
    return np.column_stack([u1, u2])


# ── BRDF functions (match DRE_Vol1_Complete.hlsl) ─────────────────────────────

def D_GGX(NdotH: np.ndarray, alpha: float) -> np.ndarray:
    """Trowbridge-Reitz GGX NDF. Chapter 6.2.1."""
    a2    = alpha * alpha
    denom = NdotH * NdotH * (a2 - 1.0) + 1.0
    return a2 / (PI * np.maximum(denom * denom, 1e-10))


def V_SmithGGX_Correlated(NdotL: np.ndarray, NdotV: float, alpha: float) -> np.ndarray:
    """
    Height-correlated Smith G2 combined visibility term.
    Returns G2 / (4 * NdotL * NdotV). Full BRDF = D * Vis * F.
    Chapter 6.2.2 | Lagarde & de Rousiers (2014), Frostbite PBR.
    """
    a2      = alpha * alpha
    lambdaV = NdotL * np.sqrt(np.maximum(NdotV * (NdotV - NdotV * a2) + a2, 1e-10))
    lambdaL = NdotV * np.sqrt(np.maximum(NdotL * (NdotL - NdotL * a2) + a2, 1e-10))
    return 0.5 / np.maximum(lambdaV + lambdaL, 1e-10)


# ── GGX NDF importance sampling ───────────────────────────────────────────────

def sample_GGX_NDF(alpha: float, u: np.ndarray):
    """
    Sample half-vector H from GGX NDF distribution.
    cos_theta follows from the GGX CDF inversion:
      cos^2(theta) = (1 - u) / (1 + u * (a2 - 1))
    Returns (Hx, Hy, Hz) in tangent space.
    """
    a2         = alpha * alpha
    cos2_theta = (1.0 - u[:, 0]) / np.maximum(1.0 + u[:, 0] * (a2 - 1.0), 1e-10)
    cos_theta  = np.sqrt(np.maximum(cos2_theta, 0.0))
    sin_theta  = np.sqrt(np.maximum(1.0 - cos2_theta, 0.0))
    phi        = 2.0 * PI * u[:, 1]
    return sin_theta * np.cos(phi), sin_theta * np.sin(phi), cos_theta


def white_furnace_test(roughness: float, NdotV: float, N: int = 8192) -> float:
    """
    Monte Carlo White Furnace Test.

    Sampling:    H sampled from GGX NDF importance distribution
    pdf(L):      D(H) * NdotH / (4 * VdotH)
    Contribution: f_r(V,L) * NdotL / pdf(L) = Vis * NdotL * 4 * VdotH / NdotH
    F0 = 1 (white furnace: maximum reflectance, no absorption)

    Expected value = integral(f_r * NdotL d_omega_L) = Smith G2 deficit value.
    """
    alpha = roughness * roughness
    Vx    = float(np.sqrt(max(0.0, 1.0 - NdotV * NdotV)))

    u = hammersley_2d(N)

    # Sample H from GGX NDF
    Hx, Hy, Hz = sample_GGX_NDF(alpha, u)
    NdotH = Hz  # = cos(theta_H) in tangent space

    # Reflect V over H to get L: L = 2*(V·H)*H - V
    VdotH = Vx * Hx + NdotV * Hz
    Lx    = 2.0 * VdotH * Hx - Vx
    Ly    = 2.0 * VdotH * Hy
    Lz    = 2.0 * VdotH * Hz - NdotV  # NdotL
    valid = Lz > 1e-6

    NdotL     = np.maximum(Lz, 1e-6)
    VdotH_pos = np.maximum(VdotH, 1e-7)
    NdotH_pos = np.maximum(NdotH, 1e-7)

    Vis = V_SmithGGX_Correlated(NdotL, NdotV, alpha)

    # contribution = f_r * NdotL / pdf(L)
    # f_r = D * Vis * F,  pdf(L) = D * NdotH / (4 * VdotH)
    # D cancels: contribution = Vis * F * NdotL * 4 * VdotH / NdotH
    # F = 1 (white furnace)
    contribution = np.where(valid,
                            Vis * NdotL * 4.0 * VdotH_pos / NdotH_pos,
                            0.0)

    return float(np.mean(contribution))


# ── Test runner ────────────────────────────────────────────────────────────────

def run_suite() -> int:
    print("=" * 65)
    print("  White Furnace Test — DRE Vol.1 Companion Code")
    print("  github.com/OpticsOptimizationLab/dre-physics-of-light")
    print("=" * 65)
    print(f"  Method: GGX NDF importance sampling | N={SAMPLE_COUNT} | tol={TOLERANCE}")
    print("-" * 65)
    print(f"  {'roughness':>10}  {'NdotV':>6}  {'result':>8}  {'status':>12}")
    print("-" * 65)

    failures = []
    all_pass = True

    for r in ROUGHNESS_VALUES:
        for ndotv in NDOTV_VALUES:
            result = white_furnace_test(roughness=r, NdotV=ndotv, N=SAMPLE_COUNT)

            if result > TOLERANCE:
                status   = "FAIL (gain)"
                all_pass = False
                failures.append((r, ndotv, result, "energy gain > 1.001"))
            else:
                # Result < 1.0 is the Smith single-scattering deficit — physical, not a bug
                status = "PASS"

            print(f"  {r:>10.1f}  {ndotv:>6.1f}  {result:>8.4f}  {status:>12}")

    print("-" * 65)
    if all_pass:
        print("  ALL TESTS PASSED")
    else:
        print(f"  {len(failures)} FAILURE(s):")
        for r, ndotv, res, reason in failures:
            print(f"    roughness={r:.1f}, NdotV={ndotv:.1f}: {res:.4f} ({reason})")
    print("=" * 65)
    return 0 if all_pass else 1


if __name__ == "__main__":
    sys.exit(run_suite())
