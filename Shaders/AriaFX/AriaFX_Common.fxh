#pragma once



namespace Common {   

	static const float3x3 CLIN_2_XYZ = float3x3(
		0.4124564,  0.3575761, 0.1804375,
		0.2126729,  0.7151522, 0.0721750,
		0.0193339,  0.1191920, 0.9503041
	);
	static const float3x3 XYZ_2_CLIN = float3x3(
		3.2404542,  -1.5371385, -0.4985314,
		-0.9692660, 1.8760108,  0.0415560,
		0.0556434,  -0.2040259, 1.0572252
	);

	static const float3x3 XYZ_2_LMS = float3x3(  // -- CAT02 
		0.7328,  0.4296, -0.1624, 
		-0.7036, 1.6975, 0.0061, 
		0.003,   0.0136, 0.9834
	);
	static const float3x3 LMS_2_XYZ = float3x3(  // -- Inverse CAT02
		1.09612382,  -0.278869 ,  0.18274518, 
		0.45436904,  0.47353315,  0.0720978, 
		-0.00962761, -0.00569803, 1.01532564
	);

	static const float3x3 REC709_TO_REC2020 = float3x3(
		0.6274, 0.3293, 0.0433,
		0.0691, 0.9195, 0.0113,
		0.0164, 0.0880, 0.8956
	);

	static const float3x3 REC2020_TO_REC709 = float3x3(
		1.6605,  -0.5876, -0.0728,
		-0.1246, 1.1329,  -0.0083,
		-0.0182, -0.1006,  1.1187
	);



	float Luma(float3 cin) {   // -- sRGB Luma 
        return max(0.00001f, dot(cin, float3(0.2127f, 0.7152f, 0.0722f)));
    }
	float Luminance(float3 cin) { // -- Linear space Luminance
        return max(0.00001f, dot(cin, float3(0.2127f, 0.7152f, 0.0722f)));
    }

	float3 WeightedExposure(float3 cin, float x) {
		x = x < 0.0 ? x * 0.333 : x;

    	return saturate(cin.rgb * (x * (1.0 - cin.rgb) + 1.0));
	}


	float3 WhiteBalance(float3 cin, float Temperature, float Tint)
	{
		float t1 = Temperature * 10 / 6;
		float t2 = Tint * 10 / 6;

		// Get the CIE xy chromaticity of the reference white point.
		// Note: 0.31271 = x value on the D65 white point
		float x = 0.31271 - t1 * (t1 < 0 ? 0.1 : 0.05);
		float standardIlluminantY = 2.87 * x - 3 * x * x - 0.27509507;
		float y = standardIlluminantY + t2 * 0.05;

		// Calculate the coefficients in the LMS space.
		float3 w1 = float3(0.949237, 1.03542, 1.08728); // D65 white point

		// CIExyToLMS
		float Y = 1;
		float X = Y * x / y;
		float Z = Y * (1 - x - y) / y;
		float L = 0.7328 * X + 0.4296 * Y - 0.1624 * Z;
		float M = -0.7036 * X + 1.6975 * Y + 0.0061 * Z;
		float S = 0.0030 * X + 0.0136 * Y + 0.9834 * Z;
		float3 w2 = float3(L, M, S);

		float3 balance = float3(w1.x / w2.x, w1.y / w2.y, w1.z / w2.z);

		//float3 lms = mul(LIN_2_LMS_MAT, In);
		float3 lms = mul(XYZ_2_LMS, mul(CLIN_2_XYZ,cin));
		lms *= balance;
		return mul(XYZ_2_CLIN, mul(LMS_2_XYZ, lms));
	}


	float3 SRGB2Linear(float3 cin) { 
		return pow(cin, 2.2);
	}
	float3 Linear2SRGB(float3 cin) { 
		return pow(cin, 0.4545);
	}

}



#if !defined(__RESHADE__) || __RESHADE__ < 30000
	#error "ReShade 3.0+ is required to use this header file"
#endif

#ifndef RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
	#define RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN 0
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_REVERSED
	#define RESHADE_DEPTH_INPUT_IS_REVERSED 1
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_MIRRORED
        #define RESHADE_DEPTH_INPUT_IS_MIRRORED 0
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
	#define RESHADE_DEPTH_INPUT_IS_LOGARITHMIC 0
#endif

#ifndef RESHADE_DEPTH_MULTIPLIER
	#define RESHADE_DEPTH_MULTIPLIER 1
#endif
#ifndef RESHADE_DEPTH_LINEARIZATION_FAR_PLANE
	#define RESHADE_DEPTH_LINEARIZATION_FAR_PLANE 1000.0
#endif

// Above 1 expands coordinates, below 1 contracts and 1 is equal to no scaling on any axis
#ifndef RESHADE_DEPTH_INPUT_Y_SCALE
	#define RESHADE_DEPTH_INPUT_Y_SCALE 1
#endif
#ifndef RESHADE_DEPTH_INPUT_X_SCALE
	#define RESHADE_DEPTH_INPUT_X_SCALE 1
#endif
// An offset to add to the Y coordinate, (+) = move up, (-) = move down
#ifndef RESHADE_DEPTH_INPUT_Y_OFFSET
	#define RESHADE_DEPTH_INPUT_Y_OFFSET 0
#endif
#ifndef RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET
	#define RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET 0
#endif
// An offset to add to the X coordinate, (+) = move right, (-) = move left
#ifndef RESHADE_DEPTH_INPUT_X_OFFSET
	#define RESHADE_DEPTH_INPUT_X_OFFSET 0
#endif
#ifndef RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET
	#define RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET 0
#endif

#define BUFFER_PIXEL_SIZE float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
#define BUFFER_SCREEN_SIZE float2(BUFFER_WIDTH, BUFFER_HEIGHT)
#define BUFFER_ASPECT_RATIO (BUFFER_WIDTH * BUFFER_RCP_HEIGHT)

namespace ReShade
{
#if defined(__RESHADE_FXC__)
	float GetAspectRatio() { return BUFFER_WIDTH * BUFFER_RCP_HEIGHT; }
	float2 GetPixelSize() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
	float2 GetScreenSize() { return float2(BUFFER_WIDTH, BUFFER_HEIGHT); }
	#define AspectRatio GetAspectRatio()
	#define PixelSize GetPixelSize()
	#define ScreenSize GetScreenSize()
#else
	// These are deprecated and will be removed eventually.
	static const float AspectRatio = BUFFER_WIDTH * BUFFER_RCP_HEIGHT;
	static const float2 PixelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	static const float2 ScreenSize = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
#endif

	// Global textures and samplers
	texture BackBufferTex : COLOR;
	texture DepthBufferTex : DEPTH;

	sampler BackBuffer { Texture = BackBufferTex; };
	sampler DepthBuffer { Texture = DepthBufferTex; };

	// Helper functions
	float GetLinearizedDepth(float2 texcoord)
	{
#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
		texcoord.y = 1.0 - texcoord.y;
#endif
#if RESHADE_DEPTH_INPUT_IS_MIRRORED
                texcoord.x = 1.0 - texcoord.x;
#endif
		texcoord.x /= RESHADE_DEPTH_INPUT_X_SCALE;
		texcoord.y /= RESHADE_DEPTH_INPUT_Y_SCALE;
#if RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET
		texcoord.x -= RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET * BUFFER_RCP_WIDTH;
#else // Do not check RESHADE_DEPTH_INPUT_X_OFFSET, since it may be a decimal number, which the preprocessor cannot handle
		texcoord.x -= RESHADE_DEPTH_INPUT_X_OFFSET / 2.000000001;
#endif
#if RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET
		texcoord.y += RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET * BUFFER_RCP_HEIGHT;
#else
		texcoord.y += RESHADE_DEPTH_INPUT_Y_OFFSET / 2.000000001;
#endif
		float depth = tex2Dlod(DepthBuffer, float4(texcoord, 0, 0)).x * RESHADE_DEPTH_MULTIPLIER;

#if RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
		const float C = 0.01;
		depth = (exp(depth * log(C + 1.0)) - 1.0) / C;
#endif
#if RESHADE_DEPTH_INPUT_IS_REVERSED
		depth = 1.0 - depth;
#endif
		const float N = 1.0;
		depth /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - depth * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - N);

		return depth;
	}

	float3 GetScreenSpaceNormal(float2 texcoord) {
		float3 offset    = float3(BUFFER_PIXEL_SIZE, 0.0);
		float2 posCenter = texcoord.xy;
		float2 posNorth  = posCenter - offset.zy;
		float2 posEast   = posCenter + offset.xz;

		float3 vertCenter = float3(posCenter - 0.5, 1) * GetLinearizedDepth(posCenter);
		float3 vertNorth  = float3(posNorth - 0.5,  1) * GetLinearizedDepth(posNorth);
		float3 vertEast   = float3(posEast - 0.5,   1) * GetLinearizedDepth(posEast);

		return normalize(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5;
	}
}


void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}


#define RESHADE_VERSION(major,minor,build) (10000 * (major) + 100 * (minor) + (build))
#define SUPPORTED_VERSION(major,minor,build) (__RESHADE__ >= RESHADE_VERSION(major,minor,build))

// >= 3.0.0
// Commit current in-game user interface status
// https://github.com/crosire/reshade/commit/302bacc49ae394faedc2e29a296c1cebf6da6bb2#diff-82cf230afdb2a0d5174111e6f17548a5R1183
// Added various GUI related uniform variable annotations
// https://reshade.me/forum/releases/2341-3-0
#define __UNIFORM_INPUT_ANY    ui_type = "input";

#define __UNIFORM_INPUT_BOOL1  __UNIFORM_INPUT_ANY
#define __UNIFORM_INPUT_BOOL2  __UNIFORM_INPUT_ANY
#define __UNIFORM_INPUT_BOOL3  __UNIFORM_INPUT_ANY
#define __UNIFORM_INPUT_BOOL4  __UNIFORM_INPUT_ANY
#define __UNIFORM_INPUT_INT1   __UNIFORM_INPUT_ANY
#define __UNIFORM_INPUT_INT2   __UNIFORM_INPUT_ANY
#define __UNIFORM_INPUT_INT3   __UNIFORM_INPUT_ANY
#define __UNIFORM_INPUT_INT4   __UNIFORM_INPUT_ANY
#define __UNIFORM_INPUT_FLOAT1 __UNIFORM_INPUT_ANY
#define __UNIFORM_INPUT_FLOAT2 __UNIFORM_INPUT_ANY
#define __UNIFORM_INPUT_FLOAT3 __UNIFORM_INPUT_ANY
#define __UNIFORM_INPUT_FLOAT4 __UNIFORM_INPUT_ANY

// >= 4.0.1
// Change slider widget to be used with new "slider" instead of a "drag" type annotation
// https://github.com/crosire/reshade/commit/746229f31cd6f311a3e72a543e4f1f23faa23f11#diff-59405a313bd8cbfb0ca6dd633230e504R1701
// Changed slider widget to be used with < ui_type = "slider"; > instead of < ui_type = "drag"; >
// https://reshade.me/forum/releases/4772-4-0
#if SUPPORTED_VERSION(4,0,1)
#define __UNIFORM_DRAG_ANY    ui_type = "drag";

// >= 4.0.0
// Rework statistics tab and add drag widgets back
// https://github.com/crosire/reshade/commit/1b2c38795f00efd66c007da1f483f1441b230309
// Changed drag widget to a slider widget (old one is still available via < ui_type = "drag2"; >)
// https://reshade.me/forum/releases/4772-4-0
#elif SUPPORTED_VERSION(4,0,0)
#define __UNIFORM_DRAG_ANY    ui_type = "drag2";

// >= 3.0.0
// Commit current in-game user interface status
// https://github.com/crosire/reshade/commit/302bacc49ae394faedc2e29a296c1cebf6da6bb2#diff-82cf230afdb2a0d5174111e6f17548a5R1187
// Added various GUI related uniform variable annotations
// https://reshade.me/forum/releases/2341-3-0
#else
#define __UNIFORM_DRAG_ANY    ui_type = "drag";
#endif

#define __UNIFORM_DRAG_BOOL1  __UNIFORM_DRAG_ANY
#define __UNIFORM_DRAG_BOOL2  __UNIFORM_DRAG_ANY
#define __UNIFORM_DRAG_BOOL3  __UNIFORM_DRAG_ANY
#define __UNIFORM_DRAG_BOOL4  __UNIFORM_DRAG_ANY
#define __UNIFORM_DRAG_INT1   __UNIFORM_DRAG_ANY
#define __UNIFORM_DRAG_INT2   __UNIFORM_DRAG_ANY
#define __UNIFORM_DRAG_INT3   __UNIFORM_DRAG_ANY
#define __UNIFORM_DRAG_INT4   __UNIFORM_DRAG_ANY
#define __UNIFORM_DRAG_FLOAT1 __UNIFORM_DRAG_ANY
#define __UNIFORM_DRAG_FLOAT2 __UNIFORM_DRAG_ANY
#define __UNIFORM_DRAG_FLOAT3 __UNIFORM_DRAG_ANY
#define __UNIFORM_DRAG_FLOAT4 __UNIFORM_DRAG_ANY

// >= 4.0.1
// Change slider widget to be used with new "slider" instead of a "drag" type annotation
// https://github.com/crosire/reshade/commit/746229f31cd6f311a3e72a543e4f1f23faa23f11#diff-59405a313bd8cbfb0ca6dd633230e504R1699
// Changed slider widget to be used with < ui_type = "slider"; > instead of < ui_type = "drag"; >
// https://reshade.me/forum/releases/4772-4-0
#if SUPPORTED_VERSION(4,0,1)
#define __UNIFORM_SLIDER_ANY    ui_type = "slider";

// >= 4.0.0
// Rework statistics tab and add drag widgets back
// https://github.com/crosire/reshade/commit/1b2c38795f00efd66c007da1f483f1441b230309
// Changed drag widget to a slider widget (old one is still available via < ui_type = "drag2"; >)
// https://reshade.me/forum/releases/4772-4-0
#elif SUPPORTED_VERSION(4,0,0)
#define __UNIFORM_SLIDER_ANY    ui_type = "drag";
#else
#define __UNIFORM_SLIDER_ANY    __UNIFORM_DRAG_ANY
#endif

#define __UNIFORM_SLIDER_BOOL1  __UNIFORM_SLIDER_ANY
#define __UNIFORM_SLIDER_BOOL2  __UNIFORM_SLIDER_ANY
#define __UNIFORM_SLIDER_BOOL3  __UNIFORM_SLIDER_ANY
#define __UNIFORM_SLIDER_BOOL4  __UNIFORM_SLIDER_ANY
#define __UNIFORM_SLIDER_INT1   __UNIFORM_SLIDER_ANY
#define __UNIFORM_SLIDER_INT2   __UNIFORM_SLIDER_ANY
#define __UNIFORM_SLIDER_INT3   __UNIFORM_SLIDER_ANY
#define __UNIFORM_SLIDER_INT4   __UNIFORM_SLIDER_ANY
#define __UNIFORM_SLIDER_FLOAT1 __UNIFORM_SLIDER_ANY
#define __UNIFORM_SLIDER_FLOAT2 __UNIFORM_SLIDER_ANY
#define __UNIFORM_SLIDER_FLOAT3 __UNIFORM_SLIDER_ANY
#define __UNIFORM_SLIDER_FLOAT4 __UNIFORM_SLIDER_ANY

// >= 3.0.0
// Add combo box display type for uniform variables and fix displaying of integer variable under Direct3D 9
// https://github.com/crosire/reshade/commit/b025bfae5f7343509ec0cacf6df0cff537c499f2#diff-82cf230afdb2a0d5174111e6f17548a5R1631
// Added various GUI related uniform variable annotations
// https://reshade.me/forum/releases/2341-3-0
#define __UNIFORM_COMBO_ANY    ui_type = "combo";

//      __UNIFORM_COMBO_BOOL1
#define __UNIFORM_COMBO_BOOL2  __UNIFORM_COMBO_ANY
#define __UNIFORM_COMBO_BOOL3  __UNIFORM_COMBO_ANY
#define __UNIFORM_COMBO_BOOL4  __UNIFORM_COMBO_ANY
#define __UNIFORM_COMBO_INT1   __UNIFORM_COMBO_ANY
#define __UNIFORM_COMBO_INT2   __UNIFORM_COMBO_ANY
#define __UNIFORM_COMBO_INT3   __UNIFORM_COMBO_ANY
#define __UNIFORM_COMBO_INT4   __UNIFORM_COMBO_ANY
#define __UNIFORM_COMBO_FLOAT1 __UNIFORM_COMBO_ANY
#define __UNIFORM_COMBO_FLOAT2 __UNIFORM_COMBO_ANY
#define __UNIFORM_COMBO_FLOAT3 __UNIFORM_COMBO_ANY
#define __UNIFORM_COMBO_FLOAT4 __UNIFORM_COMBO_ANY

// >= 4.0.0
// Add option to display boolean values as combo box instead of checkbox
// https://github.com/crosire/reshade/commit/aecb757c864c9679e77edd6f85a1521c49e489c1#diff-59405a313bd8cbfb0ca6dd633230e504R1147
// https://github.com/crosire/reshade/blob/v4.0.0/source/gui.cpp
// Added option to display boolean values as combo box instead of checkbox (via < ui_type = "combo"; >)
// https://reshade.me/forum/releases/4772-4-0
#define __UNIFORM_COMBO_BOOL1  __UNIFORM_COMBO_ANY

// >= 4.0.0
// Cleanup GUI code and rearrange some widgets
// https://github.com/crosire/reshade/commit/6751f7bd50ea7c0556cf0670f10a4b4ba912ee7d#diff-59405a313bd8cbfb0ca6dd633230e504R1711
// Added radio button widget (via < ui_type = "radio"; ui_items = "Button 1\0Button 2\0...\0"; >)
// https://reshade.me/forum/releases/4772-4-0
#if SUPPORTED_VERSION(4,0,0)
#define __UNIFORM_RADIO_ANY    ui_type = "radio";
#else
#define __UNIFORM_RADIO_ANY    __UNIFORM_COMBO_ANY
#endif

#define __UNIFORM_RADIO_BOOL1  __UNIFORM_RADIO_ANY
#define __UNIFORM_RADIO_BOOL2  __UNIFORM_RADIO_ANY
#define __UNIFORM_RADIO_BOOL3  __UNIFORM_RADIO_ANY
#define __UNIFORM_RADIO_BOOL4  __UNIFORM_RADIO_ANY
#define __UNIFORM_RADIO_INT1   __UNIFORM_RADIO_ANY
#define __UNIFORM_RADIO_INT2   __UNIFORM_RADIO_ANY
#define __UNIFORM_RADIO_INT3   __UNIFORM_RADIO_ANY
#define __UNIFORM_RADIO_INT4   __UNIFORM_RADIO_ANY
#define __UNIFORM_RADIO_FLOAT1 __UNIFORM_RADIO_ANY
#define __UNIFORM_RADIO_FLOAT2 __UNIFORM_RADIO_ANY
#define __UNIFORM_RADIO_FLOAT3 __UNIFORM_RADIO_ANY
#define __UNIFORM_RADIO_FLOAT4 __UNIFORM_RADIO_ANY

// >= 4.1.0
// Fix floating point uniforms with unknown "ui_type" not showing up in UI
// https://github.com/crosire/reshade/commit/50e5bf44dfc84bc4220c2b9f19d5f50c7a0fda66#diff-59405a313bd8cbfb0ca6dd633230e504R1788
// Fixed floating point uniforms with unknown "ui_type" not showing up in UI
// https://reshade.me/forum/releases/5021-4-1
#define __UNIFORM_COLOR_ANY    ui_type = "color";

// >= 3.0.0
// Move technique list to preset configuration file
// https://github.com/crosire/reshade/blob/84bba3aa934c1ebe4c6419b69dfe1690d9ab9d34/source/runtime.cpp#L1328
// Added various GUI related uniform variable annotations
// https://reshade.me/forum/releases/2341-3-0

#define __UNIFORM_COLOR_BOOL1  __UNIFORM_COLOR_ANY
#define __UNIFORM_COLOR_BOOL2  __UNIFORM_COLOR_ANY
#define __UNIFORM_COLOR_BOOL3  __UNIFORM_COLOR_ANY
#define __UNIFORM_COLOR_BOOL4  __UNIFORM_COLOR_ANY
#define __UNIFORM_COLOR_INT1   __UNIFORM_COLOR_ANY
#define __UNIFORM_COLOR_INT2   __UNIFORM_COLOR_ANY
#define __UNIFORM_COLOR_INT3   __UNIFORM_COLOR_ANY
#define __UNIFORM_COLOR_INT4   __UNIFORM_COLOR_ANY
//      __UNIFORM_COLOR_FLOAT1
#define __UNIFORM_COLOR_FLOAT2 __UNIFORM_COLOR_ANY
#define __UNIFORM_COLOR_FLOAT3 __UNIFORM_COLOR_ANY
#define __UNIFORM_COLOR_FLOAT4 __UNIFORM_COLOR_ANY

// >= 4.2.0
// Add alpha slider widget for single component uniform variables (#86)
// https://github.com/crosire/reshade/commit/87a740a8e3c4dcda1dd4eeec8d5cff7fa35fe829#diff-59405a313bd8cbfb0ca6dd633230e504R1820
// Added alpha slider widget for single component uniform variables
// https://reshade.me/forum/releases/5150-4-2
#if SUPPORTED_VERSION(4,2,0)
#define __UNIFORM_COLOR_FLOAT1 __UNIFORM_COLOR_ANY
#else
#define __UNIFORM_COLOR_FLOAT1 __UNIFORM_SLIDER_ANY
#endif

// >= 4.3.0
// Add new "list" GUI widget (#103)
// https://github.com/crosire/reshade/commit/515287d20ce615c19cf3d4c21b49f83896f04ddc#diff-59405a313bd8cbfb0ca6dd633230e504R1894
// Added new "list" GUI widget
// https://reshade.me/forum/releases/5417-4-3
#if SUPPORTED_VERSION(4,3,0)
#define __UNIFORM_LIST_ANY    ui_type = "list";
#else
#define __UNIFORM_LIST_ANY    __UNIFORM_COMBO_ANY
#endif

//      __UNIFORM_LIST_BOOL1
#define __UNIFORM_LIST_BOOL2  __UNIFORM_LIST_ANY
#define __UNIFORM_LIST_BOOL3  __UNIFORM_LIST_ANY
#define __UNIFORM_LIST_BOOL4  __UNIFORM_LIST_ANY
#define __UNIFORM_LIST_INT1   __UNIFORM_LIST_ANY // >= 4.3.0
#define __UNIFORM_LIST_INT2   __UNIFORM_LIST_ANY
#define __UNIFORM_LIST_INT3   __UNIFORM_LIST_ANY
#define __UNIFORM_LIST_INT4   __UNIFORM_LIST_ANY
#define __UNIFORM_LIST_FLOAT1 __UNIFORM_LIST_ANY
#define __UNIFORM_LIST_FLOAT2 __UNIFORM_LIST_ANY
#define __UNIFORM_LIST_FLOAT3 __UNIFORM_LIST_ANY
#define __UNIFORM_LIST_FLOAT4 __UNIFORM_LIST_ANY

// For compatible with 'combo'
#define __UNIFORM_LIST_BOOL1  __UNIFORM_COMBO_ANY