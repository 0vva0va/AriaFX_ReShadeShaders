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

Standard SMAA for ReShade 


Author : https://github.com/0vva0va


Credits : 

https://github.com/CeeJayDK/SweetFX/blob/master/Shaders/SweetFX/SMAA.fxh

*/


#include "AriaFX/AriaFX_Common.fxh"


#if !defined(SMAA_PRESET_LOW) && !defined(SMAA_PRESET_MEDIUM) && !defined(SMAA_PRESET_HIGH) && !defined(SMAA_PRESET_ULTRA)
#define SMAA_PRESET_CUSTOM 
#endif


// -------------------------------------------------------------------
// -------------------------------------------------------------------
// -------------------------------------------------------------------

//--- UNIFORM VARIABLES ---@/
//-------------------------@/

uniform int _EdgeDetectionType < __UNIFORM_COMBO_INT1
    ui_category = "SMAA Settings";
    ui_category_closed = true;
	ui_items = "Luminance edge detection\0colour edge detection\0Both, biasing Clarity\0Both, biasing Anti-Aliasing\0";
	ui_label = "Edge Detection Type";
> = 3;

#ifdef SMAA_PRESET_CUSTOM
uniform float _EdgeDetectionThreshold < __UNIFORM_DRAG_FLOAT1
    ui_category = "SMAA Settings";
    ui_category_closed = true;
	ui_min = 0.05; ui_max = 0.2; ui_step = 0.001;
	ui_label = "Edge Detection Threshold";
> = 0.0625;

uniform int _MaxSearchSteps < __UNIFORM_SLIDER_INT1
    ui_category = "SMAA Settings";
    ui_category_closed = true;
	ui_min = 1; ui_max = 112;
	ui_label   = "Max Search Steps";
	ui_tooltip = "Determines the radius SMAA will search for aliased edges";
> = 112;

uniform int _MaxSearchStepsDiagonal < __UNIFORM_SLIDER_INT1
    ui_category = "SMAA Settings";
    ui_category_closed = true;
	ui_min = 1; ui_max = 20;
	ui_label   = "Max Search Steps Diagonal";
	ui_tooltip = "Determines the radius SMAA will search for diagonal aliased edges";
> = 20;

uniform int _CornerRounding < __UNIFORM_SLIDER_INT1
    ui_category = "SMAA Settings";
    ui_category_closed = true;
	ui_min = 0; ui_max = 100;
	ui_label   = "Corner Rounding";
	ui_tooltip = "Determines the percent of anti-aliasing to apply to corners";
> = 10;

uniform float _ContrastAdaptationFactor < __UNIFORM_DRAG_FLOAT1
    ui_category = "SMAA Settings";
    ui_category_closed = true;
	ui_min = 1.0; ui_max = 8.0; ui_step = 0.01;
	ui_label   = "Local Contrast Adaptation Factor";
	ui_tooltip = "Low values preserve detail, high values increase anti-aliasing effect";
> = 1.60;

uniform bool _PredicationEnabled < __UNIFORM_INPUT_BOOL1
    ui_category = "SMAA Settings";
    ui_category_closed = true;
	ui_label = "Enable Predicated Thresholding";
> = false;

uniform float _PredicationThreshold < __UNIFORM_DRAG_FLOAT1
    ui_category = "SMAA Settings";
    ui_category_closed = true;
	ui_min = 0.005; ui_max = 1.00; ui_step = 0.01;
	ui_tooltip = "Threshold to be used in the additional predication buffer.";
	ui_label   = "Predication Threshold";
> = 0.01;

uniform float _PredicationScale < __UNIFORM_SLIDER_FLOAT1
    ui_category = "SMAA Settings";
    ui_category_closed = true;
	ui_min = 1; ui_max = 8;
	ui_tooltip = "How much to scale the global threshold used for luma or colour edge.";
	ui_label   = "Predication Scale";
> = 2.0;

uniform float _PredicationStrength < __UNIFORM_SLIDER_FLOAT1
    ui_category = "SMAA Settings";
    ui_category_closed = true;
	ui_min = 0; ui_max = 4;
	ui_tooltip = "How much to locally decrease the threshold.";
	ui_label   = "Predication Strength";
> = 0.4;
#endif

uniform int _DebugOutput < __UNIFORM_COMBO_INT1
	ui_items = "None\0View edges\0View weights\0";
	ui_label = "Debug Output";
> = false;



//--- SMAA DEFINES ---@/
//--------------------@/

#ifdef SMAA_PRESET_CUSTOM
	#define SMAA_THRESHOLD             _EdgeDetectionThreshold
	#define SMAA_MAX_SEARCH_STEPS      _MaxSearchSteps
	#define SMAA_MAX_SEARCH_STEPS_DIAG _MaxSearchStepsDiagonal
	#define SMAA_CORNER_ROUNDING       _CornerRounding
	#define SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR _ContrastAdaptationFactor
	#define SMAA_PREDICATION           _PredicationEnabled
	#define SMAA_PREDICATION_THRESHOLD _PredicationThreshold
	#define SMAA_PREDICATION_SCALE     _PredicationScale
	#define SMAA_PREDICATION_STRENGTH  _PredicationStrength
#endif

#define SMAA_RT_METRICS float4(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT, BUFFER_WIDTH, BUFFER_HEIGHT)
#define SMAA_CUSTOM_SL 1

#define SMAATexture2D(tex) sampler tex
#define SMAATexturePass2D(tex) tex
#define SMAASampleLevelZero(tex, coord) tex2Dlod(tex, float4(coord, coord))
#define SMAASampleLevelZeroPoint(tex, coord) SMAASampleLevelZero(tex, coord)
#define SMAASampleLevelZeroOffset(tex, coord, offset) tex2Dlodoffset(tex, float4(coord, coord), offset)
#define SMAASample(tex, coord) tex2D(tex, coord)
#define SMAASamplePoint(tex, coord) SMAASample(tex, coord)
#define SMAASampleOffset(tex, coord, offset) tex2Doffset(tex, coord, offset)
#define SMAA_BRANCH  [branch]
#define SMAA_FLATTEN [flatten]

#if (__RENDERER__ == 0xb000 || __RENDERER__ == 0xb100)
	#define SMAAGather(tex, coord) tex2Dgather(tex, coord, 0)
#endif


// -------------------------------------------------------------------
// -------------------------------------------------------------------
// -------------------------------------------------------------------

#include "AriaFX/SMAA.fxh"

//--- TEXTURES ---@/
//----------------@/

texture edgesTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG8; };
texture blendTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
texture depthTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16F; };

texture areaTex   < source = "AreaTex.png"; >   { Width = 160; Height = 560; Format = RG8; };
texture searchTex < source = "SearchTex.png"; > { Width = 64; Height = 16; Format = R8; };

sampler depthLinearSampler  { Texture = depthTex; };
sampler colourGammaSampler  { Texture = ReShade::BackBufferTex; AddressU = Clamp; AddressV = Clamp; MipFilter = Point; MinFilter = Linear; MagFilter = Linear; SRGBTexture = false; };
sampler colourLinearSampler { Texture = ReShade::BackBufferTex; AddressU = Clamp; AddressV = Clamp; MipFilter = Point; MinFilter = Linear; MagFilter = Linear; SRGBTexture = true; };
sampler edgesSampler        { Texture = edgesTex; AddressU = Clamp; AddressV = Clamp; MipFilter = Linear; MinFilter = Linear; MagFilter = Linear; SRGBTexture = false; };
sampler blendSampler        { Texture = blendTex; AddressU = Clamp; AddressV = Clamp; MipFilter = Linear; MinFilter = Linear; MagFilter = Linear; SRGBTexture = false; };
sampler areaSampler         { Texture = areaTex; AddressU = Clamp; AddressV = Clamp; AddressW = Clamp; MipFilter = Linear; MinFilter = Linear; MagFilter = Linear; SRGBTexture = false; };
sampler searchSampler       { Texture = searchTex; AddressU = Clamp; AddressV = Clamp; AddressW = Clamp; MipFilter = Point; MinFilter = Point; MagFilter = Point; SRGBTexture = false; };



// -------------------------------------------------------------------
// -------------------------------------------------------------------
// -------------------------------------------------------------------

//--- VERTEX ---@/
//--------------@/

void SMAAEdgeDetectionWrapVS(in uint id : SV_VertexID, out float4 position : SV_POSITION, out float2 texcoord : TEXCOORD0, out float4 offset[3] : TEXCOORD1) {
	PostProcessVS(id, position, texcoord);
	SMAAEdgeDetectionVS(texcoord, offset);
}


void SMAABlendingWeightCalculationWrapVS(in uint id : SV_VertexID, out float4 position : SV_POSITION, 
                                         out float2 texcoord : TEXCOORD0, out float2 pixcoord : TEXCOORD1, out float4 offset[3] : TEXCOORD2) {
	PostProcessVS(id, position, texcoord);
	SMAABlendingWeightCalculationVS(texcoord, pixcoord, offset);
}


void SMAANeighborhoodBlendingWrapVS(in uint id : SV_VertexID, out float4 position : SV_POSITION, out float2 texcoord : TEXCOORD0, out float4 offset : TEXCOORD1) {
	PostProcessVS(id, position, texcoord);
	SMAANeighborhoodBlendingVS(texcoord, offset);
}


//--- PIXEL ---@/
//-------------@/

float SMAADepthLinearizationPS(float4 position : SV_POSITION, float2 texcoord : TEXCOORD) : SV_TARGET {
	return ReShade::GetLinearizedDepth(texcoord);
}


float2 SMAAEdgeDetectionWrapPS(float4 position : SV_POSITION, float2 texcoord : TEXCOORD0, float4 offset[3] : TEXCOORD1) : SV_TARGET {
	if (SMAA_PREDICATION) {
		if (_EdgeDetectionType == 0) 
			return SMAALumaEdgePredicationDetectionPS(texcoord, offset, colourGammaSampler, depthLinearSampler);

		else if (_EdgeDetectionType == 1) 
			return SMAAColorEdgePredicationDetectionPS(texcoord, offset, colourGammaSampler, depthLinearSampler);

		else if (_EdgeDetectionType == 2) 
			return (SMAAColorEdgePredicationDetectionPS(texcoord, offset, colourGammaSampler, depthLinearSampler) 
				 && SMAALumaEdgePredicationDetectionPS(texcoord, offset, colourGammaSampler, depthLinearSampler)); 
		else                             
			return ((SMAALumaEdgePredicationDetectionPS(texcoord, offset, colourGammaSampler, depthLinearSampler) 
				   + SMAAColorEdgePredicationDetectionPS(texcoord, offset, colourGammaSampler, depthLinearSampler)) / 2);
	}

	if (_EdgeDetectionType == 0) 
		return SMAALumaEdgeDetectionPS(texcoord, offset, colourGammaSampler);

	else if (_EdgeDetectionType == 1) 
		return SMAAColorEdgeDetectionPS(texcoord, offset, colourGammaSampler);

	else if (_EdgeDetectionType == 2) 
		return (SMAAColorEdgeDetectionPS(texcoord, offset, colourGammaSampler) 
		     && SMAALumaEdgeDetectionPS(texcoord, offset, colourGammaSampler));

	else                             
		return ((SMAALumaEdgeDetectionPS(texcoord, offset, colourGammaSampler) 
		       + SMAAColorEdgeDetectionPS(texcoord, offset, colourGammaSampler)) / 2);
}


float4 SMAABlendingWeightCalculationWrapPS(float4 position : SV_POSITION, 
										   float2 texcoord : TEXCOORD0, float2 pixcoord : TEXCOORD1, float4 offset[3] : TEXCOORD2) : SV_TARGET {
	return SMAABlendingWeightCalculationPS(texcoord, pixcoord, offset, edgesSampler, areaSampler, searchSampler, 0.0);
}


float3 SMAANeighborhoodBlendingWrapPS(float4 position : SV_POSITION, float2 texcoord : TEXCOORD0, float4 offset : TEXCOORD1) : SV_TARGET {
	if (_DebugOutput == 1) return tex2D(edgesSampler, texcoord).rgb;
	if (_DebugOutput == 2) return tex2D(blendSampler, texcoord).rgb;

	return SMAANeighborhoodBlendingPS(texcoord, offset, colourLinearSampler, blendSampler).rgb;
}


//**************************************************//
//                  TECHNIQUES                      //
//**************************************************//

technique AriaFXSMAA < 
    ui_label   = "AriaFX: SMAA";
    ui_tooltip = "Standard SMAA Anti Aliasing Solution";
>
{
#if SMAA_PREDICATION
	pass LinearizeDepthPass {
		VertexShader = PostProcessVS;
		PixelShader  = SMAADepthLinearizationPS;
		RenderTarget = depthTex;
	}
#endif

	pass EdgeDetectionPass {
		VertexShader = SMAAEdgeDetectionWrapVS;
		PixelShader  = SMAAEdgeDetectionWrapPS;
		RenderTarget = edgesTex;
		ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass   = REPLACE;
		StencilRef    = 1;
	}

	pass BlendWeightCalculationPass	{
		VertexShader = SMAABlendingWeightCalculationWrapVS;
		PixelShader  = SMAABlendingWeightCalculationWrapPS;
		RenderTarget = blendTex;
		ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass   = KEEP;
		StencilFunc   = EQUAL;
		StencilRef    = 1;
	}

	pass NeighborhoodBlendingPass {
		VertexShader    = SMAANeighborhoodBlendingWrapVS;
		PixelShader     = SMAANeighborhoodBlendingWrapPS;
		StencilEnable   = false;
		SRGBWriteEnable = true;
	}
}
