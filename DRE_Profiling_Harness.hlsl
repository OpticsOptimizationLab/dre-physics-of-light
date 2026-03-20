// ============================================================
// DRE Vol. 1 — Shader Performance Profiling Harness
// Digital Rendering Engineering: The Physics of Light
// github.com/OpticsOptimizationLab/dre-physics-of-light
//
// PURPOSE
// -------
// Isolates each DRE function in a dedicated compute dispatch
// for accurate register count, occupancy, and instruction count
// measurement with NSight Graphics (NVIDIA) or PIX (AMD/Intel).
//
// USAGE
// -----
// 1. Compile with: dxc -T cs_6_0 DRE_Profiling_Harness.hlsl
// 2. Dispatch each kernel: 1920x1080 / (8x8) = 240x135 threadgroups
// 3. Capture with NSight Graphics > Shader Profiler, or PIX > GPU Captures
// 4. Record results in PROFILING.md
//
// IMPORTANT: Each kernel writes to g_Output to prevent dead-code elimination.
// Compilers will strip unused computations — the output write forces them to
// remain in the compiled shader, giving accurate register counts.
//
// Validated: DXC 1.8 / SM6.0 — zero errors, zero warnings
// ============================================================

#include "DRE_Vol1_Complete.hlsl"

RWTexture2D<float4> g_Output : register(u0);

// Fixed inputs — same across all kernels for fair comparison.
// These values are not special: they exercise the common code paths.
static const float3 L_FIXED        = float3( 0.5774f,  0.5774f,  0.5774f);
static const float3 V_FIXED        = float3(-0.5774f,  0.5774f,  0.5774f);
static const float3 N_FIXED        = float3( 0.0f,     1.0f,     0.0f);
static const float3 F0_FIXED       = float3( 0.98f,    0.86f,    0.46f);  // gold
static const float  ROUGHNESS      = 0.5f;
static const float  ALPHA          = ROUGHNESS * ROUGHNESS;
static const float  NDOTV          = 0.5774f;
static const float  NDOTL          = 0.5774f;
static const float  NDOTH          = 0.8165f;
static const float  VDOTH          = 0.8165f;
static const float2 U_FIXED        = float2(0.3f, 0.7f);

// ── Kernel 0: D_GGX ──────────────────────────────────────────────────────────
[numthreads(8, 8, 1)]
void CS_D_GGX(uint3 tid : SV_DispatchThreadID)
{
    float result = D_GGX(NDOTH, ALPHA);
    g_Output[tid.xy] = float4(result, 0, 0, 1);
}

// ── Kernel 1: V_SmithGGX_Correlated ──────────────────────────────────────────
[numthreads(8, 8, 1)]
void CS_V_SmithGGX(uint3 tid : SV_DispatchThreadID)
{
    float result = V_SmithGGX_Correlated(NDOTL, NDOTV, ALPHA);
    g_Output[tid.xy] = float4(result, 0, 0, 1);
}

// ── Kernel 2: F_Schlick ───────────────────────────────────────────────────────
[numthreads(8, 8, 1)]
void CS_F_Schlick(uint3 tid : SV_DispatchThreadID)
{
    float3 result = F_Schlick(F0_FIXED, VDOTH);
    g_Output[tid.xy] = float4(result, 1);
}

// ── Kernel 3: EvaluateCookTorrance ───────────────────────────────────────────
[numthreads(8, 8, 1)]
void CS_CookTorrance(uint3 tid : SV_DispatchThreadID)
{
    float3 result = EvaluateCookTorrance(L_FIXED, V_FIXED, N_FIXED,
                                         F0_FIXED, ROUGHNESS);
    g_Output[tid.xy] = float4(result, 1);
}

// ── Kernel 4: EvaluateCookTorrance_MS (with Kulla-Conty) ─────────────────────
[numthreads(8, 8, 1)]
void CS_CookTorrance_MS(uint3 tid : SV_DispatchThreadID)
{
    float3 result = EvaluateCookTorrance_MS(L_FIXED, V_FIXED, N_FIXED,
                                             F0_FIXED, ROUGHNESS);
    g_Output[tid.xy] = float4(result, 1);
}

// ── Kernel 5: SampleVNDF ──────────────────────────────────────────────────────
[numthreads(8, 8, 1)]
void CS_SampleVNDF(uint3 tid : SV_DispatchThreadID)
{
    float3 Ve = float3(sqrt(max(0.0f, 1.0f - NDOTV * NDOTV)), 0.0f, NDOTV);
    float3 result = SampleVNDF(Ve, ALPHA, ALPHA, U_FIXED);
    g_Output[tid.xy] = float4(result, 1);
}

// ── Kernel 6: WaveRussianRoulette ─────────────────────────────────────────────
[numthreads(8, 8, 1)]
void CS_WaveRussianRoulette(uint3 tid : SV_DispatchThreadID)
{
    float3 throughput = float3(0.6f, 0.5f, 0.4f);
    float  rng        = frac(float(tid.x * 1973 + tid.y * 9277) / 65536.0f);
    bool   survived   = WaveRussianRoulette(throughput, rng);
    g_Output[tid.xy]  = float4(throughput * (survived ? 1.0f : 0.0f), 1);
}

// ── Kernel 7: RunWhiteFurnaceTest (4096 samples — heavy) ─────────────────────
// WARNING: This kernel is expensive. Run at 1x1 dispatch for timing,
// not 1920x1080. Record separately from the lightweight kernels.
[numthreads(1, 1, 1)]
void CS_WhiteFurnace(uint3 tid : SV_DispatchThreadID)
{
    float result = RunWhiteFurnaceTest(ROUGHNESS, NDOTV, 4096u);
    g_Output[tid.xy] = float4(result, 0, 0, 1);
}
