// RussianRoulette.hlsl
// Unbiased path termination via Russian Roulette
// Chapter 1, Section 1.1 | Chapter 7 | Digital Rendering Engineering: The Physics of Light
//
// Terminates low-energy paths stochastically while preserving expected value.
// The survival probability q = max(r,g,b) of the throughput, capped at 0.95.
// Cap at 0.95 prevents infinite loops in perfect mirror scenes (throughput never decays).
// Dividing by q on survival rescales to preserve radiometric energy budget.
//
// throughput: current path throughput (modified in-place on survival)
// rng:        uniform random sample in [0, 1)
// Returns: true = path continues | false = path terminated

bool RussianRoulette(inout float3 throughput, float rng)
{
    float q = min(max(throughput.r, max(throughput.g, throughput.b)), 0.95f);
    if (rng > q) return false; // terminate
    throughput /= q;           // rescale — preserves E[throughput]
    return true;
}
