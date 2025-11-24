// Cel Shading

#include "common.hlsl"

// Edge thickness (Note: squared internally for optimization)
#define edgeThreshold Constants0.x
// Color bands
#define colorBands Constants0.y
// Edge color darkness
#define edgeDarkness Constants0.z

float4 main( PS_INPUT i ) : COLOR
{
    float2 pixelSize = TexBaseSize.xy;
    float2 uv = scaleFBUV(i.uv);

    // Sample the center pixel
    float4 centerSample = tex2D(TexBase, uv);
    float3 center = centerSample.rgb;

    // Sample 8 surrounding pixels
    float3 tl = tex2D(TexBase, uv + float2(-1, -1) * pixelSize).rgb;
    float3 t  = tex2D(TexBase, uv + float2( 0, -1) * pixelSize).rgb;
    float3 tr = tex2D(TexBase, uv + float2( 1, -1) * pixelSize).rgb;
    float3 l  = tex2D(TexBase, uv + float2(-1,  0) * pixelSize).rgb;
    float3 r  = tex2D(TexBase, uv + float2( 1,  0) * pixelSize).rgb;
    float3 bl = tex2D(TexBase, uv + float2(-1,  1) * pixelSize).rgb;
    float3 b  = tex2D(TexBase, uv + float2( 0,  1) * pixelSize).rgb;
    float3 br = tex2D(TexBase, uv + float2( 1,  1) * pixelSize).rgb;

    // Convert to luminance
    float lum_tl = dot(tl, LUM_WEIGHTS);
    float lum_t  = dot(t,  LUM_WEIGHTS);
    float lum_tr = dot(tr, LUM_WEIGHTS);
    float lum_l  = dot(l,  LUM_WEIGHTS);
    float lum_r  = dot(r,  LUM_WEIGHTS);
    float lum_bl = dot(bl, LUM_WEIGHTS);
    float lum_b  = dot(b,  LUM_WEIGHTS);
    float lum_br = dot(br, LUM_WEIGHTS);

    // Sobel edge detection
    float gx = -lum_tl - 2.0*lum_l - lum_bl + lum_tr + 2.0*lum_r + lum_br;
    float gy = -lum_tl - 2.0*lum_t - lum_tr + lum_bl + 2.0*lum_b + lum_br;

    // Compare squared values
    float edgeSq = gx * gx + gy * gy;
    float thresholdSq = edgeThreshold * edgeThreshold;
    float isEdge = step(thresholdSq, edgeSq);

    // Reduce colors to discrete bands
    float3 quantized = floor(center * colorBands) / colorBands;

    // Darken edges
    float3 finalColor = quantized * lerp(1.0, edgeDarkness, isEdge);

    return float4(finalColor, centerSample.a);
}
