// ============================================================
// Cook-Torrance Specular BRDF — Compliant Implementation
// D: GGX/Trowbridge-Reitz (Walter et al. 2007)
// G: Height-Correlated Smith G2 (Heitz 2014)
// F: Schlick approximation (Schlick 1994)
// Roughness remapping: Lagarde & de Rousiers 2014 (Frostbite)
// Target: Shader Model 6.0+ | No divergence
// ============================================================

static const float PI     = 3.14159265358979f;
static const float INV_PI = 0.31830988618379f;

// D_GGX: Normal Distribution Function
// NdotH: saturated dot(N, H) — bounded by geometry, no clamp needed here
float D_GGX(float NdotH, float alpha)
{
    float a2    = alpha * alpha;
    float denom = (NdotH * NdotH) * (a2 - 1.0f) + 1.0f;
    return a2 * INV_PI / (denom * denom);
}

// V_SmithGGX_Correlated: visibility term G2 / (4 * NdotL * NdotV)
// Combined form for numerical stability — avoids division by zero
// at grazing angles. Guard: call only when NdotL > 0, NdotV > 0.
float V_SmithGGX_Correlated(float NdotL, float NdotV, float alpha)
{
    float a2      = alpha * alpha;
    float lambdaV = NdotL * sqrt((NdotV - NdotV * a2) * NdotV + a2);
    float lambdaL = NdotV * sqrt((NdotL - NdotL * a2) * NdotL + a2);
    return 0.5f / (lambdaV + lambdaL);
}

// F_Schlick: Fresnel reflectance at VdotH
// F0: specular color at normal incidence
//   Dielectrics: 0.04 (4% base reflectance)
//   Metals:      albedo (fully colored specular)
float3 F_Schlick(float3 F0, float VdotH)
{
    float  p  = 1.0f - VdotH;
    float  p5 = p * p * p * p * p;
    return F0 + (1.0f - F0) * p5;
}

// EvaluateCookTorrance: complete specular lobe evaluation
// L, V, N: normalized directions in consistent space (world or tangent)
// F0:               specular color at normal incidence
// perceptualRoughness: artist-facing [0,1], remapped internally to alpha
// Returns: specular radiance contribution (NOT multiplied by NdotL)
float3 EvaluateCookTorrance(float3 L, float3 V, float3 N,
                             float3 F0, float perceptualRoughness)
{
    float3 H      = normalize(L + V);
    float  NdotL  = max(dot(N, L), 1e-6f);
    float  NdotV  = max(dot(N, V), 1e-6f);
    float  NdotH  = saturate(dot(N, H)); // geometry guarantees [0,1]
    float  VdotH  = saturate(dot(V, H)); // geometry guarantees [0,1]

    // α remapping: perceptual roughness → GGX α
    float alpha = perceptualRoughness * perceptualRoughness;

    float  D      = D_GGX(NdotH, alpha);
    float  Vis    = V_SmithGGX_Correlated(NdotL, NdotV, alpha);
    float3 F      = F_Schlick(F0, VdotH);

    // f_r = D * G * F / (4 * NdotL * NdotV)
    // Vis already encodes G / (4 * NdotL * NdotV)
    return D * Vis * F;
}