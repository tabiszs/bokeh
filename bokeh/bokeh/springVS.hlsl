matrix modelMtx, modelInvTMtx, viewProjMtx;
float4 camPos;

float h0, l, r, rsmall;
float time, xmax, vmax, thalf;

struct VSInput
{
    float3 pos : POSITION0;
    float3 norm : NORMAL0;
    float2 tex : TEXCOORD0;
};

struct VSOutput
{
    float4 pos : SV_POSITION;
    float3 worldPos : POSITION0;
    float3 norm : NORMAL0;
    float3 view : VIEWVEC0;
    float2 tex : TEXCOORD0;
    float3 tangent : TANGENT0;
};

float dangle_ds(const float l, const float r, const float h) {
    return sqrt(l * l - h * h) / r;
}

float3 get_position(const float s, const float r, const float h, const float a) {
    return float3(
        r * cos(s * a),
        s * h,
        r * sin(s * a)
    );
}

float3 get_tangent(const float s, const float r, const float h, const float a) {
    return float3(
        -a * r * sin(s * a),
        h,
        a * r * cos(s * a)
    );
}

float3 get_normal(const float s, const float r, const float h, const float a) {
    return float3(
        -a * a * r * cos(s * a),
        0,
        -a * a * r * sin(s * a)
    );
}

static const float two_pi = 6.283185307179586476925286766559f;

float spring_height(const float t) {
    return xmax * exp(log(0.5f) * t / thalf) * sin(vmax / xmax * t);
}

VSOutput main(VSInput i)
{
    const float h = h0 + spring_height(time);
    const float a = dangle_ds(l, r, h);
    const float3 curve_position = get_position(i.pos.y, r, h, a);
    const float3 curve_tangent = normalize(get_tangent(i.pos.y, r, h, a));
    const float3 curve_normal = normalize(get_normal(i.pos.y, r, h, a));
    const float3 curve_binormal = cross(curve_normal, curve_tangent);
    const float3 normal = curve_normal * cos(two_pi * i.pos.x) + curve_binormal * sin(two_pi * i.pos.x);
    const float4 position = float4(curve_position + rsmall * normal, 1.0f);

    VSOutput o;
    float4 worldPos = mul(modelMtx, position);
    o.view = normalize(camPos.xyz - worldPos.xyz);
    o.norm = normalize(mul(modelInvTMtx, float4(normal, 0.0f)).xyz);
    o.worldPos = worldPos.xyz;
    o.pos = mul(viewProjMtx, worldPos);
    o.tangent = mul(modelInvTMtx, float4(curve_tangent, 0.0f)).xyz;
    o.tex = float2(i.pos.y * 20.0f, i.pos.x * 2.0f);

    return o;
}