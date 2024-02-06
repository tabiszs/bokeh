static const float PI = 3.14159265322f;
//static const int NUM_SAMPLES = 16; // static keyword is required

float angle;
float coc_factor;
float NUM_SAMPLES;
sampler blurSampler;
Texture2D sceneTexture;
Texture2D verticalBlurTexture;
Texture2D diagonalBlurTexture;


struct PSInput {
    float4 pos : SV_POSITION;
    float2 tex : TEXCOORD0;
};

float4 BlurTexture(Texture2D tex, float2 uv, const float2 direction) {
    float4 finalColor = 0.0f;
    float blurAmount = 0.0f;

    // Remove Rhombi Overlap
    uv += direction * 0.5f;

    for (int i = 0; i < NUM_SAMPLES; ++i) {
        float4 color = tex.Sample(blurSampler, uv + direction * i);
        color *= color.a;
        blurAmount += color.a;
        finalColor += color;
    }

    return (finalColor / blurAmount);
}

float4 main(const PSInput i) : SV_TARGET {
    uint viewWidth, viewHeight;
    verticalBlurTexture.GetDimensions(viewWidth, viewHeight);
    const float2 invViewDimensions = float2(1.0f / viewWidth, 1.0f / viewHeight);

    // Get the center to determine the radius of the blur
    float4 centerColor = verticalBlurTexture.Sample(blurSampler, i.tex);
    float4 centerColor2 = diagonalBlurTexture.Sample(blurSampler, i.tex);
    const float coc = centerColor.a;
    const float coc2 = centerColor2.a;

    // Compute the blur direction. Here, diagonal.
    const float2 blurDirection = coc * invViewDimensions * float2(cos(angle - PI / 6), sin(angle - PI / 6));
    const float2 blurDirection2 = coc2 * invViewDimensions * float2(cos(angle - 5 * PI / 6), sin(angle - 5 * PI / 6));

    // Blur using the weights to bias it
    float4 color = BlurTexture(verticalBlurTexture, i.tex, blurDirection) * coc;
    float4 color2 = BlurTexture(diagonalBlurTexture, i.tex, blurDirection2) * coc2;

    float3 output = (color.rgb + color2.rgb) * 0.5f;

    // Expose. Hacked-up for this demo.
    // return float4(1 - exp(-output.rgb / 8), 1.0f);
    return float4(output, 1.0f);
}
