// SobolSampler.hlsl
// Owen-scrambled Sobol quasi-random sequence
// Chapter 7 | Digital Rendering Engineering: The Physics of Light
// Reference: Burley, B. (2020). "Practical Hash-based Owen Scrambling."
//            JCGT, Vol. 9, No. 4.
//
// Sobol sequences have much lower discrepancy than pseudo-random generators,
// meaning samples fill the domain more uniformly. Owen scrambling removes
// the structured patterns visible in raw Sobol that can alias with scene geometry.
//
// index:   sample index (0, 1, 2, ... N-1)
// seed:    per-pixel scramble seed (use pixel position hash)
// Returns: 2D sample in [0, 1)^2

uint OwenHash(uint x)
{
    x ^= x * 0x3d20adeau;
    x += 0x2a21f447u;
    x ^= x * 0x0e4c5cf5u;
    x += 0xf9e79b85u;
    x ^= x * 0x7f3de9a1u;
    return x;
}

uint ReverseBits32(uint x)
{
    x = (x & 0x55555555u) << 1  | (x >> 1)  & 0x55555555u;
    x = (x & 0x33333333u) << 2  | (x >> 2)  & 0x33333333u;
    x = (x & 0x0f0f0f0fu) << 4  | (x >> 4)  & 0x0f0f0f0fu;
    x = (x & 0x00ff00ffu) << 8  | (x >> 8)  & 0x00ff00ffu;
    return (x << 16) | (x >> 16);
}

float SampleSobol1D(uint index, uint seed)
{
    uint x = ReverseBits32(index);
    x ^= OwenHash(seed);
    return (float)x * (1.0f / 4294967296.0f); // x / 2^32
}

float2 SampleSobol2D(uint index, uint seed)
{
    return float2(
        SampleSobol1D(index, OwenHash(seed)),
        SampleSobol1D(index, OwenHash(seed + 1u))
    );
}
