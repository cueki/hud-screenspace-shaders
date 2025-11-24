// Night Mode
#include "common.hlsl"

// Base channel multipliers
#define rMult Constants0.x
#define gMult Constants0.y
#define bMult Constants0.z

// Shadow extra multipliers
#define shadowRMult Constants1.x
#define shadowGMult Constants1.y
#define shadowBMult Constants1.z

// Mask settings
#define maskThreshold Constants0.w
#define maskSoftness Constants1.w

float4 main( PS_INPUT i ) : COLOR
{
    float3 color = tex2D(TexBase, scaleFBUV(i.uv)).rgb;

    // Shadow mask
    float luma = dot(color, float3(0.2126, 0.7152, 0.0722));
    float lowEdge = max(0.0, maskThreshold - maskSoftness);
    float mask = 1.0 - smoothstep(lowEdge, maskThreshold, luma);

    // Base color grade
    float3 graded;
    graded.r = color.r * rMult;
    graded.g = color.g * gMult;
    graded.b = color.b * bMult;

    // Extra shadow shift
    float3 shadowShift;
    shadowShift.r = graded.r * shadowRMult;
    shadowShift.g = graded.g * shadowGMult;
    shadowShift.b = graded.b * shadowBMult;

    // Blend shadow shift based on mask
    float3 result = lerp(graded, shadowShift, mask);

    return float4(saturate(result), 1.0);
}
