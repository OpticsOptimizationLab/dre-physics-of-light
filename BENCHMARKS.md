# Performance Benchmarks

**Test Platform:** Python 3.11, NumPy 2.3.5
**Date:** 2026-03-22

---

## White Furnace Test Results

**Method:** Monte Carlo integration with GGX NDF importance sampling
**Samples:** 8192 per configuration (QMC Hammersley sequence)
**Criterion:** Energy conservation verified (result ≤ 1.001)

### Full Test Results

| roughness | NdotV | Result | Status |
|---|---|---|---|
| 0.1 | 0.2 | 0.9986 | PASS |
| 0.1 | 0.5 | 0.9998 | PASS |
| 0.1 | 0.9 | 0.9999 | PASS |
| 0.3 | 0.2 | 0.9155 | PASS |
| 0.3 | 0.5 | 0.9747 | PASS |
| 0.3 | 0.9 | 0.9894 | PASS |
| 0.5 | 0.2 | 0.8479 | PASS |
| 0.5 | 0.5 | 0.8572 | PASS |
| 0.5 | 0.9 | 0.9074 | PASS |
| 0.7 | 0.2 | 0.7928 | PASS |
| 0.7 | 0.5 | 0.7040 | PASS |
| 0.7 | 0.9 | 0.6933 | PASS |
| 0.9 | 0.2 | 0.6975 | PASS |
| 0.9 | 0.5 | 0.5353 | PASS |
| 0.9 | 0.9 | 0.4356 | PASS |
| 1.0 | 0.2 | 0.6417 | PASS |
| 1.0 | 0.5 | 0.4507 | PASS |
| 1.0 | 0.9 | 0.3276 | PASS |

**Result:** 18/18 configurations PASSED

**Interpretation:**
- All results < 1.001 (no energy gain detected)
- Results < 1.0 are expected (Smith G₂ single-scattering deficit)
- Smooth surfaces (roughness=0.1) approach 1.0 (near-perfect conservation)
- Rough surfaces (roughness=1.0) show larger deficit (expected physical behavior)

---

## BRDF Component Register Costs

Estimated from DXC -O3 assembly output (Shader Model 6.0):

| Function | Registers | Notes |
|---|---|---|
| D_GGX | ~8 | One division, minimal temporaries |
| V_SmithGGX_Correlated | ~10 | Two sqrt operations |
| F_Schlick | ~6 | pow(x,5) optimized to 4 multiplies |
| EvaluateCookTorrance | ~16 | D+F+V combined, compiler reuses intermediates |
| PathTrace (5 bounces) | ~38-44 | Full path tracer with bounce loop |

**Note:** Actual register allocation may vary depending on driver optimization passes.

---

## Test Methodology

**White Furnace Test:**
1. Uniform white environment (radiance = 1.0 from all directions)
2. Surface with albedo = 1.0 (perfect reflector)
3. Measure average reflected radiance via Monte Carlo integration
4. Expected: result ≤ 1.0 (energy conservation)
5. Tolerance: ≤ 1.001 (0.1% margin for Monte Carlo noise)

**Implementation:**
- Sampling: H sampled from GGX NDF distribution
- PDF: D(H) · NdotH / (4 · VdotH)
- Contribution: f_r · NdotL / pdf(L) = Vis · NdotL · 4 · VdotH / NdotH
- Convergence: 8192 samples provides < 0.01 variance

**Why This Matters:**
- Energy gain (result > 1.001) = implementation bug
- Energy conservation is the fundamental requirement for physical correctness
- Many real-world BRDF implementations fail this test

---

## References

Test methodology based on:
- Walter et al. (2007). "Microfacet Models for Refraction through Rough Surfaces." EGSR.
- Heitz, E. (2014). "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs." JCGT 3(2).
- Lagarde, S. & de Rousiers, C. (2014). "Moving Frostbite to Physically Based Rendering." SIGGRAPH Course.

For detailed validation, see [`VALIDATION_SUMMARY.md`](VALIDATION_SUMMARY.md).
