// Rain shader
#include "common.hlsl"

#define iTime Constants0.x

float4 main( PS_INPUT i ) : COLOR
{
    float2 q = i.uv;
    float2 p = -1.0 + 2.0 * q;
    p.x *= 1.0 / (TexBaseSize.x / TexBaseSize.y);

    // Chromatic aberration
    float2 offset = (q - 0.5) * 2.0;
    float dist = length(offset);
    float aberrationStrength = pow(abs(dist), 0.7) * 0.0022; // Power < 1 makes it extend further in

    float2 uvR = clamp(i.uv - offset * aberrationStrength, 0.0, 1.0);
    float2 uvB = clamp(i.uv + offset * aberrationStrength, 0.0, 1.0);

    float r = tex2D(TexBase, uvR).r;
    float g = tex2D(TexBase, i.uv).g;
    float b = tex2D(TexBase, uvB).b;
    float4 baseColor = float4(r, g, b, tex2D(TexBase, i.uv).a);

    // Rain (by Dave Hoskins) with variation to reduce repetition
    float time = iTime;
    float2 st = 256.0 * (p * float2(0.5, 0.01) + float2(-time * 0.091 - q.y * 0.6, -time * 0.091));

    // Multiple noise layers
    float f = noise2D(st) * noise2D(st * 0.773) * 1.55;
    f += 0.5 * noise2D(st * 1.2 + float2(100.0, 100.0)) * noise2D(st * 0.9);

    f = 0.25 + clamp(pow(abs(f), 13.0) * 13.0, 0.0, q.y * 0.14);

    float sceneBrightness = dot(baseColor.rgb, LUM_WEIGHTS); // Luminance
    float lightInteraction = f * sceneBrightness * 3.0;

    // Add rain
    float3 backgroundColor = float3(0.2, 0.4, 0.6) * 0.09;
    float3 rainColor = 0.25 * f * (0.2 + backgroundColor);

    // Add light-interacting rain with warm tint for light sources
    rainColor += lightInteraction * float3(1.0, 0.9, 0.7);

    float3 col = baseColor.rgb + rainColor;

    col *= 0.3;

    // Warm color tint
    col *= 1.2 * float3(1.0, 0.97, 0.88);

    // Desaturate
    float lum = dot(col, LUM_WEIGHTS);
    col = lerp(col, float3(lum, lum, lum), 0.2); // 20% desaturation

    // Contrast adjustment
    col = clamp(1.03 * col - 0.01, 0.0, 1.0);

    // Highlight compression
    col = col * (1.0 - col * 0.5);

    // Film grain
    float invLum = clamp(1.0 - dot(LUM_WEIGHTS, col), 0.0, 1.0);
    float seed = (q.x + 4.0) * (q.y + 4.0) * (fmod(time, 10.0) + 12342.876);
    float grain = frac((fmod(seed, 13.0) + 1.0) * (fmod(seed, 127.0) + 1.0)) - 0.5;
    grain *= smoothstep(0.1, 0.7, invLum * invLum);
    col += 0.01 * grain;

    // Vignette
    col *= 0.05 + 0.95 * pow(abs(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y)), 0.5);

    return float4(col, baseColor.a);
}
