struct PSInput {
    float4 pos : SV_POSITION;
    float3 worldPos : POSITION0;
    float3 norm : NORMAL0;
    float3 view : VIEWVEC0;
};

float zToCoc(const float z) {
    if (z < 0.5) {
        return 0.0;
    }
    return pow(z, 4);
}

float4 main(PSInput i) : SV_TARGET {
    return float4(1.0f, 1.0f, 1.0f, zToCoc(i.pos.z));
}
