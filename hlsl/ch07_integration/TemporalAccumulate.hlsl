// TemporalAccumulate.hlsl
// Variance-based temporal accumulation with neighborhood AABB clamp
// Chapter 7, Section 7.3.2 | Digital Rendering Engineering: The Physics of Light
//
// History weight: HISTORY_WEIGHT = 0.95 (95% history / 5% new sample per frame)
// This is the stable-region default. It must become dynamic near disocclusions:
// when historyUV falls outside [0,1], history is invalid — set blend to 0.
//
// Ghosting prevention: neighborhood 3x3 AABB clamp rejects history samples
// that have drifted outside the local color neighborhood of the current frame.
// Without this clamp, disoccluded regions accumulate stale radiance (ghosting).

float3 TemporalAccumulate(
    Texture2D       historyBuffer,
    Texture2D       currentBuffer,
    SamplerState    linearSampler,
    float2          uv,
    float2          motionVector,
    float2          texelSize)
{
    static const float HISTORY_WEIGHT = 0.95f;

    float2 historyUV = uv - motionVector;
    float3 history   = historyBuffer.SampleLevel(linearSampler, historyUV, 0).rgb;
    float3 current   = currentBuffer.SampleLevel(linearSampler, uv, 0).rgb;

    // Neighborhood AABB clamp: reject history outside local color neighborhood
    float3 colorMin = current, colorMax = current;
    [unroll] for (int y = -1; y <= 1; y++)
    [unroll] for (int x = -1; x <= 1; x++)
    {
        float3 s = currentBuffer.SampleLevel(
            linearSampler, uv + float2(x, y) * texelSize, 0).rgb;
        colorMin = min(colorMin, s);
        colorMax = max(colorMax, s);
    }
    history = clamp(history, colorMin, colorMax);

    // Disocclusion: UV outside [0,1] means no valid history — discard
    float inBounds = all(saturate(historyUV) == historyUV) ? 1.0f : 0.0f;
    float blend    = HISTORY_WEIGHT * inBounds;

    return lerp(current, history, blend);
}
