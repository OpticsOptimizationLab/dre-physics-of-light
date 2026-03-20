// PowerHeuristic.hlsl
// Multiple Importance Sampling — Power Heuristic (beta=2)
// Chapter 7, Section 7.2.1 | Digital Rendering Engineering: The Physics of Light
// Reference: Veach, E. & Guibas, L. (1995). "Optimally Combining Sampling Techniques
//            for Monte Carlo Rendering." SIGGRAPH 1995.
//
// The power heuristic with beta=2 is "meritocratic" — it assigns weight proportional
// to the square of the PDF, rewarding the strategy with the stronger match.
// beta=1 (balance heuristic) is "democratic" — equal weight per sample count.
// beta=2 reduces variance more aggressively at the cost of slightly higher bias
// when strategies have very different PDF magnitudes.
//
// a: PDF of the current sampling strategy (e.g., BRDF sampling)
// b: PDF of the other strategy (e.g., light sampling)
// Returns: MIS weight in [0, 1]

float PowerHeuristic(float a, float b)
{
    return (a * a) / max(a * a + b * b, 1e-10f);
}
