#define NLIGHTS 2

float4 lightPos[NLIGHTS];
float3 lightColor[NLIGHTS];
float3 surfaceColor;
static const float ks = 1;
static const float kd = 0.1;
static const float ka = 0.1;
static const float m = 10;

float4 phong(const float3 worldPos, float3 norm, float3 view) {
    view = normalize(view);
    norm = normalize(norm);
    float3 color = surfaceColor * ka;
    for (int k = 0; k < NLIGHTS; ++k) {
        const float3 lightVec = normalize(lightPos[k].xyz - worldPos);
        const float3 halfVec = normalize(view + lightVec);
        color += lightColor[k] * kd * surfaceColor * saturate(dot(norm, lightVec)); //diffuse
        color += lightColor[k] * ks * pow(saturate(dot(norm, halfVec)), m);         //specular
    }
    return saturate(float4(color, 1.0f));
}

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
    const float3 color = phong(i.worldPos, i.norm, i.view).rgb;
    return float4(color, zToCoc(i.pos.z));
}
