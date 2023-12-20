static const float PI = 3.14159265322f;
//static const int NUM_SAMPLES = 16; // static keyword is required

float NUM_SAMPLES;
sampler blurSampler;
texture2D sceneTexture;
texture2D verticalBlurTexture;
texture2D diagonalBlurTexture;

float coc;
float angle;


struct PSInput
{
    float4 pos : SV_POSITION;
    float2 tex : TEXCOORD0;
};

float4 BlurTexture(texture2D tex, float2 uv, float2 direction)
{
    float4 finalColor = 0.0f;
    float blurAmount = 0.0f;
 
    // This offset is important. Will explain later. ;)
    uv += direction * 0.5f;
 
    for (int i = 0; i < NUM_SAMPLES; ++i)
    {
        float4 color = tex.Sample(blurSampler, uv + direction * i);
        color *= color.a;
        blurAmount += color.a;
        finalColor += color;
    }
 
    return (finalColor / blurAmount);
}

float4 main(PSInput i) : SV_TARGET
{
    uint viewWidth, viewHeight;
    verticalBlurTexture.GetDimensions(viewWidth, viewHeight);
    float2 invViewDimensions = float2(1.0f / viewWidth, 1.0f / viewHeight);
    
    // Get the local CoC to determine the radius of the blur.
    // tu mozna zdefiniowac poziom bluru w zaleznosci od odleglosci z
    float coc = verticalBlurTexture.Sample(blurSampler, i.tex).a;
    
    // CoC-weighted diagonal blur
    float2 blurDir = coc * invViewDimensions * float2(cos(-PI / 6), sin(-PI / 6));
    float4 color = BlurTexture(verticalBlurTexture, i.tex, blurDir) * coc;

    // Combine with the vertical blur 
    // We don't need to divide by 2 here, because there is no overlap 
    return float4(color.xyz + verticalBlurTexture.Sample(blurSampler, i.tex).rgb, coc);
}