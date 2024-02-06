sampler samp;
TextureCube envMap;

struct PSInput {
    float4 pos : SV_POSITION;
    float3 tex : TEXCOORD0;
};

float4 main(const PSInput i) : SV_TARGET {
    const float3 color = pow(envMap.Sample(samp, i.tex).rgb, 0.4545f);
    return float4(color, 1.0f);
}
