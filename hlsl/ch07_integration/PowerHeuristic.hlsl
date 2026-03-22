// PowerHeuristic: Veach & Guibas (1995), beta=2
// pdf_a: PDF of the chosen sampling strategy
// pdf_b: PDF of the competing strategy
// n_a, n_b: number of samples from each strategy (typically 1 each)
float PowerHeuristic(float pdf_a, float pdf_b, int n_a, int n_b)
{
 float a = float(n_a) * pdf_a;
 float b = float(n_b) * pdf_b;
 // beta=2: square both, then normalize
 return (a * a) / max(a * a + b * b, 1e-10f);
}

// Usage — combining BRDF sample and light sample:
// float w_brdf = PowerHeuristic(pdf_brdf, pdf_light, 1, 1);
// float w_light = PowerHeuristic(pdf_light, pdf_brdf, 1, 1);
// result = w_brdf * f_brdf / pdf_brdf + w_light * f_light / pdf_light;