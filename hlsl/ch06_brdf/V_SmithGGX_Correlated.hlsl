// Wave-coherent Russian Roulette — SM6.0+
// Scalar form: each lane decides independently → divergent wave.
// Wave form: wave terminates only when ALL lanes are dead → coherent exit.
//
// WaveActiveAnyTrue: returns true if ANY lane passes the condition.
// If no lane survives, the entire wave exits — no divergent stragglers.
bool WaveRussianRoulette(inout float3 throughput, float rng)
{
    float q = min(max(throughput.r, max(throughput.g, throughput.b)), 0.95f);
    bool  survive = (rng <= q);
    if (survive) throughput /= q;  // unbiased: E[result] preserved

    // Keep wave alive until every lane is terminated.
    // Eliminates the "1 live lane drags 31 dead lanes" pathology.
    return WaveActiveAnyTrue(survive) && survive;
}

// WaveIsFirstLane: execute once per wave, not once per lane.
// Use for operations with wave-level side effects:
//   - incrementing a shared atomic counter (one increment per wave, not 32)
//   - loading from a shared LUT into groupshared memory
//   - writing a wave-level debug diagnostic
if (WaveIsFirstLane())
{
    // Example: increment ray counter once per wave (32 rays, not 32 atomics)
    InterlockedAdd(g_RayCountBuffer[0], WaveActiveCountBits(true));
}

// WaveActiveSum: reduce a per-lane value across the wave.
// Use for: accumulating throughput luminance to decide wave-level RR threshold.
// Avoids per-lane divergence when one bright lane would keep the whole wave alive.
float waveLuminance = WaveActiveSum(max(throughput.r,
                                   max(throughput.g, throughput.b)));
float waveAvgLuminance = waveLuminance / float(WaveGetLaneCount());
// Use waveAvgLuminance as the wave-level termination signal instead of per-lane.