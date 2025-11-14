// Cel Shading

#include "common.hlsl"

// Edge thickness
#define edgeThreshold Constants0.x
// Color bands
#define colorBands Constants0.y
// Edge color darkness
#define edgeDarkness Constants0.z

float4 main( PS_INPUT i ) : COLOR
{
    float2 pixelSize = TexBaseSize.xy;

    // Sample the center pixel
    float3 center = tex2D(TexBase, i.uv).rgb;

    // Sample 8 surrounding pixels
    float3 tl = tex2D(TexBase, i.uv + float2(-1, -1) * pixelSize).rgb;
    float3 t  = tex2D(TexBase, i.uv + float2( 0, -1) * pixelSize).rgb;
    float3 tr = tex2D(TexBase, i.uv + float2( 1, -1) * pixelSize).rgb;
    float3 l  = tex2D(TexBase, i.uv + float2(-1,  0) * pixelSize).rgb;
    float3 r  = tex2D(TexBase, i.uv + float2( 1,  0) * pixelSize).rgb;
    float3 bl = tex2D(TexBase, i.uv + float2(-1,  1) * pixelSize).rgb;
    float3 b  = tex2D(TexBase, i.uv + float2( 0,  1) * pixelSize).rgb;
    float3 br = tex2D(TexBase, i.uv + float2( 1,  1) * pixelSize).rgb;

    // Convert to luminance
    float lum_tl = dot(tl, float3(0.299, 0.587, 0.114));
    float lum_t  = dot(t,  float3(0.299, 0.587, 0.114));
    float lum_tr = dot(tr, float3(0.299, 0.587, 0.114));
    float lum_l  = dot(l,  float3(0.299, 0.587, 0.114));
    float lum_r  = dot(r,  float3(0.299, 0.587, 0.114));
    float lum_bl = dot(bl, float3(0.299, 0.587, 0.114));
    float lum_b  = dot(b,  float3(0.299, 0.587, 0.114));
    float lum_br = dot(br, float3(0.299, 0.587, 0.114));

    // Horizontal gradient
    float gx = -lum_tl - 2.0*lum_l - lum_bl + lum_tr + 2.0*lum_r + lum_br;
    // Vertical gradient
    float gy = -lum_tl - 2.0*lum_t - lum_tr + lum_bl + 2.0*lum_b + lum_br;
    // Gradient magnitude
    float edge = sqrt(gx * gx + gy * gy);

    // Edging threshold
    float isEdge = step(edgeThreshold, edge);

    // Reduce colors to discrete bands
    float3 quantized = floor(center * colorBands) / colorBands;

    // Darken edges
    float3 finalColor = quantized * lerp(1.0, edgeDarkness, isEdge);

    return float4(finalColor, 1.0);
}
