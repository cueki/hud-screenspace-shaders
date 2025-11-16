// Notebook/Paper Shader - makes the game look like it's drawn on paper
#include "common.hlsl"

// Edge/line strength (0.0 = no outlines, 1.0 = strong pen lines)
#define lineStrength Constants0.x
// Paper grain amount (0.0 = smooth, 0.1 = textured)
#define grainAmount Constants0.y
// Ruled lines spacing (0.0 = no lines, 20.0 = notebook lines)
#define ruledLines Constants0.z
// Paper darkness (0.0 = white paper, 0.2 = aged paper)
#define paperTone Constants0.w

static const float3 LUM_WEIGHTS = float3(0.299, 0.587, 0.114);

// Simple hash function for procedural noise
float hash(float2 p)
{
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

// Paper texture noise
float paperNoise(float2 uv)
{
    float2 p = floor(uv);
    float2 f = frac(uv);
    f = f * f * (3.0 - 2.0 * f);

    float n = p.x + p.y * 157.0;
    return lerp(
        lerp(hash(float2(n + 0.0, n + 0.0)), hash(float2(n + 1.0, n + 1.0)), f.x),
        lerp(hash(float2(n + 157.0, n + 157.0)), hash(float2(n + 158.0, n + 158.0)), f.x),
        f.y
    );
}

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

    // Optional fine grain only
    if (grainAmount > 0.0)
    {
        float grain = paperNoise(i.uv * 2000.0) * grainAmount;
        paper += grain;
    }

    // Draw clean black lines on white paper (no blotch effect)
    float3 finalColor = paper * (1.0 - edge * lineStrength);

    // Optional: Add ruled notebook lines
    if (ruledLines > 0.0)
    {
        float linePos = frac(i.uv.y * ruledLines);
        float isLine = step(0.97, linePos);

        // Slight blue tint for ruled lines
        float3 lineColor = float3(0.6, 0.7, 0.9);
        finalColor = lerp(finalColor, finalColor * lineColor, isLine * 0.4);
    }

    // Slight warm tint for paper feel
    finalColor *= float3(1.0, 0.98, 0.95);

    return float4(finalColor, centerSample.a);
}
