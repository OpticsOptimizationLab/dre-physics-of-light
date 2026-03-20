// D_GGX.hlsl
// Trowbridge-Reitz (GGX) Normal Distribution Function
// Chapter 6, Section 6.2.1 | Digital Rendering Engineering: The Physics of Light
// Reference: Walter, B. et al. (2007). "Microfacet Models for Refraction through Rough Surfaces."
//            EGSR 2007. Lagarde & de Rousiers (2014), Frostbite PBR.
//
// Normalization: integral of D(h)*cos(theta_h) over hemisphere = 1
// The 1/PI factor is the analytic solution to this constraint for the GGX distribution.
//
// NdotH: dot(normal, half_vector) — cosine between surface normal and half-vector
// alpha: GGX roughness parameter = perceptualRoughness * perceptualRoughness
//        (Disney/Frostbite perceptual remapping — linear artist slider)

static const float PI      = 3.14159265358979f;
static const float EPSILON = 1e-6f;

float D_GGX(float NdotH, float alpha)
{
    float a2    = alpha * alpha;
    float denom = (NdotH * NdotH) * (a2 - 1.0f) + 1.0f;
    // a2 / (PI * denom^2): the 1/PI satisfies the normalization integral
    // max(denom*denom, EPSILON) guards against NaN at NdotH=1, alpha=0
    return a2 / (PI * max(denom * denom, EPSILON));
}
