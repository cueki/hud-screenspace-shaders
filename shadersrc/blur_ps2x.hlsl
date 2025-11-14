// Simple 3x3 Box Blur shader

#include "common.hlsl"

// Blur strength multiplier via $c0_x
#define blurStrength Constants0.x

float4 getAverageColor(float2 uv, float2 pixelSize)
{
    float4 color = float4(0, 0, 0, 0);

    for (int x = -1; x < 2; x++)
    {
        for (int y = -1; y < 2; y++)
        {
            float2 offset = float2(x, y) * pixelSize;
            color += tex2D(TexBase, uv + offset);
        }
    }

    color /= 9.0;

    return color;
}

float4 main( PS_INPUT i ) : COLOR
{
    // Calculate pixel size and scale by blur strength
    float2 pixelSize = TexBaseSize.xy * blurStrength;
    float4 blurredColor = getAverageColor(i.uv, pixelSize);

    return blurredColor;
}
