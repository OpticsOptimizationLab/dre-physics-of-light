// RunWhiteFurnaceTest.hlsl
// Automated energy conservation validator for Cook-Torrance BRDF
// Chapter 9, Section 9.1 | Digital Rendering Engineering: The Physics of Light
//
// Places the BRDF inside a uniform environment (L_e = 1.0 everywhere).
// A physically correct BRDF returns exactly 1.0 under this condition.
// The single-scattering Smith G2 is expected to return below 1.0 for rough surfaces
// (the Kulla-Conty gap — see Chapter 6.2.3 and benchmark table in Substrate 9.1).
//
// PASS criterion: result <= 1.001 for all roughness values
// FAIL (energy gain): result > 1.001 → implementation error, not physical limitation
//
// Expected results by roughness (NdotV = 0.5, N = 4096):
//   roughness 0.1 → ~0.999  | roughness 0.5 → ~0.921  | roughness 1.0 → ~0.801
//
// roughness:   perceptual roughness in [0, 1]
// NdotV:       cosine of view angle in [0, 1]
// sampleCount: Monte Carlo sample count (4096 recommended for validation)

#include "SampleVNDF.hlsl"
#include "../ch06_brdf/D_GGX.hlsl"
#include "../ch06_brdf/V_SmithGGX_Correlated.hlsl"
#include "../ch05_fresnel/F_Schlick.hlsl"
#include "../ch07_integration/SobolSampler.hlsl"

float RunWhiteFurnaceTest(float roughness, float NdotV, uint sampleCount)
{
    float3 V          = float3(sqrt(max(0.0f, 1.0f - NdotV * NdotV)), 0.0f, NdotV);
    float  accumulated = 0.0f;
    float  alpha       = roughness * roughness;

    for (uint i = 0; i < sampleCount; i++)
    {
        float2 u    = SampleSobol2D(i, 0u);
        float3 H    = SampleVNDF(V, alpha, alpha, u);
        float3 L    = reflect(-V, H);
        if (L.z <= 0.0f) continue; // sample below hemisphere — skip

        float NdotL = L.z;
        float NdotH = saturate(H.z);       // geometric guard
        float VdotH = saturate(dot(V, H)); // geometric guard

        float  D   = D_GGX(NdotH, alpha);
        float  Vis = V_SmithGGX_Correlated(NdotL, NdotV, alpha);
        // F0 = 1 (white furnace condition: maximum reflectance, no absorption)
        float3 F   = F_Schlick(float3(1.0f, 1.0f, 1.0f), VdotH);

        // VNDF PDF: D(H) * NdotH / (4 * VdotH)
        float pdf = D * NdotH / max(4.0f * VdotH, 1e-7f);

        // f_r * NdotL / pdf — Vis already encodes G2/(4*NdotL*NdotV)
        accumulated += dot(D * Vis * F * NdotL / pdf, float3(1,1,1)) / 3.0f;
    }
    return accumulated / float(sampleCount);
}
