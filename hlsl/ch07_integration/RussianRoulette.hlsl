// Unbiased Russian Roulette path termination.
// throughput: accumulated f_r * cosTheta / pdf product along the path.
// rng:        uniform [0,1] random number.
// Returns false if the path should be terminated.
bool RussianRoulette(inout float3 throughput, float rng)
{
    // Survival probability = luminance of remaining throughput
    float q = min(max(throughput.r, max(throughput.g, throughput.b)), 0.95f);
    // Cap at 0.95: never allow 100% survival (prevents infinite loops
    // in perfectly specular scenes — the Mirror Trap)
    if (rng > q) return false;   // terminate
    throughput /= q;             // compensate — preserves E[result]
    return true;                 // continue
}