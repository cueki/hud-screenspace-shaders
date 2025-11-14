## What This Is

A collection of ready-to-use screenspace shaders for TF2 that can be activated via HUD elements.

**Compilation:** See [sdk_screenspace_shaders](https://github.com/ficool2/sdk_screenspace_shaders) for how to compile HLSL shaders. 

### Required Game Setting

Add to your `autoexec`:
```
mat_hdr_level 1
```

For right now, **this is mandatory.** Without it, shaders will show black/white screens.

`_rt_FullFrameFB` (the full framebuffer) only works properly when the post-processing pipeline runs. `mat_hdr_level 1` forces this.

### Installation

1. Shader files go into folder to `hud/shaders/fcx/`
2. VMT files go in `hud/materials/vgui/replay/thumbnails/`
3. Activate via HUD ImagePanel or console commands (sv_cheats 1 only)

### ImagePanel

```
CustomShaderOverlay
{
    "ControlName"	"ImagePanel"
    "xpos"		    "0"
    "ypos"		    "0"
    "zpos"		    "-10000"
    "wide"		    "f0"
    "tall"		    "480"
    "scaleimage"	"1"
    "image"			"replay/thumbnails/depthfog_far"
}
```

### VMT Template

Minimal working VMT for custom shaders:

```
"screenspace_general"
{
    // No need for the b at the end of the filename
    $pixshader   "yourshader_ps20"
    $basetexture "_rt_FullFrameFB"
    
    // Optional extra textures you can pass to the shader
    // $texture1    ""
    // $texture2    ""
    // $texture3    ""
    
    // Extra texture settings
    // $linearread_basetexture    0
    // $linearread_texture1       0
    // $linearread_texture2       0
    // $linearread_texture3       0

    $x360appchooser 1     // Required for vertex transformations
    $fix_fb         32768 // For proxy
    
    // from testing I saw no difference with these on or off (more testing needed)
    $copyalpha                 1     // Required?
    $ignorez                   1     // Required?
    $alpha_blend_color_overlay 0
    $alpha_blend               0
    $linearwrite               0
    
    // 16 customizable parameters that are passed to the shader
    $c0_x     0.0
    $c0_y     0.0
    $c0_z     0.0
    $c0_w     0.0
    // ...this block repeats 3 more times with the number after $c incrementing by 1

    "<dx90"
    {
        $no_draw 1
    }

    Proxies
    {
        Equals
        {
            // Updates the framebuffer
            // You only need this if you are going to be *reading* the framebuffer
            // If you aren't using the framebuffer, or are only fetching its dimensions,
            // you DON'T need this and it will save you some performance
            srcVar1     $fix_fb
            resultVar   $flags2
        }
    }
}
```

### Animating Parameters

Shaders with time parameters (like rain) auto-update via CurrentTime proxy:

```
Proxies
{
    CurrentTime
    {
        resultVar   $c0_x
    }
}
```

### How to Access Depth

You probably don't want to be doing this...

```hlsl
sampler Texture1 : register(s1);  // _rt_FullFrameDepth

float4 main( PS_INPUT i ) : COLOR
{
    float3 color = tex2D(TexBase, i.uv).rgb;
    float depth = tex2D(Texture1, i.uv).a;

    // Use depth here...
}
```

**VMT:**
```
$basetexture "_rt_FullFrameFB"
$texture1    "_rt_FullFrameDepth"
```

#### Depth Buffer Limitations

1. Depth is in alpha channel
2. God awful range (192 units)
3. Viewmodels don't write to depth

**Problem:** Depth-based effects fog/blur viewmodels because depth reads the world behind them.

**Hacky solution:** Color difference masking

```hlsl
sampler Texture1 : register(s1);  // _rt_PowerOfTwoFB
sampler Texture2 : register(s2);  // _rt_FullFrameDepth

float3 fullFrame = tex2D(TexBase, i.uv).rgb;
float3 worldOnly = tex2D(Texture1, i.uv).rgb;

// Detect viewmodels by comparing
float3 diff = abs(fullFrame - worldOnly);
float isViewmodel = step(0.05, (diff.r + diff.g + diff.b) / 3.0);
```

Note: This fails when viewmodel color is close to world color

## Creating New Shaders

Use [sdk_screenspace_shaders](https://github.com/ficool2/sdk_screenspace_shaders) for shader compilation.

**Basic process:**
1. Write `.hlsl` shader
2. Compile to `.vcs`
3. Create `.vmt` material file
4. Reference in HUD

## Limitations

### What Shaders CAN'T Do

**Temporal effects** - No frame history

**SSAO** - No geometry/normal data

**Reflections** - No environment data

### What Shaders CAN Do

**Color grading** - Sepia, contrast, saturation, tinting

**Blur/sharpen** - Spatial filtering

**Edge detection** - Cel shading, outlines

**Distortion** - Chromatic aberration, lens effects

**Procedural effects** - Rain, grain, noise

**Animated effects** - Using time parameter

**Vignettes** - Darkening edges

### What Shaders MIGHT be able to do

**Depth stuff** - Like fog, the depth buffer is exposed, have not tested it myself - edit: the depthbuffer sucks

**Velocity stuff** - Wonky motion blur using speed parameters from the hud?

### Performance Notes

- Pixel shaders run **every frame, every pixel**
- The instruction limit is low so be careful with loops
- Keep texture samples low (expensive)
- Avoid complex math (sqrt, pow, trig)

### Viewmodel Notes

**Problem:** When using `_rt_PowerOfTwoFB` or `_rt_FullFrameDepth`, first-person weapons become transparent or invisible.

**Why:** Alpha blending from the shader makes them see-through. Stuff like `$additive 1` might be able to fix this. (needs more testing, maybe [this](https://wiki.facepunch.com/gmod/Shaders/screenspace_general) might help?)

## Resources

**All credits go to:**
- **Shader Compilation:** [sdk_screenspace_shaders](https://github.com/ficool2/sdk_screenspace_shaders)

**Useful:**
- **HLSL Reference:** [Microsoft HLSL Docs](https://docs.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl)
- **Shader Inspiration:** [ShaderToy](https://www.shadertoy.com/)
