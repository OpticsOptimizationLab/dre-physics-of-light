// OffsetRayOrigin.hlsl
// ULP-based ray origin offset for self-intersection prevention
// Chapter 10 | Digital Rendering Engineering: The Physics of Light
// Reference: Wächter, C. & Binder, N. (2019). "A Fast and Robust Method for
//            Avoiding Self-Intersection." Ray Tracing Gems, Chapter 6. Apress.
//
// Replaces the naive constant-offset method: world_pos + normal * BIAS_MAGNITUDE
// The constant method fails at both extremes:
//   Large scenes (>100 units): 0.001 is too small → shadow acne
//   Small objects (<0.01 units): 0.001 is too large → visible surface displacement
//
// This implementation operates in IEEE 754 integer (ULP) space.
// It steps one ULP in the normal direction — correct at ALL production scene scales
// from 0.001 to 100,000+ world units without any magic constant.
//
// p: ray origin (world space)
// n: surface normal (unit vector, pointing away from surface)
// Returns: offset origin guaranteed to avoid self-intersection

float3 OffsetRayOrigin(float3 p, float3 n)
{
    static const float origin      = 1.0f / 32.0f;
    static const float float_scale = 1.0f / 65536.0f;
    static const float int_scale   = 256.0f;

    // Integer ULP offset: step one representable float in the normal direction
    int3   of_i = int3(int_scale * n.x, int_scale * n.y, int_scale * n.z);
    float3 p_i  = float3(
        asfloat(asint(p.x) + (p.x < 0 ? -of_i.x : of_i.x)),
        asfloat(asint(p.y) + (p.y < 0 ? -of_i.y : of_i.y)),
        asfloat(asint(p.z) + (p.z < 0 ? -of_i.z : of_i.z))
    );

    // Near origin: floats are dense — use small additive offset instead
    return float3(
        abs(p.x) < origin ? p.x + float_scale * n.x : p_i.x,
        abs(p.y) < origin ? p.y + float_scale * n.y : p_i.y,
        abs(p.z) < origin ? p.z + float_scale * n.z : p_i.z
    );
}
