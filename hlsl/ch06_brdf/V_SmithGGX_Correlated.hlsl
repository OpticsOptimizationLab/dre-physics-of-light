// V_SmithGGX_Correlated.hlsl
// Height-Correlated Smith Visibility Function (combined G2 / denominator)
// Chapter 6, Section 6.2.2 | Digital Rendering Engineering: The Physics of Light
// Reference: Heitz, E. (2014). "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs."
//            JCGT, Vol. 3, No. 2. Lagarde & de Rousiers (2014), Frostbite PBR.
//
// Returns G2(l,v) / (4 * NdotL * NdotV) — combined form for numerical stability.
// This is the VISIBILITY TERM Vis, not G2 alone.
// The full Cook-Torrance specular is: D * Vis * F  (no additional 1/(4*NdotL*NdotV) needed)
//
// CRITICAL: Use the height-correlated form (this function), NOT the uncorrelated form.
// The uncorrelated form systematically overestimates reflectance and cannot be fixed by tuning.
//
// NdotL: dot(normal, light_direction)   — must be > 0 (caller's responsibility)
// NdotV: dot(normal, view_direction)    — must be > 0 (caller's responsibility)
// alpha: GGX roughness = perceptualRoughness^2

static const float EPSILON = 1e-7f;

float V_SmithGGX_Correlated(float NdotL, float NdotV, float alpha)
{
    float a2      = alpha * alpha;
    float lambdaV = NdotL * sqrt((NdotV - NdotV * a2) * NdotV + a2);
    float lambdaL = NdotV * sqrt((NdotL - NdotL * a2) * NdotL + a2);
    return 0.5f / max(lambdaV + lambdaL, EPSILON);
}
