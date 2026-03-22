# Digital Rendering Engineering: The Physics of Light
## Companion Code — Validated HLSL Implementations

[![White Furnace Test](https://img.shields.io/badge/White%20Furnace%20Test-PASSING-brightgreen?style=flat-square)](tests/test_white_furnace.py)
[![Energy Conservation](https://img.shields.io/badge/Energy%20Conservation-VERIFIED-brightgreen?style=flat-square)](VALIDATION_SUMMARY.md)
[![Tests](https://img.shields.io/badge/Tests-18%2F18%20Passed-success?style=flat-square)](tests/)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)

**github.com/OpticsOptimizationLab/dre-physics-of-light**

Companion repository for **Digital Rendering Engineering: The Physics of Light** by JM Sage.
All implementations include automated energy conservation tests.

---

## Quick Start

Copy `DRE_Vol1_Complete.hlsl` into your project:

```hlsl
#include "DRE_Vol1_Complete.hlsl"

// All functions are immediately available:
float3 brdf = EvaluateCookTorrance(L, V, N, F0, roughness);
float3 H = SampleVNDF(V, alpha, alpha, u);
float3 origin = OffsetRayOrigin(hitPos, hitNormal);
float energy = RunWhiteFurnaceTest(0.5f, 0.5f, 4096); // should return ~0.921
```

---

## Repository Structure

```
DRE_Vol1_Complete.hlsl Single assembly file — copy this into your project
│
hlsl/
├── ch05_fresnel/
│ └── F_Schlick.hlsl Schlick + FresnelConductorF0 (complex IOR)
├── ch06_brdf/
│ ├── D_GGX.hlsl Trowbridge-Reitz NDF
│ ├── V_SmithGGX_Correlated.hlsl Height-correlated Smith G2
│ └── CookTorrance_BRDF.hlsl Complete specular BRDF assembly
├── ch07_integration/
│ ├── PowerHeuristic.hlsl MIS power heuristic (beta=2)
│ ├── RussianRoulette.hlsl Unbiased path termination
│ ├── SobolSampler.hlsl Owen-scrambled Sobol QMC
│ └── TemporalAccumulate.hlsl Variance-based TAA with AABB clamp
├── ch09_validation/
│ ├── SampleVNDF.hlsl Heitz (2018) visible normal sampling
│ └── RunWhiteFurnaceTest.hlsl Energy conservation validator
└── ch10_utils/
└── OffsetRayOrigin.hlsl Wächter & Binder (2019) ULP ray offset

tests/
├── test_white_furnace.py Monte Carlo energy conservation test
├── run_all_tests.py Run all tests
└── requirements.txt
```

---

## DXC Compilation

All functions compile without errors or warnings under DirectX Shader Compiler (DXC) 1.8, Shader Model 6.0:

```bash
dxc -T cs_6_0 -E CSMain hlsl/_dxc_validation_wrapper.hlsl -Fo /dev/null
# no output = clean compile
```

The wrapper (`hlsl/_dxc_validation_wrapper.hlsl`) provides a valid compute shader entry point that exercises every function in the assembly.

## Validation Tests

Run the test suite (requires Python and numpy):

```bash
pip install numpy
python tests/run_all_tests.py
```

Expected output:
```
roughness 0.1 NdotV 0.5 0.9991 [PASS]
roughness 0.5 NdotV 0.5 0.9213 [PASS]
roughness 1.0 NdotV 0.5 0.8012 [PASS]
...
ALL TESTS PASSED
```

The single-scattering Smith G₂ model returns below 1.0 for rough surfaces —
this is the documented Kulla-Conty deficit (Chapter 6.2.3), not an error.
Results **above 1.001** indicate an energy gain and are a hard failure.

---

## Cross-Reference: Book Code

| Chapter | Section | File |
|---------|---------|------|
| Chapter 5 | 5.3.2 Fresnel | `hlsl/ch05_fresnel/F_Schlick.hlsl` |
| Chapter 6 | 6.2.1 GGX NDF | `hlsl/ch06_brdf/D_GGX.hlsl` |
| Chapter 6 | 6.2.2 Smith G₂ | `hlsl/ch06_brdf/V_SmithGGX_Correlated.hlsl` |
| Chapter 4 / 6 | 4.3.2, 6.2.1–3 Cook-Torrance | `hlsl/ch06_brdf/CookTorrance_BRDF.hlsl` |
| Chapter 7 | 7.2.1 MIS | `hlsl/ch07_integration/PowerHeuristic.hlsl` |
| Chapter 7 | 7.1 Russian Roulette | `hlsl/ch07_integration/RussianRoulette.hlsl` |
| Chapter 7 | 7.1 Sobol QMC | `hlsl/ch07_integration/SobolSampler.hlsl` |
| Chapter 7 | 7.3.2 Temporal | `hlsl/ch07_integration/TemporalAccumulate.hlsl` |
| Chapter 9 | 9.2 VNDF Sampling | `hlsl/ch09_validation/SampleVNDF.hlsl` |
| Chapter 9 | 9.1 White Furnace | `hlsl/ch09_validation/RunWhiteFurnaceTest.hlsl` |
| Chapter 10 | Shadow Bias | `hlsl/ch10_utils/OffsetRayOrigin.hlsl` |

---

## Why Choose DRE?

### **Proven Accuracy**
- **White Furnace Test: 18/18 PASSED** (energy conservation verified)
- Zero energy gain (all results < 1.001)
- Numerical stability at extreme angles
- [See full validation report](VALIDATION_SUMMARY.md)

### **Industry-Standard Implementation**
- Height-correlated Smith G₂ (Heitz 2014)
- GGX/Trowbridge-Reitz NDF (Walter et al. 2007)
- Schlick Fresnel approximation
- VNDF importance sampling (Heitz 2018)
- Register-optimized for GPU execution

### **Educational Clarity**
- Code matches manuscript equations 1:1
- Every function documented with paper references
- No "black box" implementations
- Self-contained: zero external dependencies

### **Automated Quality Assurance**
- CI/CD runs White Furnace Test on every commit
- Real-time test status badges
- Comprehensive validation reports
- [See benchmark results](BENCHMARKS.md)

### **Citation-Ready**
- `CITATION.cff` for academic papers
- DOI-ready metadata
- Suitable for research use
- [Cite this repository](CITATION.cff)

### **100% Open Source**
- MIT License
- No proprietary dependencies
- Full transparency
- Community-driven improvements

Only PBR implementation with automated energy conservation validation and continuous testing.

---

## Documentation

- [**VALIDATION_SUMMARY.md**](VALIDATION_SUMMARY.md) — White Furnace Test results & component verification
- [**BENCHMARKS.md**](BENCHMARKS.md) — Test methodology & measured results
- [**CITATION.cff**](CITATION.cff) — How to cite this work in academic papers

---

## Key References

- Cook & Torrance (1982). *A Reflectance Model for Computer Graphics.* ACM TOG.
- Heitz, E. (2014). *Understanding the Masking-Shadowing Function.* JCGT 3(2).
- Heitz, E. (2018). *Sampling the GGX Distribution of Visible Normals.* JCGT 7(4).
- Kulla, C. & Conty, A. (2017). *Revisiting Physically Based Shading at Imageworks.* SIGGRAPH.
- Lagarde, S. & de Rousiers, C. (2014). *Moving Frostbite to PBR.* SIGGRAPH.
- Veach, E. & Guibas, L. (1995). *Optimally Combining Sampling Techniques.* SIGGRAPH.
- Wächter, C. & Binder, N. (2019). *A Fast and Robust Method for Avoiding Self-Intersection.* Ray Tracing Gems, Ch. 6.
- Pharr, M., Jakob, W., & Humphreys, G. (2023). *Physically Based Rendering, 4th Ed.*

---

*Digital Rendering Engineering: The Physics of Light — JM Sage*
*Published by Optics Optimization Laboratory*
