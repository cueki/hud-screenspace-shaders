// common data shared among all screenspace shaders

// Common constants
static const float3 LUM_WEIGHTS = float3(0.299, 0.587, 0.114);
#define PI 3.14159265359

// Hash functions
float hash(float n)
{
    return frac(sin(n) * 43758.5453);
}

float hash2(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * 0.2831);
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
}

// 2D noise
float noise2D(float2 x)
{
    float2 p = floor(x);
    float2 f = frac(x);
    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 157.0;
    return lerp(
        lerp(hash(n + 0.0), hash(n + 1.0), f.x),
        lerp(hash(n + 157.0), hash(n + 158.0), f.x),
        f.y
    );
}

// 2D rotation matrix
float2x2 rotate2d(float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    return float2x2(c, -s, s, c);
}

// up to four textures available for sampling
sampler TexBase : register( s0 ); // $basetexture
sampler Tex1    : register( s1 ); // $texture1
sampler Tex2    : register( s2 ); // $texture2
sampler Tex3    : register( s3 ); // $texture3

// normalized dimensions for each texture above
// (x = 1.0 / width, y = 1.0 / height)
// NOT AVAILABLE IN L4D2/PORTAL 2
float2 TexBaseSize : register( c4 );
float2 Tex1Size    : register( c5 );
float2 Tex2Size    : register( c6 );
float2 Tex3Size    : register( c7 );

// customizable parameters $c0, $c1, $c2, $c3, $c4
const float4 Constants0 : register( c0 );
const float4 Constants1 : register( c1 );
const float4 Constants2 : register( c2 );
const float4 Constants3 : register( c3 );
// ONLY AVAILABLE IN L4D2/PORTAL2 (
const float4 Constants4 : register( c4 );

// eye position in world coordinates
// WARNING: this is calculated from the view matrix
// on a screen overlay, this will return near-zero values
// use PlayerPosition VMT proxy as a workaround
const float4 EyePosition : register( c10 );

// xyz will be 0, 0, 0 (black) if mesh is rendered without fog
const float4 FogColor    : register( c29 );
// range of compressed depth buffer. usually 1.0 / 192
#define DepthRange         FogColor.w 

const float4 HDRParams   : register( c30 );
// exposure scale (bounded by tonemap controller's min/max)
#define TonemapScale       HDRParams.x
// 16 in HDR, 4.59479 in LDR
#define LightmapScale      HDRParams.y
// 16 in HDR, 1 in LDR
#define EnvmapScale        HDRParams.z
// gamma, equivalent to pow(TonemapScale, 1.0 / 2.2)
#define GammaScale         HDRParams.w

// interpolated vertex data from vertex shader, do not change
struct PS_INPUT
{
	// texture coordinates
	float2 uv		    : TEXCOORD0;
	// always (0, 0)
	float2 zeros        : TEXCOORD1;
	// unused
	float2 texcoord2    : TEXCOORD2;
	// vertex color (if mesh has one)
	float4 color		: TEXCOORD3;
	// screenspace position
	// SHADER MODEL 3 ONLY
	float2 pos			: VPOS;
};