// Notebook Paper Shader
#include "common.hlsl"

// Edge/line strength
#define lineStrength Constants0.x
// Paper grain amount
#define grainAmount Constants0.y
// Ruled lines spacing
#define ruledLines Constants0.z
// Paper darkness
#define paperTone Constants0.w

float4 main( PS_INPUT i ) : COLOR
{
    float2 pixelSize = TexBaseSize.xy;

    // Sample 3x3 grid for Sobel edge detection
    float3 tl = tex2D(TexBase, i.uv + float2(-1, -1) * pixelSize).rgb;
    float3 t  = tex2D(TexBase, i.uv + float2( 0, -1) * pixelSize).rgb;
    float3 tr = tex2D(TexBase, i.uv + float2( 1, -1) * pixelSize).rgb;
    float3 l  = tex2D(TexBase, i.uv + float2(-1,  0) * pixelSize).rgb;
    float4 centerSample = tex2D(TexBase, i.uv);
    float3 c  = centerSample.rgb;
    float3 r  = tex2D(TexBase, i.uv + float2( 1,  0) * pixelSize).rgb;
    float3 bl = tex2D(TexBase, i.uv + float2(-1,  1) * pixelSize).rgb;
    float3 b  = tex2D(TexBase, i.uv + float2( 0,  1) * pixelSize).rgb;
    float3 br = tex2D(TexBase, i.uv + float2( 1,  1) * pixelSize).rgb;

    // Convert to luminance
    float lum_tl = dot(tl, LUM_WEIGHTS);
    float lum_t  = dot(t, LUM_WEIGHTS);
    float lum_tr = dot(tr, LUM_WEIGHTS);
    float lum_l  = dot(l, LUM_WEIGHTS);
    float lum_r  = dot(r, LUM_WEIGHTS);
    float lum_bl = dot(bl, LUM_WEIGHTS);
    float lum_b  = dot(b, LUM_WEIGHTS);
    float lum_br = dot(br, LUM_WEIGHTS);

    // Sobel edge detection
    float gx = -lum_tl - 2.0*lum_l - lum_bl + lum_tr + 2.0*lum_r + lum_br;
    float gy = -lum_tl - 2.0*lum_t - lum_tr + lum_bl + 2.0*lum_b + lum_br;

    // Edge magnitude (comparing squared to avoid sqrt)
    float edgeSq = gx * gx + gy * gy;
    float edge = saturate(edgeSq * 50.0);

    // Clean white paper
    float paperWhite = 1.0 - paperTone;
    float3 paper = float3(paperWhite, paperWhite, paperWhite);

    // Optional grain
    if (grainAmount > 0.0)
    {
        float grain = noise2D(i.uv * 2000.0) * grainAmount;
        paper += grain;
    }

    // Draw black lines on white paper
    float3 finalColor = paper * (1.0 - edge * lineStrength);

    // Optional notebook lines
    if (ruledLines > 0.0)
    {
        float linePos = frac(i.uv.y * ruledLines);
        float isLine = step(0.97, linePos);

        // Blue tint for ruled lines
        float3 lineColor = float3(0.6, 0.7, 0.9);
        finalColor = lerp(finalColor, finalColor * lineColor, isLine * 0.4);
    }

    // Slight warm tint for paper
    finalColor *= float3(1.0, 0.98, 0.95);

    return float4(finalColor, centerSample.a);
}
