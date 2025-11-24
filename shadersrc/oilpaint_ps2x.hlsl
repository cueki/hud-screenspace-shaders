// Oil Paint Shader (Kuwahara Filter) with enhanced vibrancy
#include "common.hlsl"

// Brush size multiplier
#define brushSize Constants0.x
// Color quantization
#define colorBands Constants0.y
// Vibrancy boost
#define vibrancy Constants0.z
// Shadow floor
#define shadowFloor Constants0.w

float4 main( PS_INPUT i ) : COLOR
{
    float2 pixelSize = TexBaseSize.xy * brushSize;
    float2 uv = scaleFBUV(i.uv);

    // Sample 3x3 grid
    float3 tl = tex2D(TexBase, uv + float2(-1, -1) * pixelSize).rgb;
    float3 t  = tex2D(TexBase, uv + float2( 0, -1) * pixelSize).rgb;
    float3 tr = tex2D(TexBase, uv + float2( 1, -1) * pixelSize).rgb;
    float3 l  = tex2D(TexBase, uv + float2(-1,  0) * pixelSize).rgb;
    float4 centerSample = tex2D(TexBase, uv);
    float3 c  = centerSample.rgb;
    float3 r  = tex2D(TexBase, uv + float2( 1,  0) * pixelSize).rgb;
    float3 bl = tex2D(TexBase, uv + float2(-1,  1) * pixelSize).rgb;
    float3 b  = tex2D(TexBase, uv + float2( 0,  1) * pixelSize).rgb;
    float3 br = tex2D(TexBase, uv + float2( 1,  1) * pixelSize).rgb;

    // Kuwahara filter

    // Quadrant 0: top-left
    float3 mean0 = (tl + t + l + c) * 0.25;
    float lum0_1 = dot(tl, LUM_WEIGHTS);
    float lum0_2 = dot(t, LUM_WEIGHTS);
    float lum0_3 = dot(l, LUM_WEIGHTS);
    float lum0_4 = dot(c, LUM_WEIGHTS);
    float mean0_lum = (lum0_1 + lum0_2 + lum0_3 + lum0_4) * 0.25;
    float var0 = abs(lum0_1 - mean0_lum) + abs(lum0_2 - mean0_lum) +
                 abs(lum0_3 - mean0_lum) + abs(lum0_4 - mean0_lum);

    // Quadrant 1: top-right
    float3 mean1 = (t + tr + c + r) * 0.25;
    float lum1_1 = dot(t, LUM_WEIGHTS);
    float lum1_2 = dot(tr, LUM_WEIGHTS);
    float lum1_3 = dot(c, LUM_WEIGHTS);
    float lum1_4 = dot(r, LUM_WEIGHTS);
    float mean1_lum = (lum1_1 + lum1_2 + lum1_3 + lum1_4) * 0.25;
    float var1 = abs(lum1_1 - mean1_lum) + abs(lum1_2 - mean1_lum) +
                 abs(lum1_3 - mean1_lum) + abs(lum1_4 - mean1_lum);

    // Quadrant 2: bottom-left
    float3 mean2 = (l + c + bl + b) * 0.25;
    float lum2_1 = dot(l, LUM_WEIGHTS);
    float lum2_2 = dot(c, LUM_WEIGHTS);
    float lum2_3 = dot(bl, LUM_WEIGHTS);
    float lum2_4 = dot(b, LUM_WEIGHTS);
    float mean2_lum = (lum2_1 + lum2_2 + lum2_3 + lum2_4) * 0.25;
    float var2 = abs(lum2_1 - mean2_lum) + abs(lum2_2 - mean2_lum) +
                 abs(lum2_3 - mean2_lum) + abs(lum2_4 - mean2_lum);

    // Quadrant 3: bottom-right
    float3 mean3 = (c + r + b + br) * 0.25;
    float lum3_1 = dot(c, LUM_WEIGHTS);
    float lum3_2 = dot(r, LUM_WEIGHTS);
    float lum3_3 = dot(b, LUM_WEIGHTS);
    float lum3_4 = dot(br, LUM_WEIGHTS);
    float mean3_lum = (lum3_1 + lum3_2 + lum3_3 + lum3_4) * 0.25;
    float var3 = abs(lum3_1 - mean3_lum) + abs(lum3_2 - mean3_lum) +
                 abs(lum3_3 - mean3_lum) + abs(lum3_4 - mean3_lum);

    // Select the mean color from the quadrant with minimum variance
    float3 finalColor = mean0;
    float minVar = var0;

    if (var1 < minVar) {
        finalColor = mean1;
        minVar = var1;
    }
    if (var2 < minVar) {
        finalColor = mean2;
        minVar = var2;
    }
    if (var3 < minVar) {
        finalColor = mean3;
    }

    // Optional: quantize colors for more flat paint effect
    if (colorBands > 0.0)
    {
        finalColor = floor(finalColor * colorBands) / colorBands;

        // Remap to prevent pure black shadows
        finalColor = shadowFloor + finalColor * (1.0 - shadowFloor);
    }

    // Optional: increase saturation and contrast
    if (vibrancy > 0.0)
    {
        // Saturation
        float lum = dot(finalColor, LUM_WEIGHTS);
        finalColor = lerp(float3(lum, lum, lum), finalColor, vibrancy);

        // Contrast
        finalColor = finalColor * finalColor * (3.0 - 2.0 * finalColor);
    }

    return float4(finalColor, centerSample.a);
}
