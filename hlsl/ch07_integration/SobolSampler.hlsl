// Sobol dimension index for a given bounce and slot.
// slot: 0=BRDF_u, 1=BRDF_v, 2=RussianRoulette, 3=LightSelect, 4=LightPos
uint SobolDim(uint bounce, uint slot)
{
    // Dims 0-1: reserved for pixel AA jitter (called before PathTrace)
    // Dims 2+: path tracing, 5 dims per bounce
    return 2u + bounce * 5u + slot;
}

// Usage in PathTrace loop:
//   float2 brdfU   = SampleSobol2D(sampleIdx, SobolDim(bounce, 0));
//   float  rng_rr  = SampleSobol1D(sampleIdx, SobolDim(bounce, 2));
//   float  rng_ls  = SampleSobol1D(sampleIdx, SobolDim(bounce, 3));
//   float2 lightU  = SampleSobol2D(sampleIdx, SobolDim(bounce, 4));