// PSX-style shader with color quantization and dithering
#include "common.hlsl"

// Color precision (e.g., 16, 32, 64)
#define colorPrecision Constants0.x
// Dither strength (0.0 = none, 1.0 = normal, 2.0 = strong)
#define ditherStrength Constants0.y
// Resolution X for UV snapping (0 = disabled)
#define resolutionX Constants0.z
// Resolution Y for UV snapping (0 = disabled)
#define resolutionY Constants0.w

// Saturation boost (1.0 = normal, 1.3 = boosted)
#define saturation Constants1.x
// Color temperature (-1.0 = cool/blue, 0.0 = neutral, 1.0 = warm/orange)
#define colorTemp Constants1.y
// Chromatic aberration strength (0.0 = none, 0.003 = subtle)
#define aberrationStrength Constants1.z
// RGB subpixel intensity (0.0 = none, 0.3 = subtle, 0.7 = strong)
#define subpixelIntensity Constants1.w

// 4x4 dither pattern (from Godot shader https://godotshaders.com/shader/ps1-psx-model/)
static const float ditherPattern[16] = {
    0.00, 0.50, 0.10, 0.65,
    0.75, 0.25, 0.90, 0.35,
    0.20, 0.70, 0.05, 0.50,
    0.95, 0.40, 0.80, 0.30
};

float getDitherValue(float2 screenPos)
{
    int2 pos = int2(fmod(screenPos, 4.0));
    int index = pos.y * 4 + pos.x;
    return ditherPattern[index];
}

float reduceColor(float raw, float dither, float depth)
{
    float scaled = raw * depth;
    float lower = floor(scaled);
    float frac = scaled - lower;

    if (frac <= dither * 0.999)
        return lower / depth;
    else
        return (lower + 1.0) / depth;
}

float4 main( PS_INPUT i ) : COLOR
{
    float2 uv = i.uv;

    // Snap UV to low-res grid
    if (resolutionX > 0.0 && resolutionY > 0.0)
    {
        float2 res = float2(resolutionX, resolutionY);
        uv = floor(uv * res) / res;
    }

    // Chromatic aberration
    float3 color;
    if (aberrationStrength > 0.0)
    {
        float2 offset = (uv - 0.5) * 2.0;
        float dist = length(offset);
        float abAmount = pow(abs(dist), 0.7) * aberrationStrength;

        float2 uvR = clamp(uv - offset * abAmount, 0.0, 1.0);
        float2 uvB = clamp(uv + offset * abAmount, 0.0, 1.0);

        color.r = tex2D(TexBase, uvR).r;
        color.g = tex2D(TexBase, uv).g;
        color.b = tex2D(TexBase, uvB).b;
    }
    else
    {
        color = tex2D(TexBase, uv).rgb;
    }

    float alpha = tex2D(TexBase, i.uv).a;

    // Saturation boost
    if (saturation != 1.0)
    {
        float lum = dot(color, LUM_WEIGHTS);
        color = lerp(float3(lum, lum, lum), color, saturation);
    }

    // Color temperature
    if (colorTemp != 0.0)
    {
        color.r += colorTemp * 0.1;
        color.g += colorTemp * 0.05;
        color.b -= colorTemp * 0.1;
        color = saturate(color);
    }

    // Get dither value for this pixel
    float2 screenPos = i.uv / TexBaseSize;
    float dither = getDitherValue(screenPos);

    // Color quantization with dithering
    float depth = colorPrecision - 1.0;
    if (ditherStrength > 0.0)
    {
        float threshold = (dither - 0.5) * dither + 0.5;
        color.r = reduceColor(color.r, threshold, depth);
        color.g = reduceColor(color.g, threshold, depth);
        color.b = reduceColor(color.b, threshold, depth);
    }
    else
    {
        color = floor(color * colorPrecision) / colorPrecision;
    }
    color = saturate(color);

    // RGB subpixel pattern (my shitty attempt at CRT phosphor simulation)
    if (subpixelIntensity > 0.0)
    {
        float2 screenPos = i.uv / TexBaseSize;
        int subpixel = int(fmod(screenPos.x, 3.0));

        float3 mask = float3(1.0, 1.0, 1.0);
        if (subpixel == 0)
            mask = float3(1.0, 1.0 - subpixelIntensity * 0.5, 1.0 - subpixelIntensity * 0.5);
        else if (subpixel == 1)
            mask = float3(1.0 - subpixelIntensity * 0.5, 1.0, 1.0 - subpixelIntensity * 0.5);
        else
            mask = float3(1.0 - subpixelIntensity * 0.5, 1.0 - subpixelIntensity * 0.5, 1.0);

        color *= mask;
    }

    return float4(color, alpha);
}
