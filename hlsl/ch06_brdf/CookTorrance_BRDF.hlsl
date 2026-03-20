// CookTorrance_BRDF.hlsl
// Complete Cook-Torrance Specular BRDF
// Chapter 4, Section 4.3.2 | Chapter 6, Sections 6.2.1–6.2.3
// Digital Rendering Engineering: The Physics of Light
//
// Reference: Cook, R.L. & Torrance, K.E. (1982). ACM TOG.
//            Lagarde & de Rousiers (2014), Moving Frostbite to PBR.
//
// Implements: f_r(l,v) = D(h,alpha) * G2(l,v,alpha) * F(v,h) / (4 * NdotL * NdotV)
// Note: V_SmithGGX_Correlated already encodes G2/(4*NdotL*NdotV).
//       The full specular is simply D * Vis * F.
//
// IMPORTANT — saturate() on NdotH and VdotH:
// These are geometric guards, NOT energy corrections. The half-vector h lies
// in the positive hemisphere by construction. The clamps will never trigger on
// valid geometry and exist only to protect against floating-point noise < 1e-7.
// They are permitted. saturate() used to silence a broken energy budget is not.

#include "D_GGX.hlsl"
#include "V_SmithGGX_Correlated.hlsl"
#include "../ch05_fresnel/F_Schlick.hlsl"

// EvaluateCookTorrance
// L: light direction  (unit, pointing toward light source)
// V: view direction   (unit, pointing toward camera)
// N: surface normal   (unit)
// F0: specular color at normal incidence
//   Dielectrics: float3(0.04, 0.04, 0.04)
//   Metals: albedo
// perceptualRoughness: artist-facing [0,1], remapped to alpha = r^2 internally
// Returns: specular radiance contribution — caller multiplies by NdotL and light radiance
float3 EvaluateCookTorrance(float3 L, float3 V, float3 N,
                             float3 F0, float perceptualRoughness)
{
    float3 H      = normalize(L + V);
    float  NdotL  = max(dot(N, L), 1e-6f);
    float  NdotV  = max(dot(N, V), 1e-6f);
    float  NdotH  = saturate(dot(N, H)); // geometric guard — see header note
    float  VdotH  = saturate(dot(V, H)); // geometric guard — see header note

    float  alpha  = perceptualRoughness * perceptualRoughness;

    float  D   = D_GGX(NdotH, alpha);
    float  Vis = V_SmithGGX_Correlated(NdotL, NdotV, alpha);
    float3 F   = F_Schlick(F0, VdotH);

    return D * Vis * F;
}
