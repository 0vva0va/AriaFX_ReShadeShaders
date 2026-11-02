// ARIA FX GT7 TONEMAPPER 
// https://blog.selfshadow.com/publications/s2025-shading-course/pdi/supplemental/gt7_tone_mapping.cpp


// Sample implementation of the GT7 Tone Mapping operator.
//
// Version history:
// 1.0    (2025-08-10)    Initial release.
//
// -----
// MIT License
//
// Copyright (c) 2025 Polyphony Digital Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.




#define REFERENCE_LUMINANCE 100.0f // cd/m^2 <-> 1.0f



float frameBufferValueToPhysicalValue(float fbValue) {
    return fbValue * REFERENCE_LUMINANCE;
}

float physicalValueToFrameBufferValue(float physical) {
    return physical / REFERENCE_LUMINANCE;
}


float smoothStep(float x, float edge0, float edge1) {
    float t = (x - edge0) / (edge1 - edge0);

    if (x < edge0) return 0.0;
    if (x > edge1) return 1.0;

    return t * t * (3.0 - 2.0 * t);
}

float chromaCurve(float x, float a, float b) {
    return 1.0 - smoothStep(x, a, b);
}



float evaluateCurve(float x, float monitorIntensity, float alpha, float grayPoint, float linearSection, float toeStrength) {
    float k = (linearSection - 1.0) / (alpha - 1.0);
    float kA = monitorIntensity * linearSection + monitorIntensity * k;
    float kB = -monitorIntensity * k * exp(linearSection / k); 
    float kC = -1.0f / (k * monitorIntensity);

    if (x < 0.0f) return 0.0f;
        
    float weightLinear = smoothStep(x, 0.0f, grayPoint);
    float weightToe    = 1.0 - weightLinear;


    float shoulder = kA + kB * exp(x * kC);

    if (x < linearSection * monitorIntensity) {
        float toeMapped = grayPoint * pow(x / grayPoint, toeStrength);
        return weightToe * toeMapped + weightLinear * x;
    }
    else {
        return shoulder;
    }
}


// -----------------------------------------------------------------------------
// EOTF / inverse-EOTF for ST-2084 (PQ).
// Note: Introduce exponentScaleFactor to allow scaling of the exponent in the EOTF for Jzazbz.
// -----------------------------------------------------------------------------
float eotfSt2084(float n, float exponentScaleFactor = 1.0f) {
    if (n < 0.0) n = 0.0;
    if (n > 1.0) n = 1.0;
    

    const float m1  = 0.1593017578125;               
    const float m2  = 78.84375 * exponentScaleFactor; 
    const float c1  = 0.8359375;                      
    const float c2  = 18.8515625;                     
    const float c3  = 18.6875;                     
    const float pqC = 10000.0;                       


    float np = pow(n, 1.0 / m2);
    float l  = np - c1;

    if (l < 0.0f) l = 0.0;
    
    l = l / (c2 - c3 * np);
    l = pow(l, 1.0 / m1);

    return physicalValueToFrameBufferValue(l * pqC);
}

float inverseEotfSt2084(float v, float exponentScaleFactor = 1.0) {
    const float m1  = 0.1593017578125;
    const float m2  = 78.84375 * exponentScaleFactor;
    const float c1  = 0.8359375;
    const float c2  = 18.8515625;
    const float c3  = 18.6875;
    const float pqC = 10000.0;

    float physical = frameBufferValueToPhysicalValue(v);
    float y        = physical / pqC; 

    float ym = pow(y, m1);
    return exp2(m2 * (log2(c1 + c2 * ym) - log2(1.0f + c3 * ym)));
}


// -----------------------------------------------------------------------------
// ICtCp conversion.
// Reference: ITU-T T.302 (https://www.itu.int/rec/T-REC-T.302/en)
// -----------------------------------------------------------------------------
float3 rgbToICtCp(float3 rgb) {// Input: linear Rec.2020
    float l = (rgb.r * 1688.0 + rgb.g * 2146.0 + rgb.g * 262.0)  / 4096.0;
    float m = (rgb.r * 683.0  + rgb.g * 2951.0 + rgb.g * 462.0)  / 4096.0;
    float s = (rgb.r * 99.0   + rgb.g * 309.0  + rgb.g * 3688.0) / 4096.0;

    float lPQ = inverseEotfSt2084(l);
    float mPQ = inverseEotfSt2084(m);
    float sPQ = inverseEotfSt2084(s);

    float3 ictCp;
    ictCp.r = (2048.0  * lPQ + 2048.0  * mPQ) / 4096.0;
    ictCp.g = (6610.0  * lPQ - 13613.0 * mPQ  + 7003.0 * sPQ) / 4096.0;
    ictCp.b = (17933.0 * lPQ - 17390.0 * mPQ  - 543.0  * sPQ) / 4096.0;

    return ictCp;
}

float3 iCtCpToRgb(float3 ictCp) { // Output: linear Rec.2020
    float l = ictCp.r + 0.00860904 * ictCp.g + 0.11103  * ictCp.b;
    float m = ictCp.r - 0.00860904 * ictCp.g - 0.11103  * ictCp.b;
    float s = ictCp.r + 0.560031   * ictCp.g - 0.320627 * ictCp.b;

    float lLin = eotfSt2084(l);
    float mLin = eotfSt2084(m);
    float sLin = eotfSt2084(s);

    float3 rgb;
    rgb.r = max(3.43661    * lLin - 2.50645   * mLin + 0.0698454 * sLin, 0.0);
    rgb.g = max(-0.79133   * lLin + 1.9836    * mLin - 0.192271  * sLin, 0.0);
    rgb.b = max(-0.0259499 * lLin - 0.0989137 * mLin + 1.12486   * sLin, 0.0);

    return rgb;
}


// -----------------------------------------------------------------------------
// Unified color space (UCS): ICtCp or Jzazbz.
// -----------------------------------------------------------------------------
float3 rgbToUcs(float3 rgb) {
    return rgbToICtCp(rgb);
}
float3 ucsToRgb(float3 ucs) {
    return iCtCpToRgb(ucs);
}

// -----------------------------------------------------------------------------
// GT7 Tone Mapping classes.
// -----------------------------------------------------------------------------
float2 initializeParameters(float physicalTargetLuminance) {
        
    float framebufferLuminanceTarget = physicalValueToFrameBufferValue(physicalTargetLuminance);

    float3 rgb = (float3)framebufferLuminanceTarget;
    float3 ucs = rgbToUcs(rgb);

    float framebufferLuminanceTargetUcs = ucs.r;

    return float2(framebufferLuminanceTarget, framebufferLuminanceTargetUcs);
}


float2 TonemappingSDRInit(float sdrWhitePointNits) {
    return initializeParameters(sdrWhitePointNits);
}


float3 ApplyTonemapping(float3 rgb, 
                        float framebufferLuminanceTarget, 
                        float framebufferLuminanceTargetUcs,
                        float sdrWhitePointNits,
                        float blendRatio,
                        float fadeStart,
                        float fadeEnd) {
    float sdrCorrectionFactor = 1.0 / physicalValueToFrameBufferValue(sdrWhitePointNits);


    float3 ucs = rgbToUcs(rgb);

    float skewedRgbR = evaluateCurve(rgb.r, framebufferLuminanceTarget, 0.25, 0.18, 0.444, 1.280);
    float skewedRgbG = evaluateCurve(rgb.g, framebufferLuminanceTarget, 0.25, 0.18, 0.444, 1.280);
    float skewedRgbB = evaluateCurve(rgb.b, framebufferLuminanceTarget, 0.25, 0.18, 0.444, 1.280);
    float3 skewedRgb = float3(skewedRgbR, skewedRgbG, skewedRgbB);


    float3 skewedUcs = rgbToUcs(skewedRgb);

    float chromaScale = chromaCurve(ucs.r / framebufferLuminanceTargetUcs, fadeStart, fadeEnd);

    float3 scaledUcs = float3(skewedUcs.r, ucs.g * chromaScale, ucs.b * chromaScale);
    float3 scaledRgb = ucsToRgb(scaledUcs);


    float blendedR = (1.0 - blendRatio) * skewedRgb.r + blendRatio * scaledRgb.r;
    float blendedG = (1.0 - blendRatio) * skewedRgb.g + blendRatio * scaledRgb.g;
    float blendedB = (1.0 - blendRatio) * skewedRgb.b + blendRatio * scaledRgb.b;

    float3 cout;
    cout.r = sdrCorrectionFactor * min(blendedR, framebufferLuminanceTarget);
    cout.g = sdrCorrectionFactor * min(blendedG, framebufferLuminanceTarget);
    cout.b = sdrCorrectionFactor * min(blendedB, framebufferLuminanceTarget);

    return cout;
}