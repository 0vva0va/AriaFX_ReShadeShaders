/*
                            ▄▄▄▌                 ░▄▄▓▀▓▓▄              
     ▄▄▄         ▄  ▄▄     ▀███        ▄▄▄      ▀███  █▒▒▌ ▄▄         ▄
  ▄▓▓▀ ▀▓▓▄    ▄█▓█▀ ▀▓▓▄    ▀      ▄▓▓▀ ▀▓▓▄    ▓▓▓  ▀▄▀  ▀▓▓▓▄   ▄▓▓▓
 ▒▒▒▌   ▐▒▒▌   ▒▒▒▌   ▐▒▒▌ ▀▒▒▒▀   ▒▒▒▌   ▐▒▒▌   ▒▒▒▄▄       ▐▒▒▒ ▒▒▒▌ 
░░░░     ░░░   ░░░▌   █░░█  ░░░   ░░░░     ░░░   ░░░          ░░░░░░░  
▀░░░▌   ▐░░░   ░░░▌    ▀▀   ░░░   ▀░░░▌   ▐░░░   ░░░         ▐░░░▀░░░▌ 
 ▀▒▒▒   ▒▒▒▒   ▒▒▒▌         ▒▒▒▌   ▀▒▒▒   ▒▒▒▒   ▒▒▒▌        ▒▒▒▀ ▀▒▒▒ 
   ▀▀▓▄▓▀▓▓▓▄ ▄▓▓▓█▄       ▄▓▓▓▓▄    ▀▀▓▄▓▀▓▓▓▄ ▄▓▓▓▓▄     ▄▓▀▀     ▀▀▓
=======================================================================

AriaFX Colours for ReShade 

    Colour grading
    shader for ReShade

Author : https://github.com/0vva0va


Credits : 

Valve Dither is adapted from https://www.shadertoy.com/view/4dcSRXslide
which is adapted from page  49 of Alex Vlachos's
GDC2015 talk: "Advanced VR Rendering".
http://alex.vlachos.com/graphics/Alex_Vlachos_Advanced_VR_Rendering_GDC2015.pdf

Gran Turismo 7 Tonemapping operator adapted from
https://blog.selfshadow.com/publications/s2025-shading-course/pdi/supplemental/gt7_tone_mapping.cpp

*/


#include "AriaFX/AriaFX_Common.fxh"
#include "AriaFX/AriaFX_Tonemap.fxh"


// -------------------------------------------------------------------
// -------------------------------------------------------------------
// -------------------------------------------------------------------

//--- UNIFORM VARIABLES ---@/
//-------------------------@/

uniform bool _AdjustExposure < 
	ui_label    = "Exposure Toggle";
	ui_tooltip  = "Enable Exposure Adjustment";
    ui_category = "Exposure";
    ui_category_closed = true;
> = false; // --------------------------------//
uniform float _Exposure < __UNIFORM_SLIDER_FLOAT1
    ui_min = -1.0; ui_max = 1.0;
	ui_label    = "Exposure";
	ui_tooltip  = "Controls Exposure";
    ui_category = "Exposure";
    ui_category_closed = true;
> = 0.0;


uniform bool _AdjustContrast < 
	ui_label    = "Contrast Toggle";
	ui_tooltip  = "Enable Contrast Adjustment";
    ui_category = "Contrast";
    ui_category_closed = true;
> = false; // --------------------------------//
uniform float _Contrast < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0.0; ui_max = 2.0;
	ui_label    = "Contrast";
	ui_tooltip  = "Controls Contrast";
    ui_category = "Contrast";
    ui_category_closed = true;
> = 1.0;


uniform bool _AdjustSaturation < 
	ui_label    = "Saturation Toggle";
	ui_tooltip  = "Enable Saturation Adjustment";
    ui_category = "Saturation";
    ui_category_closed = true;
> = false; // --------------------------------//
uniform float _Saturation < __UNIFORM_SLIDER_FLOAT1
    ui_min = -1.0; ui_max = 1.0;
	ui_label    = "Exposure";
	ui_tooltip  = "Controls Saturation";
    ui_category = "Saturation";
    ui_category_closed = true;
> = 0.0;


// -- Temp and Tint -- /
uniform bool _AdjustWhiteBalanceAndTint < 
	ui_label    = "White Balance and Tint Toggle";
	ui_tooltip  = "Enable White Balance and Tint Adjustment";
    ui_category = "Colour Grading";
    ui_category_closed = true;
> = false; // --------------------------------//
uniform float _Temperature < __UNIFORM_SLIDER_FLOAT1
    ui_min = -1.0; ui_max = 1.0;
	ui_label    = "Temperature";
	ui_tooltip  = "Controls White Balance Temperature";
    ui_category = "Colour Grading";
    ui_category_closed = true;
> = 0.0; // --------------------------------//
uniform float _Tint < __UNIFORM_SLIDER_FLOAT1
    ui_min = -1.0; ui_max = 1.0;
	ui_label    = "Tint";
	ui_tooltip  = "Controls White Balance Tint";
    ui_category = "Colour Grading";
    ui_category_closed = true;
> = 0.0;


uniform bool _UseDither < 
	ui_label    = "Dither Toggle";
	ui_tooltip  = "Enable Dither";
    ui_category = "Dither";
    ui_category_closed = true;
> = false;


// -- Tonemapping -- /
uniform bool _UseTonemap < 
	ui_label    = "Tonemap Toggle";
	ui_tooltip  = "Enable Tonemap";
    ui_category = "Tonemap";
    ui_category_closed = true;
> = false; // --------------------------------//
uniform float _BlendRatio < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0.0; ui_max = 1.0;
	ui_label    = "Tonemap Blend Ratio";
    ui_category = "Tonemap";
    ui_category_closed = true;
> = 0.12; // --------------------------------//
uniform float _FadeStart < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0.0; ui_max = 2.0;
	ui_label    = "Tonemap Fade Start";
    ui_category = "Tonemap";
    ui_category_closed = true;
> = 0.8; // --------------------------------// 
uniform float _FadeEnd < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0.0; ui_max = 2.0;
	ui_label    = "Tonemap Fade End";
    ui_category = "Tonemap";
    ui_category_closed = true;
> = 1.2; // --------------------------------//
uniform float _WHITEPOINT < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0.0; ui_max = 500.0;
	ui_label    = "Tonemap White Point (SDR)";
    ui_category = "Tonemap";
    ui_category_closed = true;
> = 110.0;


// -- Shadows, Midtones & Highlights -- /
uniform bool _UseSMH < 
	ui_label    = "Enable Shadow, Midtones and Highlights Controls";
	ui_tooltip  = "Enable SMH";
    ui_category = "SMH";
    ui_category_closed = true;
> = false; // --------------------------------//
uniform float4 _TintS < __UNIFORM_COLOR_FLOAT4
    ui_min = 0.0; ui_max = 1.0;
	ui_label    = "Shadows Tint";
    ui_category = "SMH";
    ui_category_closed = true;
> = 0.0; // --------------------------------//
uniform float4 _TintM < __UNIFORM_COLOR_FLOAT4
    ui_min = 0.0; ui_max = 1.0;
	ui_label    = "Midtones Tint";
    ui_category = "SMH";
    ui_category_closed = true;
> = 0.0; // --------------------------------//
uniform float4 _TintH < __UNIFORM_COLOR_FLOAT4
    ui_min = 0.0; ui_max = 1.0;
	ui_label    = "Highlights Tint";
    ui_category = "SMH";
    ui_category_closed = true;
> = 0.0; // --------------------------------//
uniform float _ExpS < __UNIFORM_SLIDER_FLOAT1
    ui_min = -4.0; ui_max = 4.0;
	ui_label    = "Shadows Exposure";
    ui_category = "SMH";
    ui_category_closed = true;
> = 0.0; // --------------------------------//
uniform float _ExpM < __UNIFORM_SLIDER_FLOAT1
    ui_min = -4.0; ui_max = 4.0;
	ui_label    = "Midtones Exposure";
    ui_category = "SMH";
    ui_category_closed = true;
> = 0.0; // --------------------------------//
uniform float _ExpH < __UNIFORM_SLIDER_FLOAT1
    ui_min = -4.0; ui_max = 4.0;
	ui_label    = "Highlights Exposure";
    ui_category = "SMH";
    ui_category_closed = true;
> = 0.0; // --------------------------------//
uniform int _SMHMode < __UNIFORM_COMBO_INT1
	ui_label    = "Blending Mode";
    ui_items    = "Harsh Separation\0Smooth Separation\0";
    ui_category = "SMH";
    ui_category_closed = true;
> = 0;


// -------------------------------------------------------------------
// -------------------------------------------------------------------
// -------------------------------------------------------------------


sampler ColourLinearSampler { Texture = ReShade::BackBufferTex; SRGBTexture = true; };


//--- FUNCTIONS ---@/
//-----------------@/

float3 ValveDither(float2 pos) {
    float dotPos  = dot(float2(131.0, 312.0), pos.xy);
    float3 dither = float3(dotPos, dotPos, dotPos);
           dither = frac(dither / float3(103.0, 71.0, 97.0)) - float3(0.5, 0.5, 0.5);

    return (dither / 255.0) * 0.375;
}


float QuintSmoothstep(float x) {
    return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
}


float3 GetSMHWeights(float3 cin, int _SMHMode) {
    float weightS, weightM, weightH;

    float luma = Common::Luma(cin);

    if (_SMHMode == 0) {
        weightS = QuintSmoothstep(max(1.0 - luma * 2.0, 0.0));
        weightH = QuintSmoothstep(max((luma - 0.5) * 2.0, 0.0));
        weightM = saturate(1.0 - weightS - weightH);
        
    } 
    if (_SMHMode == 1) {
        weightS = pow(1.0 - luma, 4.0);
        weightH = pow(luma, 4.0);
        weightM = saturate(1.0 - weightS - weightH);
        
    }

    return float3(weightS, weightM, weightH);
}


//--- PASSES ---@/
//--------------@/

float4 ColoursPass(float4 position : SV_POSITION, float2 texcoord : TEXCOORD) : SV_TARGET {
    float3 colour = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float3 linearColour = tex2D(ColourLinearSampler, texcoord).rgb;


    if (_AdjustExposure)
        linearColour *= pow(2.0, _Exposure);


    if (_AdjustContrast) 
        linearColour = _Contrast * (linearColour - 0.18) + 0.18;
    

    if (_AdjustSaturation) {
        float maxColour = max(linearColour.r, max(linearColour.g, linearColour.b));
        float avgColour = (linearColour.r + linearColour.g + linearColour.b) / 3.0;

        float saturationAmount = maxColour - avgColour;

        float scale = _Saturation * (1.0 - saturationAmount);

        if (linearColour.r > linearColour.g && linearColour.r > linearColour.b) {
            float skinToneProtection = (linearColour.r - max(linearColour.g, linearColour.b)) / maxColour;
            scale *= (1.0 - skinToneProtection * 0.5);
        }
        linearColour = lerp(linearColour, float3(maxColour, maxColour, maxColour), -scale);
    }


    if (_AdjustWhiteBalanceAndTint) 
        linearColour = Common::WhiteBalance(linearColour, _Temperature, _Tint);
    

    if (_UseTonemap) {
        float2 initVars = TonemappingSDRInit(_WHITEPOINT);
        linearColour = mul(Common::REC709_TO_REC2020, linearColour);
        linearColour = ApplyTonemapping(linearColour, 
                 initVars.r, 
              initVars.g, 
                          _WHITEPOINT,  
                                 _BlendRatio, _FadeStart, _FadeEnd);
        linearColour = mul(Common::REC2020_TO_REC709, linearColour);
    }


    if (_UseSMH) {
        float3 weights = GetSMHWeights(linearColour, _SMHMode);
        // -- Exposures -- / 
        linearColour = Common::WeightedExposure(linearColour, _ExpS * weights.x);
        linearColour = Common::WeightedExposure(linearColour, _ExpM * weights.y);
        linearColour = Common::WeightedExposure(linearColour, _ExpH * weights.z);
        // -- Tints -- /
        linearColour = lerp(linearColour, _TintS.rgb, weights.x * _TintS.a);
        linearColour = lerp(linearColour, _TintM.rgb, weights.y * _TintM.a);
        linearColour = lerp(linearColour, _TintH.rgb, weights.z * _TintH.a);
    }


    // -- Final Colour Output -- /
    float3 outCol = Common::Linear2SRGB(linearColour);
    

    if (_UseDither) {
        float3 ditherColour = ValveDither(position.xy);
        float3 finalDither  = (ditherColour - 0.5) / 255.0;
        outCol += finalDither;

    }


    return saturate(float4(outCol, 1.0));
}


// -------------------------------------------------------------------
// -------------------------------------------------------------------
// -------------------------------------------------------------------


technique AriaFXColours < ui_label = "AriaFX: Colours"; ui_tooltip = "Colour Adjustment and Grading Shader"; > {
    pass {
        VertexShader = PostProcessVS;
        PixelShader  = ColoursPass;
    }
}