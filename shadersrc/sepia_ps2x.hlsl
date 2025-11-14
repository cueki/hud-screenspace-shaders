// Sepia tone shader

#include "common.hlsl"

// Sepia intensity
#define sepiaStrength Constants0.x

float4 main( PS_INPUT i ) : COLOR
{
    float4 color = tex2D(TexBase, i.uv);

    // Classic sepia tone matrix
    float4 sepiaColor;
    sepiaColor.r = (color.r * 0.393) + (color.g * 0.769) + (color.b * 0.189);
    sepiaColor.g = (color.r * 0.349) + (color.g * 0.686) + (color.b * 0.168);
    sepiaColor.b = (color.r * 0.272) + (color.g * 0.534) + (color.b * 0.131);
    sepiaColor.a = color.a;

    // Combine original and sepia based on strength
    float strength = clamp(sepiaStrength, 0.0, 1.0);
    float4 finalColor = lerp(color, sepiaColor, strength);

    return finalColor;
}
