# DRE Vol. 1 — Shader Performance Profile

## Purpose

Instruction counts, register usage, and occupancy estimates for each DRE function.
Use `DRE_Profiling_Harness.hlsl` to validate these numbers on your target GPU.

---

## Methodology

**Tool:** NSight Graphics (NVIDIA) or PIX for Windows (AMD/Intel)
**Dispatch:** 1920×1080 / (8×8) = 240×135 threadgroups per kernel (except CS_WhiteFurnace: 1×1)
**Shader Model:** SM6.0, compiled with DXC 1.8
**Measurement:** Shader Profiler → "Registers Per Thread" + "Theoretical Occupancy"

**To capture with NSight Graphics:**
1. Launch app with NSight Graphics attached
2. Trigger a frame capture
3. Shader Profiler → select the dispatch → read "Registers Per Thread" and "Theoretical Occupancy"

**To capture with PIX for Windows:**
1. GPU Capture → select compute dispatch → Pipeline Statistics → Shader tab

---

## Estimated Results — Ampere GA102 (RTX 3090)

> **NOTE:** Values marked `[est.]` are derived from manual instruction counting of the
> DXC-compiled DXIL + published Ampere SM architecture documentation (NVIDIA 2020).
> They are **not** NSight measurements. Run `DRE_Profiling_Harness.hlsl` to validate.
> Values marked `[meas.]` have been confirmed with the profiling harness.

### Occupancy model (Ampere GA102)
- 65,536 registers per SM | 1,536 max threads per SM | 32 threads/warp
- For 8×8 = 64-thread threadgroups: register pressure limits occupancy when
  registers/thread > 42 (= 65536 / 24 threadgroups × 64 threads)
- Below 42 registers: theoretical occupancy is **100%** in isolation
- In a full path tracing kernel (multiple functions combined): occupancy drops
  proportionally to total register demand across the compiled shader

| Function | Registers | Occupancy (isolated) | Instructions | Notes |
|---|---|---|---|---|
| `D_GGX` | 8 [est.] | ~100% [est.] | ~7 [est.] | 1 RCP, 3 MAD, 1 MUL |
| `V_SmithGGX_Correlated` | 12 [est.] | ~100% [est.] | ~14 [est.] | 2× SQRT dominate cost |
| `F_Schlick` | 10 [est.] | ~100% [est.] | ~9 [est.] | Scalar pow5 + vec3 MAD |
| `EvaluateCookTorrance` | 16 [est.] | ~100% [est.] | ~26 [est.] | D+V+F + normalize + 4 dots |
| `EvaluateCookTorrance_MS` (+ KC) | 20 [est.] | ~100% [est.] | ~38 [est.] | +12 ALU for Kulla-Conty |
| `SampleVNDF` | 18 [est.] | ~100% [est.] | ~24 [est.] | rsqrt + cross + sincos + normalize |
| `WaveRussianRoulette` | 8 [est.] | ~100% [est.] | ~9 [est.] | +1 wave instr vs scalar RR |
| `RunWhiteFurnaceTest` (4096 spp) | 24 [est.] | ~75% [est.] | ~35/iter [est.] | Loop state adds registers |

### Your measurements (fill in after running the harness)

| Function | Registers | Occupancy | Instructions | Hardware | Date |
|---|---|---|---|---|---|
| `D_GGX` | | | | | |
| `V_SmithGGX_Correlated` | | | | | |
| `F_Schlick` | | | | | |
| `EvaluateCookTorrance` | | | | | |
| `EvaluateCookTorrance_MS` (+ KC) | | | | | |
| `SampleVNDF` | | | | | |
| `WaveRussianRoulette` | | | | | |
| `RunWhiteFurnaceTest` (4096 spp) | | | | | |

**Hardware tested:** _______________
**Driver version:** _______________

---

## Architecture Reference

### Ampere GA102 (RTX 3080 / 3090)
| Parameter | Value |
|---|---|
| SMs | 82 (RTX 3090) |
| CUDA cores | 10,496 |
| RT cores | 82 (2nd gen) |
| Registers per SM | 65,536 × 32-bit |
| Max threads per SM | 1,536 |
| Threads per warp | 32 |
| L1 cache | 128 KB per SM (configurable) |
| Occupancy threshold | > 42 registers/thread starts reducing occupancy |

### RDNA 3 (RX 7900 XTX)
| Parameter | Value |
|---|---|
| Compute Units | 96 |
| Shader processors | 12,288 |
| RT accelerators | 96 (2nd gen) |
| Registers per CU | 256 KB |
| Threads per wavefront | 64 |
| Note | 64-thread wavefronts: `WaveGetLaneCount()` returns 64, not 32. |

> **RDNA 3 note:** `WaveRussianRoulette` uses `WaveActiveAnyTrue` — correct on both
> architectures. On RDNA 3, it operates over 64 lanes instead of 32, meaning the
> wave terminates only when all 64 lanes are dead. This is strictly better than 32.

---

## In-Kernel Cost Model (Full Path Tracer)

In a real path tracer, all functions compile into a single ray generation or compute
shader. The combined register demand determines actual occupancy:

| Depth | Functions active | Estimated combined registers | Estimated occupancy |
|---|---|---|---|
| 1 bounce | EvaluateCookTorrance + SampleVNDF + PowerHeuristic | ~28–32 [est.] | ~85% [est.] |
| 2 bounces | + throughput accumulation + RR | ~32–38 [est.] | ~75% [est.] |
| 4 bounces (typical) | Full loop with temporal state | ~38–44 [est.] | ~60–70% [est.] |
| + Kulla-Conty | EvaluateCookTorrance_MS per bounce | +4–6 registers | −5–10% occupancy |

Target: ≥ 50% occupancy for path tracing kernels. Below 50%, the SM cannot hide
memory latency with in-flight threads and throughput degrades non-linearly.

---

## Kulla-Conty Cost Detail

`EvaluateKullaConty` adds ~12 ALU instructions per shading point:

| Sub-function | Instructions | Notes |
|---|---|---|
| `E_approx` (×2, for NdotL and NdotV) | ~4 each | 2 MAD + saturate |
| `E_avg` | ~3 | 2 MAD |
| `F_avg` | ~2 | MAD (vec3) |
| Final num/denom + max guard | ~3 | MUL (vec3) + max + RCP |
| **Total** | **~16** | Including vec3 overhead |

**Production rule:** enable `EvaluateCookTorrance_MS` only for rough metals
(`perceptualRoughness > 0.5`). Energy error for dielectrics at roughness 1.0 is < 2%
— within noise tolerance for interactive rendering. Save the 16 instructions.
