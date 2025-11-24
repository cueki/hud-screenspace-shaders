// Fullbright shader - compress brightness range
#include "common.hlsl"

// Output range minimum
#define outputMin Constants0.x
// Output range maximum
#define outputMax Constants0.y
// Maximum scale factor to prevent artifacts in very dark areas
#define maxScale Constants0.z
// Blend back toward original
#define blendBack Constants0.w
// Final darkness multiplier
#define finalDarken Constants1.x

float4 main( PS_INPUT i ) : COLOR
{
    float4 baseColor = tex2D(TexBase, scaleFBUV(i.uv));
    float3 color = baseColor.rgb;

    // Current brightness
    float brightness = max(max(color.r, color.g), color.b);

    // Remap brightness: map 0-1.0 linearly to outputMin-outputMax
    float newBrightness = outputMin + (brightness * (outputMax - outputMin));
    float scale = newBrightness / max(brightness, 0.001);

    // Prevent artifacts in very dark areas
    scale = min(scale, maxScale);
    float3 result = color * scale;
    result = lerp(result, color, blendBack);

    // Darkening pass
    result = result * finalDarken;

    return float4(saturate(result), baseColor.a);
}
