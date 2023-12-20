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

struct PSOUTPUT
{
    float4 vertical : COLOR0;
    float4 diagonal : COLOR1;
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

PSOUTPUT main(PSInput i) : SV_TARGET
{
    uint viewWidth, viewHeight;
    sceneTexture.GetDimensions(viewWidth, viewHeight);
    float2 invViewDimensions = float2(1.0f / viewWidth, 1.0f / viewHeight);
    
    // Get the local CoC to determine the radius of the blur.
    // tu mozna zdefiniowac poziom bluru w zaleznosci od odleglosci z
    float coc = sceneTexture.Sample(blurSampler, i.tex).a;
    
    // CoC-weighted vertical blur.
    float2 blurDir = coc * invViewDimensions * float2(cos(PI / 2), sin(PI / 2));
    float4 color = BlurTexture(sceneTexture, i.tex, blurDir) * coc;

    // CoC-weighted diagonal blur.
    float2 blurDir2 = coc * invViewDimensions * float2(cos(-PI / 6), sin(-PI / 6));
    float4 color2 = BlurTexture(sceneTexture, i.tex, blurDir2) * coc;

    // Output to MRT - multi render target
    PSOUTPUT output;
    output.vertical = float4(color.rgb, coc);
    output.diagonal = float4(0.5 * (color2.rgb + output.vertical.xyz), coc); 
    return output;
}