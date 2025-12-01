// Flappy Bird
#include "common.hlsl"

// Game state
#define birdY Constants0.x
#define pipe1X Constants0.y
#define pipe1GapY Constants0.z
#define pipe2X Constants0.w
#define pipe2GapY Constants1.x
#define gameOver Constants1.y
#define pipe1GapSize Constants1.z
#define pipe2GapSize Constants1.w

// Settings
#define pipeWidth 0.1
#define birdX 0.2
#define birdSize 0.04

float4 main( PS_INPUT i ) : COLOR
{
    float2 uv = i.uv;
    uv.y = 1.0 - uv.y; // flip Y so 0 is bottom

    // Blue background
    float3 color = float3(0.4, 0.7, 1.0);

    // Ground
    if (uv.y < 0.1)
    {
        color = float3(0.6, 0.4, 0.2);
        if (uv.y > 0.08)
        {
            color = float3(0.3, 0.8, 0.2);
        }
    }

    // Pipe 1
    if (uv.x > pipe1X && uv.x < pipe1X + pipeWidth)
    {
        float gapTop = pipe1GapY + pipe1GapSize;
        float gapBottom = pipe1GapY - pipe1GapSize;

        // Top pipe or bottom pipe
        if (uv.y > gapTop || uv.y < gapBottom)
        {
            color = float3(0.2, 0.8, 0.2);

            // Pipe edge
            float edgeDist = min(abs(uv.x - pipe1X), abs(uv.x - (pipe1X + pipeWidth)));
            if (edgeDist < 0.01)
            {
                color = float3(0.1, 0.5, 0.1);
            }
        }
    }

    // Pipe 2
    if (uv.x > pipe2X && uv.x < pipe2X + pipeWidth)
    {
        float gapTop = pipe2GapY + pipe2GapSize;
        float gapBottom = pipe2GapY - pipe2GapSize;

        if (uv.y > gapTop || uv.y < gapBottom)
        {
            color = float3(0.2, 0.8, 0.2);

            float edgeDist = min(abs(uv.x - pipe2X), abs(uv.x - (pipe2X + pipeWidth)));
            if (edgeDist < 0.01)
            {
                color = float3(0.1, 0.5, 0.1);
            }
        }
    }

    // Bird
    float2 birdCenter = float2(birdX, birdY);
    float distToBird = length(uv - birdCenter);

    if (distToBird < birdSize)
    {
        color = float3(1.0, 0.9, 0.2);
        if (uv.y < birdCenter.y - birdSize * 0.2)
        {
            color = float3(1.0, 0.6, 0.2);
        }

        float2 eyePos = birdCenter + float2(birdSize * 0.4, birdSize * 0.3);
        if (length(uv - eyePos) < birdSize * 0.25)
        {
            color = float3(1.0, 1.0, 1.0);
            if (length(uv - eyePos) < birdSize * 0.12)
            {
                color = float3(0.0, 0.0, 0.0);
            }
        }
    }

    // Game over
    if (gameOver > 0.5)
    {
        color = lerp(color, float3(1.0, 0.0, 0.0), 0.3);
    }

    return float4(color, 1.0);
}
