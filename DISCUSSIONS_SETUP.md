# GitHub Discussions Setup Guide

## Recommended Categories

### 1. **Q&A** (Questions & Answers)
Topic: Implementation questions

**Seed Posts:**
- "How to integrate DRE_Vol1_Complete.hlsl into my DX12 project?"
- "Understanding the height-correlated Smith G₂ implementation"
- "VNDF sampling: when to use vs basic GGX importance sampling?"
- "Debugging energy conservation failures in custom BRDFs"
- "Register pressure optimization tips for PathTrace kernel"

### 2. **Show and Tell**
Topic: Projects using this code

**Seed Posts:**
- "Share your path tracer implementation"
- "Performance benchmarks on different GPUs"
- "Comparison with your previous BRDF implementation"
- "Screenshots of your renderer using DRE code"

### 3. **Research & Papers**
Topic: Academic discussion

**Seed Posts:**
- "Recent advances in microfacet theory (post-2018)"
- "Alternative BRDF models: when GGX is not enough"
- "Energy conservation in multi-scattering BRDFs"
- "Heitz 2023: Latest VNDF improvements"

### 4. **Validation & Testing**
Topic: White Furnace and other tests

**Seed Posts:**
- "White Furnace Test: your results on different hardware"
- "Additional validation tests for BRDFs"
- "Numerical stability edge cases"
- "Comparing against PBRT reference renderer"

### 5. **Book Discussion**
Topic: Digital Rendering Engineering manuscript

**Seed Posts:**
- "Errata: report errors in the book"
- "Chapter discussion: Vol. 1 Chapter 6 (Microfacet Theory)"
- "Questions about equations in the manuscript"
- "Suggestions for Vol. 3 content"

### 6. **Optimization**
Topic: Performance improvements

**Seed Posts:**
- "GPU profiling results with NSight"
- "Register allocation strategies"
- "Memory coalescing patterns"
- "Divergence reduction techniques"

---

## Initial Post Templates

### Welcome Post (Pin to top)

```markdown
# Welcome to DRE Discussions!

This is the community space for Digital Rendering Engineering companion code.

**What to expect:**
- Implementation questions answered by maintainers and community
- Technical discussions about PBR, microfacet theory, and rendering
- Showcase of projects using this code
- Academic paper discussions

**Rules:**
1. Be respectful and professional
2. Search before posting (your question may be answered)
3. Include code snippets and error messages when asking for help
4. Share your benchmarks and validation results

**Resources:**
- [White Furnace Test](tests/test_white_furnace.py)
- [Validation Summary](VALIDATION_SUMMARY.md)
- [Book Repository](https://github.com/OpticsOptimizationLab)

Let's build a knowledge base for production-quality PBR!
```

---

### Q&A Seed Post

```markdown
# [Q&A] How to integrate DRE_Vol1_Complete.hlsl into my project?

I'm working on a DX12 path tracer and want to use the validated BRDF implementations from this repo. What's the recommended integration approach?

**My current setup:**
- DirectX 12 with Agility SDK
- Shader Model 6.6
- RTX 4070 (Turing architecture)

**Questions:**
1. Can I just `#include "DRE_Vol1_Complete.hlsl"` in my shaders?
2. Do I need to add any defines or constants?
3. Are there root signature requirements?

Has anyone successfully integrated this? Would love to see examples!
```

---

### Show and Tell Seed Post

```markdown
# [Show and Tell] Path tracer using DRE BRDF implementations

Share your path tracer screenshots, performance numbers, or integration experience!

**Template:**

**Project:** [Name/link]
**GPU:** [e.g., RTX 4090]
**Performance:** [ms per frame at resolution]
**White Furnace Result:** [if you ran the test]
**Screenshot:** [optional]

**What worked well:**
- ...

**Challenges:**
- ...

**Questions:**
- ...
```

---

### Research Seed Post

```markdown
# [Research] Energy conservation in multi-scattering BRDFs

The current implementation uses single-scattering Smith G₂, which produces the expected energy deficit at high roughness (Kulla-Conty deficit).

**Papers of interest:**
- Kulla & Conty (2017): "Revisiting Physically Based Shading at Imageworks"
- Turquin (2019): "Practical multiple scattering compensation for microfacet models"
- Heitz et al. (2016): "Multiple-scattering microfacet BSDFs with the Smith model"

**Discussion:**
Has anyone implemented multi-scattering compensation on top of the DRE base? What were the performance implications?

The theoretical max is 1.0 (perfect conservation), but single-scattering gives ~0.45 at roughness=1.0. Multi-scattering should reach ~0.95.

Share your implementation or benchmarks!
```

---

### Validation Seed Post

```markdown
# [Validation] White Furnace Test results on your hardware

CI runs the test on GitHub runners (Ubuntu + CPU). Let's crowdsource GPU results!

**Please share:**
- GPU model
- Driver version
- Test results (18 configurations)
- Any failures or anomalies

**How to run:**
```bash
git clone https://github.com/OpticsOptimizationLab/dre-physics-of-light
cd dre-physics-of-light
pip install -r tests/requirements.txt
python tests/test_white_furnace.py
```

**Expected:** All 18 tests PASS (< 1.001 energy gain)

**My results (RTX 4090):**
- roughness 0.1, NdotV 0.5 → 0.9998 ✓
- roughness 0.5, NdotV 0.5 → 0.8572 ✓
- roughness 1.0, NdotV 0.5 → 0.4507 ✓
[... post full table or summary ...]

Let's verify cross-platform consistency!
```

---

### Book Errata Post

```markdown
# [Book Errata] Report errors here

Found a typo, code error, or incorrect equation in the manuscript? Report it here!

**Format:**
- **Location:** Volume X, Chapter Y, Section Z, Page/Line
- **Error:** [describe what's wrong]
- **Correction:** [suggest fix if known]

**Example:**
- **Location:** Vol. 1, Chapter 6.2.1, Equation 6.3
- **Error:** Missing 1/π factor in NDF normalization
- **Correction:** Should be D(h) = α² / (π · denom²)

Confirmed errata will be compiled and published in a separate document.
```

---

## Moderation Guidelines

**Maintainer responses:**
- Aim for < 48h response time on Q&A
- Pin important discussions (welcome, errata, FAQ)
- Mark solved questions with ✓
- Lock off-topic or resolved threads

**Encourage:**
- Sharing benchmarks and validation results
- Linking to papers and references
- Code snippets with explanations
- Constructive technical debate

**Discourage:**
- Asking for help with unrelated codebases
- Requests for features outside book scope
- Non-technical discussion
- Self-promotion without contribution

---

## Post ideas (ongoing)

**Weekly/Monthly:**
- "Paper of the month" discussion
- "Optimization challenge" (e.g., reduce register count by 10%)
- Highlight interesting Show & Tell posts

**When new content drops:**
- Volume 2 release announcement
- New test suite additions
- CI improvements

**Community-driven:**
- Guest posts from researchers using the code
- Tutorials from community members
- Performance case studies
