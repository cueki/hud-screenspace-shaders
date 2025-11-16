// Depth fog shader

#include "common.hlsl"

sampler Texture1 : register(s1);  // _rt_FullFrameDepth

// Fog start distance via $c0_x (0.0 = near, 1.0 = far)
#define fogStart Constants0.x
// Fog density via $c0_y
#define fogDensity Constants0.y
// Fog color via $c1 (RGB)
#define fogColor float3(Constants1.x, Constants1.y, Constants1.z)

float4 main( PS_INPUT i ) : COLOR
{
    float4 baseColor = tex2D(TexBase, i.uv);
    float depth = tex2D(Texture1, i.uv).a;
    float fogAmount = saturate((depth - fogStart) * fogDensity);
    float3 fogged = lerp(baseColor.rgb, fogColor, fogAmount);

    return float4(fogged, baseColor.a);
}
