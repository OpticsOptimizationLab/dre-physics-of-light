// _dxc_validation_wrapper.hlsl
// DXC syntax validation wrapper — NOT production code.
// Includes all DRE Vol.1 functions and calls each from a compute shader entry point.
// Purpose: verify DXC compiles all functions without errors.
// Compile: dxc -T cs_6_0 _dxc_validation_wrapper.hlsl -Fo /dev/null

// ── Include all functions in dependency order ─────────────────────────────────
static const float PI      = 3.14159265358979f;
static const float INV_PI  = 0.31830988618379f;
static const float EPSILON = 1e-6f;

// Ch05: Fresnel
float3 F_Schlick(float3 F0, float VdotH) {
    float p = 1.0f - VdotH; float p5 = p*p*p*p*p;
    return F0 + (1.0f - F0) * p5;
}
float3 FresnelConductorF0(float3 eta, float3 k, float eta1) {
    float3 e = eta/eta1, ki = k/eta1;
    return ((e-1)*(e-1)+ki*ki) / ((e+1)*(e+1)+ki*ki);
}

// Ch06: BRDF
float D_GGX(float NdotH, float alpha) {
    float a2 = alpha*alpha, d = NdotH*NdotH*(a2-1.0f)+1.0f;
    return a2 / (PI * max(d*d, EPSILON));
}
float V_SmithGGX_Correlated(float NdotL, float NdotV, float alpha) {
    float a2 = alpha*alpha;
    float lV = NdotL * sqrt(max(NdotV*(NdotV - NdotV*a2) + a2, EPSILON));
    float lL = NdotV * sqrt(max(NdotL*(NdotL - NdotL*a2) + a2, EPSILON));
    return 0.5f / max(lV + lL, 1e-7f);
}
float3 EvaluateCookTorrance(float3 L, float3 V, float3 N, float3 F0, float r) {
    float3 H = normalize(L+V);
    float  NdotL = max(dot(N,L),1e-6f), NdotV = max(dot(N,V),1e-6f);
    float  NdotH = saturate(dot(N,H)), VdotH = saturate(dot(V,H));
    float  a = r*r;
    return D_GGX(NdotH,a) * V_SmithGGX_Correlated(NdotL,NdotV,a) * F_Schlick(F0,VdotH);
}

// Ch07: Integration
float PowerHeuristic(float a, float b) { return (a*a)/max(a*a+b*b,1e-10f); }
bool  RussianRoulette(inout float3 t, float rng) {
    float q = min(max(t.r,max(t.g,t.b)),0.95f);
    if (rng > q) return false; t /= q; return true;
}
uint  _OH(uint x) { x^=x*0x3d20adeau; x+=0x2a21f447u; x^=x*0x0e4c5cf5u; x+=0xf9e79b85u; x^=x*0x7f3de9a1u; return x; }
uint  _RB(uint x) {
    x=((x&0x55555555u)<<1)|((x>>1)&0x55555555u); x=((x&0x33333333u)<<2)|((x>>2)&0x33333333u);
    x=((x&0x0f0f0f0fu)<<4)|((x>>4)&0x0f0f0f0fu); x=((x&0x00ff00ffu)<<8)|((x>>8)&0x00ff00ffu);
    return (x<<16)|(x>>16);
}
float2 SampleSobol2D(uint i, uint s) {
    return float2(_RB(i)^_OH(s), _RB(i)^_OH(s+1u)) * (1.0f/4294967296.0f);
}

// Ch09: Validation
float3 SampleVNDF(float3 Ve, float ax, float ay, float2 u) {
    float3 Vh = normalize(float3(ax*Ve.x, ay*Ve.y, Ve.z));
    float lsq = Vh.x*Vh.x + Vh.y*Vh.y;
    float3 T1 = lsq > 0.0f ? float3(-Vh.y,Vh.x,0)*rsqrt(lsq) : float3(1,0,0);
    float3 T2 = cross(Vh,T1);
    float r=sqrt(u.x), phi=2.0f*PI*u.y, t1=r*cos(phi), t2=r*sin(phi);
    float s=0.5f*(1.0f+Vh.z);
    t2=(1.0f-s)*sqrt(max(0.0f,1.0f-t1*t1))+s*t2;
    float3 Nh=t1*T1+t2*T2+sqrt(max(0.0f,1.0f-t1*t1-t2*t2))*Vh;
    return normalize(float3(ax*Nh.x, ay*Nh.y, max(0.0f,Nh.z)));
}
float RunWhiteFurnaceTest(float roughness, float NdotV, uint N) {
    float3 V=float3(sqrt(max(0.0f,1.0f-NdotV*NdotV)),0.0f,NdotV);
    float acc=0.0f, a=roughness*roughness;
    for (uint i=0; i<N; i++) {
        float2 u=SampleSobol2D(i,0u);
        float3 H=SampleVNDF(V,a,a,u), L=reflect(-V,H);
        if (L.z<=0.0f) continue;
        float NdotL=L.z, NdotH=saturate(H.z), VdotH=saturate(dot(V,H));
        float D=D_GGX(NdotH,a), Vis=V_SmithGGX_Correlated(NdotL,NdotV,a);
        float3 F=F_Schlick(float3(1,1,1),VdotH);
        float pdf=D*NdotH/max(4.0f*VdotH,1e-7f);
        acc+=dot(D*Vis*F*NdotL/pdf,float3(1,1,1))/3.0f;
    }
    return acc/float(N);
}

// Ch10: Utils
float3 OffsetRayOrigin(float3 p, float3 n) {
    static const float o=1.0f/32.0f, fs=1.0f/65536.0f, is=256.0f;
    int3 oi=int3(is*n.x,is*n.y,is*n.z);
    float3 pi=float3(
        asfloat(asint(p.x)+(p.x<0?-oi.x:oi.x)),
        asfloat(asint(p.y)+(p.y<0?-oi.y:oi.y)),
        asfloat(asint(p.z)+(p.z<0?-oi.z:oi.z)));
    return float3(abs(p.x)<o?p.x+fs*n.x:pi.x, abs(p.y)<o?p.y+fs*n.y:pi.y, abs(p.z)<o?p.z+fs*n.z:pi.z);
}

// ── Compute shader entry point ────────────────────────────────────────────────
RWBuffer<float> g_output : register(u0);

[numthreads(1, 1, 1)]
void CSMain(uint3 tid : SV_DispatchThreadID)
{
    float3 N = float3(0,0,1), L = normalize(float3(0.5f,0,1)), V = normalize(float3(-0.3f,0,1));
    float3 F0 = float3(0.04f,0.04f,0.04f);
    float  r  = 0.5f;

    float3 brdf   = EvaluateCookTorrance(L,V,N,F0,r);
    float  mis    = PowerHeuristic(0.7f, 0.3f);
    float3 t      = float3(0.5f,0.5f,0.5f);
    RussianRoulette(t, 0.4f);
    float2 sobol  = SampleSobol2D(tid.x, 0u);
    float3 H      = SampleVNDF(V, r*r, r*r, sobol);
    float  wft    = RunWhiteFurnaceTest(r, 0.5f, 4u);
    float3 origin = OffsetRayOrigin(float3(1,2,3), N);
    float3 cF0    = FresnelConductorF0(float3(0.18f,0.42f,1.37f), float3(3.42f,2.35f,1.77f), 1.0f);

    g_output[tid.x] = brdf.x + mis + wft + origin.x + cF0.x + H.x;
}
