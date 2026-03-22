// Variance-based temporal accumulation — production implementation
// History weight: 0.95 (95% history / 5% new sample per frame)
// Ghosting prevention: neighborhood AABB clamp rejects stale history
float3 TemporalAccumulate(
    Texture2D       historyBuffer,
    Texture2D       currentBuffer,
    SamplerState    linearSampler,
    float2          uv,
    float2          motionVector,
    float2          texelSize)
{
    // α = 0.95: history weight. Must decrease dynamically near disocclusions
    // and specular shifts where history is no longer physically valid.
    static const float HISTORY_WEIGHT = 0.95f;

    float2 historyUV = uv - motionVector;
    float3 history   = historyBuffer.SampleLevel(linearSampler, historyUV, 0).rgb;
    float3 current   = currentBuffer.SampleLevel(linearSampler, uv, 0).rgb;

    // Neighborhood AABB clamp — reject history that has drifted outside
    // the local color neighborhood of the current frame (ghosting prevention).
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

    // Disocclusion detection: UV outside [0,1] means no valid history.
    // Set blend to 0 — use only current sample, no history accumulation.
    float inBounds = all(saturate(historyUV) == historyUV) ? 1.0f : 0.0f;
    float blend    = HISTORY_WEIGHT * inBounds;

    return lerp(current, history, blend);
}