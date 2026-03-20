// F_Schlick.hlsl
// Schlick Fresnel approximation for dielectrics and metals
// Chapter 5, Section 5.3.2 | Digital Rendering Engineering: The Physics of Light
// Reference: Schlick, C. (1994). "An Inexpensive BRDF Model for Physically-based Rendering."
//            Computer Graphics Forum, 13(3), pp. 233–246.
//
// F0: specular color at normal incidence
//   Dielectrics: float3(0.04, 0.04, 0.04)  — ~4% base reflectance (IOR ~1.5)
//   Metals:      albedo color               — fully tinted specular
// VdotH: dot(view_direction, half_vector) — cosine of half-angle

static const float PI      = 3.14159265358979f;
static const float INV_PI  = 0.31830988618379f;
static const float EPSILON = 1e-6f;

float3 F_Schlick(float3 F0, float VdotH)
{
    float  p  = 1.0f - VdotH;
    float  p5 = p * p * p * p * p;
    return F0 + (1.0f - F0) * p5;
}

// FresnelConductorF0 — Exact F0 from complex IOR for conductors
// Use measured n+ik values from IORL databases (e.g., refractiveindex.info)
// eta:  real part of complex IOR (n)
// k:    extinction coefficient (imaginary part)
// eta1: IOR of surrounding medium (1.0 for air/vacuum)
float3 FresnelConductorF0(float3 eta, float3 k, float eta1)
{
    float3 eta_r = eta / eta1;
    float3 k_r   = k   / eta1;
    float3 num   = (eta_r - 1.0f) * (eta_r - 1.0f) + k_r * k_r;
    float3 denom = (eta_r + 1.0f) * (eta_r + 1.0f) + k_r * k_r;
    return num / denom;
}
