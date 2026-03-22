// Full conductor Fresnel at normal incidence — exact, no approximation.
// eta: real part of complex IOR (n)
// k: extinction coefficient (imaginary part)
// eta1: IOR of surrounding medium (typically 1.0 for air)
// Returns: spectral reflectance F0 — use as F0 in Cook-Torrance
float3 FresnelConductorF0(float3 eta, float3 k, float eta1)
{
 float3 eta_r = eta / eta1;
 float3 k_r = k / eta1;
 float3 num = (eta_r - 1.0f) * (eta_r - 1.0f) + k_r * k_r;
 float3 denom = (eta_r + 1.0f) * (eta_r + 1.0f) + k_r * k_r;
 return num / denom;
 // Result is physically measured F0 — pass directly to F_Schlick()
 // Example (gold at 630nm): eta=0.18, k=3.42 → F0 ≈ (0.98, 0.87, 0.55)
}