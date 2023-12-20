#define NLIGHTS 2

#define PI 3.14159265359
#define EPS 0.0000001

Texture2D normTex : register(t0);
Texture2D albedoTex : register(t1);
Texture2D roughnessTex : register(t2);
Texture2D metallnessTex : register(t3);
TextureCube irMap : register(t4);
TextureCube pfEnvMap : register(t5);
Texture2D brdfTex : register(t6);

SamplerState samp : register(s0);

float4 lightPos[NLIGHTS];
float3 lightColor[NLIGHTS];

struct PSInput {
    float4 pos : SV_POSITION;
    float3 worldPos : POSITION0;
    float3 norm : NORMAL0;
    float3 view : VIEWVEC0;
    float2 tex : TEXCOORD0;
    float3 tangent : TANGENT0;
};

float3 normalMapping(const float3 N, const float3 T, const float3 tn) {
    const float3 B = normalize(cross(normalize(N), T));
    const float3x3 tbn = {T, B, N};
    return normalize(mul(transpose(tbn), tn));
}

float normalDistributionGGX(const float3 N, const float3 H, const float roughness) {
    return roughness * roughness / (PI * pow(pow(max(dot(N, H), EPS), 2) * (roughness * roughness - 1) + 1, 2));
}

float geometrySchlickGGX(const float3 N, const float3 W, const float roughness) {
    const float q = pow(roughness + 1, 2) / 8;
    return max(dot(N, W), EPS) / (max(dot(N, W), EPS) * (1 - q) + q);
}

float geometrySmith(const float3 N, const float3 V, const float3 L, const float roughness) {
    return geometrySchlickGGX(N, V, roughness) * geometrySchlickGGX(N, L, roughness);
}

float fresnel(const float3 N, const float3 L, const float F0) {
    return F0 + (1 - F0) * pow(1 - dot(N, L), 5);
}

float4 main(const PSInput i) : SV_TARGET {
    const float3 N1 = normalize(i.norm);
    // const float3 dPdx = ddx(i.worldPos);
    // const float3 dPdy = ddy(i.worldPos);
    // const float2 dtdx = ddx(i.tex);
    // const float2 dtdy = ddy(i.tex);
    // const float3 T = normalize(-dPdx * dtdy.y + dPdy * dtdx.y);
    const float3 T = normalize(i.tangent);

    float3 tn = normalize(normTex.Sample(samp, i.tex) * 2 - 1);
    tn.y *= -1;

    const float3 N = normalMapping(N1, T, tn);
    const float3 V = normalize(i.view);

    const float3 albedo = albedoTex.Sample(samp, i.tex);
    const float roughness = roughnessTex.Sample(samp, i.tex).r;
    const float metallness = metallnessTex.Sample(samp, i.tex).r;

    const float3 A = pow(albedo, 1);
    const float3 F0 = lerp(0.04, A, metallness);

    float3 color = 0;

    const float3 Iir = irMap.Sample(samp, N).rgb;
    const float3 R = reflect(-V, N);
    const float3 Ii = pfEnvMap.SampleLevel(samp, R, roughness * 6.0f).rgb;
    const float2 brdf = brdfTex.Sample(samp, float2(max(dot(N, V), EPS), roughness)).rg;

    const float ks = fresnel(N, V, F0);
    const float kd = (1 - ks) * (1 - metallness);
    const float Id = kd * A * Iir;
    const float Is = Ii * (F0 * brdf.x + brdf.y);
    const float3 ambient = 0.03 * A + Id + Is;

    for (int l = 0; l < NLIGHTS; l++)
    {
        const float3 li = normalize(lightPos[l] - i.worldPos);
        const float3 Li = max(dot(N, li), EPS) * lightColor[l] / pow(length(lightPos[l] - i.worldPos), 2);
        const float3 H = normalize(li + V);

        const float fct =
            fresnel(H, li, F0) * normalDistributionGGX(N, H, roughness) * geometrySmith(N, V, li, roughness)
            /
            (4 * max(dot(N, V), EPS) * max(dot(N, li), EPS));
        const float brdfColor = kd * A / PI + fct;

        color += Li * brdfColor;
    }

    const float3 finalColor = color + ambient;

    return pow(float4(finalColor / (finalColor + 1), 1), 1 / 2.2);
}
