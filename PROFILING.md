# DRE Vol. 1 — Shader Performance Profile

## Purpose

Measured register counts, occupancy, and instruction counts for each DRE function.
Use `DRE_Profiling_Harness.hlsl` to generate these numbers on your target GPU.

## Methodology

**Tool:** NSight Graphics (NVIDIA) or PIX for Windows (AMD/Intel)
**Dispatch:** 1920×1080 / (8×8) = 240×135 threadgroups per kernel (except CS_WhiteFurnace: 1×1)
**Shader Model:** SM6.0, compiled with DXC 1.8
**Measurement:** Shader Profiler → per-kernel register file usage + SM occupancy

**To capture with NSight Graphics:**
1. Launch app with NSight attached
2. Capture a frame
3. Go to Shader Profiler → select the dispatch → read "Registers Per Thread" and "Theoretical Occupancy"

**To capture with PIX:**
1. GPU Capture → select compute dispatch → Pipeline Statistics

---

## Results

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

## Reference Baselines (Ampere/Ada — published sources)

These are representative values from public NVIDIA documentation and GDC presentations.
They are estimates, not measurements. Fill in measured values above.

| Shader complexity | Typical registers | Typical occupancy (32 threads/wave) |
|---|---|---|
| Simple ALU (3–5 instructions) | 8–12 | ~85% |
| Medium ALU (10–20 instructions) | 12–18 | ~65–75% |
| Complex ALU (30+ instructions, branches) | 18–28 | ~45–60% |
| `SampleVNDF` estimate | ~16–20 | ~60–70% |
| `EvaluateCookTorrance` estimate | ~14–18 | ~65–75% |
| `EvaluateCookTorrance_MS` estimate | ~18–22 | ~55–65% |

**Notes:**
- Ampere (GA102): 32 threads/warp, 255 registers/thread max, 65536 registers/SM
- RDNA 3: 64 threads/wavefront, register file per compute unit is 256KB
- Occupancy decreases as register count increases — target ≥ 50% for path tracing kernels
- `WaveRussianRoulette` adds `WaveActiveAnyTrue` — 1 wave-level instruction, minimal cost

---

## Kulla-Conty Cost

`EvaluateKullaConty` adds approximately 12 ALU instructions to each shading point:
- 2× `E_approx`: ~4 instructions each
- 1× `E_avg`: ~3 instructions
- 1× `F_avg`: ~2 instructions
- Final division: ~2 instructions + `max` guard

For production: enable KC only for rough metals (roughness > 0.5). Skip for dielectrics.
The energy error on dielectrics at roughness 1.0 is < 2% — within noise tolerance for interactive rendering.
