// Red tint shader
#include "common.hlsl"

// Number of posterization levels
#define levels Constants0.x
// White threshold
#define whiteThreshold Constants0.y
// Black threshold
#define blackThreshold Constants0.z

float4 main( PS_INPUT i ) : COLOR
{
    float4 col = tex2D(TexBase, scaleFBUV(i.uv));

    // Get luminance
    float lum = dot(col.rgb, LUM_WEIGHTS);

    // Posterize
    lum = floor(lum * levels) / levels;

    // Map to white/red/black with cutoffs
    float3 result;
    if (lum > whiteThreshold)
    {
        result = float3(1.0, 1.0, 1.0); // white
    }
    else if (lum > blackThreshold)
    {
        result = float3(1.0, 0.0, 0.0); // red
    }
    else
    {
        result = float3(0.0, 0.0, 0.0); // black
    }

    return float4(result, col.a);
}
