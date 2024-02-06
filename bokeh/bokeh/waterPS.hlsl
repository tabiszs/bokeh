float4 camPos;

sampler samp;
TextureCube envMap;
Texture3D perlin;

float time;

struct PSInput {
    float4 pos : SV_POSITION;
    float3 localPos : POSITION0;
    float3 worldPos : POSITION1;
};

float3 intersect_ray(float3 p, float3 r) {
    const float t_x = max((-p.x + 1) / r.x, (-p.x - 1) / r.x);
    const float t_y = max((-p.y + 1) / r.y, (-p.y - 1) / r.y);
    const float t_z = max((-p.z + 1) / r.z, (-p.z - 1) / r.z);
    const float t = min(min(t_x, t_y), t_z);

    return p + r * t;
}

float fresnel(const float3 viewVec, const float3 normal) {
    const float F0 = 0.14;
    const float cosTh = max(dot(viewVec, normal), 0.0);

    return F0 + (1.0 - F0) * pow(1.0 - cosTh, 5.0);
}

float zToCoc(const float z) {
    if (z < 0.5) {
        return 0.0;
    }
    return pow(z, 4);
}

float4 main(const PSInput i) : SV_TARGET {
    const float3 tex = float3(i.localPos.xz * 10.0f, time);
    const float ex = 2 * perlin.Sample(samp, tex).r - 1;
    const float ez = 2 * perlin.Sample(samp, tex + 0.5).r - 1;
    const float3 N = normalize(float3(ex, 20.0f, ez));


    const float3 viewVec = normalize(camPos.xyz - i.worldPos);
    // const float3 norm = float3(0.0f, 1.0f, 0.0f);
    const float3 norm = N;
    const float3 normal = dot(viewVec, norm) > 0 ? norm : -norm;

    const float3 reflected = reflect(-viewVec, normal);
    const float3 refracted = refract(-viewVec, normal, dot(viewVec, normal) > 0 ? 0.75f : 1.3333f);

    const float4 reflectedColor = envMap.Sample(samp, intersect_ray(i.localPos, reflected));
    const float4 refractedColor = envMap.Sample(samp, intersect_ray(i.localPos, refracted));

    if (!any(refracted)) {
        return float4(pow(reflectedColor.rgb, 0.4545f), pow(i.pos.z, 2));
    }

    const float f = fresnel(viewVec, normal);

    const float3 color = lerp(refractedColor, reflectedColor, f).rgb;

    return float4(pow(color, 0.4545f), zToCoc(i.pos.z));
}
