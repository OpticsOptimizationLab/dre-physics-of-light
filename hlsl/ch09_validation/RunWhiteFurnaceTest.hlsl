// WRONG: division by near-zero produces a massive sample weight
accumulated += brdf_times_cosine / pdf;

// CORRECT: epsilon guard prevents NaN and infinite contributions
accumulated += brdf_times_cosine / max(pdf, 1e-7f);