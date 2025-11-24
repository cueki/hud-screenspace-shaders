// CMYK Halftone Comic Book Shader
#include "common.hlsl"

// Dot size in pixels
#define dotSize Constants0.x
// Dot sharpness (higher = sharper edges)
#define dotSharpness Constants0.y
// Color saturation boost
#define saturation Constants0.z
// Paper color brightness
#define paperBrightness Constants0.w

// Color normalization strength (0.0 = original, 1.0 = fully normalized)
#define normalizeStrength Constants1.x

// CMYK screen angles (in radians)
#define CYAN_ANGLE    (15.0 * PI / 180.0)
#define MAGENTA_ANGLE (75.0 * PI / 180.0)
#define YELLOW_ANGLE  (0.0 * PI / 180.0)
#define BLACK_ANGLE   (45.0 * PI / 180.0)

float4 rgbToCmyk(float3 rgb)
{
    float k = 1.0 - max(max(rgb.r, rgb.g), rgb.b);
    float3 cmy;

    if (k < 1.0)
    {
        float invK = 1.0 / (1.0 - k);
        cmy.x = (1.0 - rgb.r - k) * invK;
        cmy.y = (1.0 - rgb.g - k) * invK;
        cmy.z = (1.0 - rgb.b - k) * invK;
    }
    else
    {
        cmy = float3(0.0, 0.0, 0.0);
    }

    return saturate(float4(cmy, k));
}

float3 cmykToRgb(float4 cmyk)
{
    float invK = 1.0 - cmyk.w;
    float3 rgb;
    rgb.r = (1.0 - cmyk.x) * invK;
    rgb.g = (1.0 - cmyk.y) * invK;
    rgb.b = (1.0 - cmyk.z) * invK;
    return rgb;
}

// Get the cell center UV for sampling, given an angle
float2 getCellCenterUV(float2 screenPos, float angle)
{
    // Rotate to grid space
    float2 rotated = mul(rotate2d(angle), screenPos);

    // Find cell center in rotated space
    float2 cellIndex = floor(rotated / dotSize);
    float2 cellCenterRotated = (cellIndex + 0.5) * dotSize;

    // Rotate back to screen space
    float2 cellCenterScreen = mul(rotate2d(-angle), cellCenterRotated);

    // Convert to uv
    return cellCenterScreen * TexBaseSize;
}

float halftone(float2 screenPos, float angle, float dotRadius)
{
    // Rotate to grid space
    float2 rotated = mul(rotate2d(angle), screenPos);
    float2 cellPos = frac(rotated / dotSize);
    float2 cellCenter = float2(0.5, 0.5);

    // Distance from cell center
    float dist = length(cellPos - cellCenter) * 2.0;

    // Create dot
    float dot = 1.0 - smoothstep(dotRadius - 0.1 / dotSharpness, dotRadius + 0.1 / dotSharpness, dist);

    return dot;
}

float4 main( PS_INPUT i ) : COLOR
{
    // Get screen position
    float2 screenPos = i.uv / TexBaseSize;

    // Sample the scene color at this pixel
    float4 baseColor = tex2D(TexBase, scaleFBUV(i.uv));
    float3 color = baseColor.rgb;

    // Normalize colors to use full range
    if (normalizeStrength > 0.0)
    {
        float maxChannel = max(max(color.r, color.g), color.b);
        if (maxChannel > 0.01)
        {
            float3 normalized = color / maxChannel;
            color = lerp(color, normalized, normalizeStrength);
        }
    }

    // Boost saturation optional
    if (saturation != 1.0)
    {
        float lum = dot(color, LUM_WEIGHTS);
        color = saturate(lerp(float3(lum, lum, lum), color, saturation));
    }

    // Convert to CMYK
    float4 cmyk = rgbToCmyk(color);

    // Returns 1.0 inside dot, 0.0 outside
    float c = halftone(screenPos, CYAN_ANGLE, cmyk.x);
    float m = halftone(screenPos, MAGENTA_ANGLE, cmyk.y);
    float y = halftone(screenPos, YELLOW_ANGLE, cmyk.z);
    float k = halftone(screenPos, BLACK_ANGLE, cmyk.w);

    // Start with paper
    float3 paper = float3(paperBrightness, paperBrightness * 0.98, paperBrightness * 0.95);
    float3 result = paper;

    // Subtractive color mixing
    // Cyan absorbs red
    result.r *= (1.0 - c);
    // Magenta absorbs green
    result.g *= (1.0 - m);
    // Yellow absorbs blue
    result.b *= (1.0 - y);

    // Black absorbs all
    result *= (1.0 - k);

    // Transition to solid black for very dark areas
    float solidBlackBlend = smoothstep(0.7, 1.0, cmyk.w);
    result = lerp(result, float3(0.0, 0.0, 0.0), solidBlackBlend);

    return float4(result, baseColor.a);
}
