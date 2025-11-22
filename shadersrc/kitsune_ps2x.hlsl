// Kitsune
#include "common.hlsl"

#define edgeMin       Constants0.x
#define edgeMax       Constants0.y
#define preGamma      Constants0.z
#define edgeThreshold Constants0.w
#define edgePower     Constants1.x

// Sample RGB with gamma preprocessing
float3 sampleRGB(float2 uv) {
    float3 c = tex2D(TexBase, uv).rgb;
    return pow(c, preGamma);
}

// Sobel on each RGB channel, return max edge response
float sobelEdge(float2 uv, float2 px) {
    float3 tl = sampleRGB(uv + float2(-1, -1) * px);
    float3 t  = sampleRGB(uv + float2( 0, -1) * px);
    float3 tr = sampleRGB(uv + float2( 1, -1) * px);
    float3 l  = sampleRGB(uv + float2(-1,  0) * px);
    float3 r  = sampleRGB(uv + float2( 1,  0) * px);
    float3 bl = sampleRGB(uv + float2(-1,  1) * px);
    float3 b  = sampleRGB(uv + float2( 0,  1) * px);
    float3 br = sampleRGB(uv + float2( 1,  1) * px);

    float3 gx = -tl - 2.0*l - bl + tr + 2.0*r + br;
    float3 gy = -tl - 2.0*t - tr + bl + 2.0*b + br;

    float3 edge = sqrt(gx*gx + gy*gy);
    return max(edge.r, max(edge.g, edge.b));
}

float4 main(PS_INPUT i) : COLOR
{
    float4 baseColor = tex2D(TexBase, i.uv);

    float rawEdge = sobelEdge(i.uv, TexBaseSize);
    float conf = smoothstep(edgeMin, edgeMax, rawEdge);
    conf = pow(conf, edgePower);
    float edgeMask = step(edgeThreshold, conf);

    // Pick the most saturated color from neighbors
    float3 bestColor = baseColor.rgb;
    float bestSat = 0.0;

    for (int ox = -1; ox <= 1; ox++)
    {
        for (int oy = -1; oy <= 1; oy++)
        {
            float3 c = tex2D(TexBase, i.uv + float2(ox, oy) * TexBaseSize).rgb;
            float cMax = max(c.r, max(c.g, c.b));
            float cMin = min(c.r, min(c.g, c.b));
            float sat = (cMax - cMin) / (cMax + 0.001);
            if (sat > bestSat)
            {
                bestSat = sat;
                bestColor = c;
            }
        }
    }

    // Normalize to full brightness
    float maxChannel = max(bestColor.r, max(bestColor.g, bestColor.b));
    float3 outlineColor = bestColor / (maxChannel + 0.001);

    // Flip black to white
    float outlineLum = dot(outlineColor, LUM_WEIGHTS);
    outlineColor = (outlineLum < 0.01) ? float3(1, 1, 1) : outlineColor;

    // Edge in object color
    float3 finalColor = outlineColor * edgeMask;

    return float4(finalColor, baseColor.a);
}
