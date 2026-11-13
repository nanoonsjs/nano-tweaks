// LiquidGlass.h - real liquid glass for MusicPill (1.6.5)
// Ported to Objective-C from LiquidGlassKit by Alexey Demin (Metal shader by the same author).
// What's behind the glass is captured each frame, then a Metal shader bends it at the edges like a lens
// (refraction), splits the colors a little there (dispersion), tints it and adds glare: Apple-style glass.
// The shader is compiled on the phone when it's first needed, so no extra files ship with the tweak.
#pragma once
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import <CoreVideo/CoreVideo.h>
#import <simd/simd.h>

static NSString *const kMPLiquidGlassShader = @
    "//\n"
    "//  LiquidGlassFragment.metal\n"
    "//  LiquidGlass\n"
    "//\n"
    "//  Created by Alexey Demin on 2025-12-05.\n"
    "//\n"
    "\n"
    "#include <metal_stdlib>\n"
    "using namespace metal;\n"
    "\n"
    "#define PI M_PI_F\n"
    "\n"
    "// Refractive indices for chromatic dispersion (simulating glass-like prismatic effects)\n"
    "constant float refractiveIndexRed = 1.0f - 0.02f;   // Red channel (slightly lower for dispersion)\n"
    "constant float refractiveIndexGreen = 1.0f;         // Green channel (neutral)\n"
    "constant float refractiveIndexBlue = 1.0f + 0.02f;  // Blue channel (slightly higher for dispersion)\n"
    "\n"
    "// Vertex output: Position (NDC) and UVs [0,1]\n"
    "struct VertexOutput {\n"
    "    float4 position [[position]];\n"
    "    half2 uv;\n"
    "};\n"
    "\n"
    "// Maximum number of rectangles (must match Swift side)\n"
    "constant int maxRectangles = 16;\n"
    "\n"
    "// Uniforms: Packed struct for Swift/Metal buffer binding\n"
    "struct ShaderUniforms {\n"
    "    float2 resolution;               // Viewport resolution (pixels)\n"
    "    float contentsScale;             // Scale factor for resolution independence\n"
    "    float2 touchPoint;               // Touch position in points (upper-left origin)\n"
    "    float shapeMergeSmoothness;      // Smooth min blend factor (higher = softer morph)\n"
    "    float cornerRadius;              // Rounding radius for rectangle corners\n"
    "    float cornerRoundnessExponent;   // Superellipse exponent for corner sharpness (higher = sharper)\n"
    "    float4 materialTint;             // RGBA tint for glass color\n"
    "    float glassThickness;            // Simulated thickness (pixels) for refraction depth\n"
    "    float refractiveIndex;           // Base refractive index of glass\n"
    "    float dispersionStrength;        // Chromatic aberration intensity\n"
    "    float fresnelDistanceRange;      // Edge distance over which Fresnel builds\n"
    "    float fresnelIntensity;          // Overall Fresnel reflection strength\n"
    "    float fresnelEdgeSharpness;      // Power for Fresnel falloff hardness\n"
    "    float glareDistanceRange;        // Edge distance for glare highlights\n"
    "    float glareAngleConvergence;     // Angle-based glare focusing\n"
    "    float glareOppositeSideBias;     // Multiplier for glare on far side of normal\n"
    "    float glareIntensity;            // Overall glare highlight strength\n"
    "    float glareEdgeSharpness;        // Power for glare falloff hardness\n"
    "    float glareDirectionOffset;      // Angular offset for glare direction\n"
    "    int rectangleCount;              // Number of active rectangles\n"
    "    float4 rectangles[maxRectangles]; // Array of rectangles (x, y, width, height) in points, upper-left origin\n"
    "};\n"
    "\n"
    "// Constant linear sampler for texture lookups (bilinear filtering, no wrap)\n"
    "constant sampler textureSampler(\n"
    "    filter::linear,\n"
    "    mag_filter::linear,\n"
    "    min_filter::linear,\n"
    "    address::clamp_to_edge\n"
    ");\n"
    "\n"
    "// =============================================================================\n"
    "// Signed Distance Field (SDF) Primitives and Operations\n"
    "// SDFs return signed distance: >0 outside, <0 inside, 0 on surface.\n"
    "// =============================================================================\n"
    "\n"
    "// Circle SDF: Distance from center minus radius\n"
    "float circleSDF(float2 point, float radius) {\n"
    "    return length(point) - radius;\n"
    "}\n"
    "\n"
    "// Superellipse SDF: Generalized superellipse for organic shapes.\n"
    "// Returns float3: x=distance, yz=gradient for normals.\n"
    "// Uses segment approximation (24 steps) for boundary evaluation.\n"
    "float3 superellipseSDF(float2 point, float scale, float exponent, constant ShaderUniforms& uniforms) {\n"
    "    point /= scale;\n"
    "    float2 signedPoint = sign(point);\n"
    "    float2 absPoint = abs(point);\n"
    "    float sumPowers = pow(absPoint.x, exponent) + pow(absPoint.y, exponent);\n"
    "    float2 gradient = signedPoint * pow(absPoint, float2(exponent - 1.0f)) * pow(sumPowers, 1.0f / exponent - 1.0f);\n"
    "\n"
    "    // Skip the loop entirely\n"
    "//    float distance = pow(sumPowers, 1.0f / exponent) - 1.0f;\n"
    "//    return float3(distance * scale, gradient);\n"
    "\n"
    "    // Abs and swap for quadrant handling\n"
    "    point = abs(point);\n"
    "    if (point.y > point.x) {\n"
    "        point = point.yx;\n"
    "    }\n"
    "    exponent = 2.0f / exponent;\n"
    "    float sideSign = 1.0f;\n"
    "    float minDistanceSquared = 1e20f;\n"
    "    const int segmentCount = 24;\n"
    "    float2 previousQuadrantPoint = float2(1.0f, 0.0f);\n"
    "    for (int i = 1; i < segmentCount; ++i) {\n"
    "        float segmentParam = float(i) / float(segmentCount - 1);\n"
    "        float2 quadrantPoint = float2(\n"
    "            pow(cos(segmentParam * PI / 4.0f), exponent),\n"
    "            pow(sin(segmentParam * PI / 4.0f), exponent)\n"
    "        );\n"
    "        float2 pointA = point - previousQuadrantPoint;\n"
    "        float2 pointB = quadrantPoint - previousQuadrantPoint;\n"
    "        float2 perpendicular = pointA - pointB * clamp(dot(pointA, pointB) / dot(pointB, pointB), 0.0f, 1.0f);\n"
    "        float distSq = dot(perpendicular, perpendicular);\n"
    "        if (distSq < minDistanceSquared) {\n"
    "            minDistanceSquared = distSq;\n"
    "            sideSign = pointA.x * pointB.y - pointA.y * pointB.x;\n"
    "        }\n"
    "        previousQuadrantPoint = quadrantPoint;\n"
    "    }\n"
    "    return float3(sqrt(minDistanceSquared) * sign(sideSign) * scale, gradient);\n"
    "}\n"
    "\n"
    "// Superellipse corner SDF: For smooth, parametric rounding in rectangles.\n"
    "float superellipseCornerSDF(float2 point, float radius, float exponent) {\n"
    "    point = abs(point);\n"
    "    float value = pow(pow(point.x, exponent) + pow(point.y, exponent), 1.0f / exponent);\n"
    "    return value - radius;\n"
    "}\n"
    "\n"
    "// Rounded rectangle SDF: Box with superellipse corners for customizable rounding.\n"
    "// rect: float4(x, y, width, height) in points, upper-left origin\n"
    "// fragmentCoord: pixel coordinates (upper-left origin)\n"
    "float roundedRectangleSDF(float2 fragmentCoord, float4 rect, float cornerRadius, float roundnessExponent, constant ShaderUniforms& uniforms) {\n"
    "    // Convert rectangle from points to pixels\n"
    "    float2 rectOriginPx = rect.xy * uniforms.contentsScale;\n"
    "    float2 rectSizePx = rect.zw * uniforms.contentsScale;\n"
    "    float scaledCornerRadius = cornerRadius * uniforms.contentsScale;\n"
    "\n"
    "    // Calculate rectangle center in pixels\n"
    "    float2 rectCenterPx = rectOriginPx + rectSizePx * 0.5f;\n"
    "\n"
    "    // Translate fragment to rectangle-centered coordinates\n"
    "    float2 point = fragmentCoord - rectCenterPx;\n"
    "\n"
    "    // Distance to unrounded box half-extents\n"
    "    float2 halfExtents = rectSizePx * 0.5f;\n"
    "    float2 edgeDistance = abs(point) - halfExtents;\n"
    "\n"
    "    float surfaceDistance;\n"
    "\n"
    "    if (edgeDistance.x > -scaledCornerRadius && edgeDistance.y > -scaledCornerRadius) {\n"
    "        // Corner region: Apply superellipse rounding\n"
    "        float2 cornerCenter = sign(point) * (halfExtents - float2(scaledCornerRadius));\n"
    "        float2 cornerRelativePoint = point - cornerCenter;\n"
    "        surfaceDistance = superellipseCornerSDF(cornerRelativePoint, scaledCornerRadius, roundnessExponent);\n"
    "    } else {\n"
    "        // Straight edges or interior: Standard rounded box formula\n"
    "        surfaceDistance = min(max(edgeDistance.x, edgeDistance.y), 0.0f) + length(max(edgeDistance, 0.0f));\n"
    "    }\n"
    "\n"
    "    return surfaceDistance;\n"
    "}\n"
    "\n"
    "// Smooth union: Blends two SDFs with polynomial smoothing to avoid sharp seams during morphing.\n"
    "float smoothUnion(float distanceA, float distanceB, float smoothness) {\n"
    "    float hermite = clamp(0.5f + 0.5f * (distanceB - distanceA) / smoothness, 0.0f, 1.0f);\n"
    "    return mix(distanceB, distanceA, hermite) - smoothness * hermite * (1.0f - hermite);\n"
    "}\n"
    "\n"
    "// Primary SDF: Merges all rectangles in the array using smooth union.\n"
    "// fragmentCoord: pixel coordinates (upper-left origin)\n"
    "float primaryShapeSDF(float2 fragmentCoord, constant ShaderUniforms& uniforms) {\n"
    "    // Start with a large distance (outside all shapes)\n"
    "    float combinedDistance = 1e10f;\n"
    "\n"
    "    // Iterate over all active rectangles and compute smooth union\n"
    "    for (int i = 0; i < uniforms.rectangleCount && i < maxRectangles; ++i) {\n"
    "        float4 rect = uniforms.rectangles[i];\n"
    "\n"
    "        // Skip empty rectangles\n"
    "        if (rect.z <= 0.0f || rect.w <= 0.0f) continue;\n"
    "\n"
    "        float rectDistance = roundedRectangleSDF(\n"
    "            fragmentCoord,\n"
    "            rect,\n"
    "            min(uniforms.cornerRadius, 0.5f * min(rect.z, rect.w)),\n"
    "            uniforms.cornerRoundnessExponent,\n"
    "            uniforms\n"
    "        );\n"
    "\n"
    "        // Normalize distance to resolution for consistent smooth union\n"
    "        float normalizedRectDist = rectDistance / uniforms.resolution.y;\n"
    "\n"
    "        if (i == 0) {\n"
    "            combinedDistance = normalizedRectDist;\n"
    "        } else {\n"
    "            combinedDistance = smoothUnion(combinedDistance, normalizedRectDist, uniforms.shapeMergeSmoothness);\n"
    "        }\n"
    "    }\n"
    "\n"
    "    return combinedDistance;\n"
    "}\n"
    "\n"
    "// =============================================================================\n"
    "// Surface Normal Computation\n"
    "// Gradients of SDF provide view-space normals for refraction and lighting.\n"
    "// =============================================================================\n"
    "\n"
    "// Adaptive finite-difference normal: Uses screen derivatives for epsilon (scale-aware).\n"
    "// Raw gradient used (not normalized) in some steps for magnitude encoding.\n"
    "float2 computeSurfaceNormal(float2 fragmentCoord, constant ShaderUniforms& uniforms) {\n"
    "    // Adaptive epsilon from pixel derivatives (fallback to min for stability)\n"
    "    float2 epsilon = float2(\n"
    "        max(abs(dfdx(fragmentCoord.x)), 0.0001f),\n"
    "        max(abs(dfdy(fragmentCoord.y)), 0.0001f)\n"
    "    );\n"
    "\n"
    "    float2 gradient = float2(\n"
    "        primaryShapeSDF(fragmentCoord + float2(epsilon.x, 0.0f), uniforms) -\n"
    "        primaryShapeSDF(fragmentCoord - float2(epsilon.x, 0.0f), uniforms),\n"
    "        primaryShapeSDF(fragmentCoord + float2(0.0f, epsilon.y), uniforms) -\n"
    "        primaryShapeSDF(fragmentCoord - float2(0.0f, epsilon.y), uniforms)\n"
    "    ) / (2.0f * epsilon);\n"
    "\n"
    "    // normalize(gradient);  // Commented: Raw gradient preferred for debug magnitude; normalized for effects\n"
    "    return gradient * 1.414213562f * 1000.0f;  // Scaled for visualization\n"
    "}\n"
    "\n"
    "// Isotropic four-sample normal (diagonal finite differences for less bias).\n"
    "float2 computeIsotropicNormal(float2 fragmentCoord, constant ShaderUniforms& uniforms) {\n"
    "    float epsilon = 0.7071f * 0.0005f;  // Diagonal step size\n"
    "    float2 offset1 = float2(1.0f, 1.0f);\n"
    "    float2 offset2 = float2(-1.0f, 1.0f);\n"
    "    float2 offset3 = float2(1.0f, -1.0f);\n"
    "    float2 offset4 = float2(-1.0f, -1.0f);\n"
    "\n"
    "    return normalize(\n"
    "        offset1 * primaryShapeSDF(fragmentCoord + epsilon * offset1, uniforms) +\n"
    "        offset2 * primaryShapeSDF(fragmentCoord + epsilon * offset2, uniforms) +\n"
    "        offset3 * primaryShapeSDF(fragmentCoord + epsilon * offset3, uniforms) +\n"
    "        offset4 * primaryShapeSDF(fragmentCoord + epsilon * offset4, uniforms)\n"
    "    );\n"
    "}\n"
    "\n"
    "// Basic central-difference normal (simple axis-aligned).\n"
    "float2 computeCentralNormal(float2 fragmentCoord, constant ShaderUniforms& uniforms) {\n"
    "    float epsilon = 0.0005f;\n"
    "    float2 offset = float2(epsilon, 0.0f);\n"
    "\n"
    "    float dx = primaryShapeSDF(fragmentCoord + offset.xy, uniforms) -\n"
    "               primaryShapeSDF(fragmentCoord - offset.xy, uniforms);\n"
    "    float dy = primaryShapeSDF(fragmentCoord + offset.yx, uniforms) -\n"
    "               primaryShapeSDF(fragmentCoord - offset.yx, uniforms);\n"
    "\n"
    "    return normalize(float2(dx, dy));\n"
    "}\n"
    "\n"
    "// =============================================================================\n"
    "// Color Space Utilities (Perceptual Adjustments via LCH)\n"
    "// For tinting highlights without desaturation; based on CIE LAB/LCH conversions.\n"
    "// Half for colors; float for matrices to preserve precision.\n"
    "// =============================================================================\n"
    "\n"
    "// D65 white point (sRGB standard)\n"
    "constant float3 d65WhitePoint = float3(0.95045592705f, 1.0f, 1.08905775076f);\n"
    "//constant float3 d50WhitePoint = float3(0.96429567643f, 1.0f, 0.82510460251f);\n"
    "constant float3 whiteReference = d65WhitePoint;\n"
    "\n"
    "// sRGB to XYZ matrix\n"
    "constant float3x3 rgbToXyzMatrix = float3x3(\n"
    "    float3(0.4124f, 0.3576f, 0.1805f),\n"
    "    float3(0.2126f, 0.7152f, 0.0722f),\n"
    "    float3(0.0193f, 0.1192f, 0.9505f)\n"
    ");\n"
    "\n"
    "// XYZ (D65) to XYZ (D50) adaptation\n"
    "constant float3x3 xyzD65ToD50Matrix = float3x3(\n"
    "    float3(1.0479298208405488f,  0.022946793341019088f, -0.05019222954313557f),\n"
    "    float3(0.029627815688159344f,  0.990434484573249f  , -0.01707382502938514f),\n"
    "    float3(-0.009243058152591178f,  0.015055144896577895f,  0.7518742899580008f)\n"
    ");\n"
    "\n"
    "// XYZ to linear RGB matrix\n"
    "constant float3x3 xyzToRgbMatrix = float3x3(\n"
    "    float3( 3.2406255f, -1.537208f , -0.4986286f),\n"
    "    float3(-0.9689307f,  1.8757561f,  0.0415175f),\n"
    "    float3( 0.0557101f, -0.2040211f,  1.0569959f)\n"
    ");\n"
    "\n"
    "// XYZ (D50) to XYZ (D65) adaptation\n"
    "constant float3x3 xyzD50ToD65Matrix = float3x3(\n"
    "    float3(0.9554734527042182f  , -0.023098536874261423f,  0.0632593086610217f  ),\n"
    "    float3(-0.028369706963208136f,  1.0099954580058226f  ,  0.021041398966943008f),\n"
    "    float3( 0.012314001688319899f, -0.020507696433477912f,  1.3303659366080753f )\n"
    ");\n"
    "\n"
    "// sRGB uncompanding (gamma to linear)\n"
    "float linearizeSRGB(float channel) {\n"
    "    return channel > 0.04045f ? pow((channel + 0.055f) / 1.055f, 2.4f) : channel / 12.92f;\n"
    "}\n"
    "\n"
    "// Linear to sRGB companding (apply gamma)\n"
    "float gammaCorrectSRGB(float linear) {\n"
    "    return linear <= 0.0031308f ? 12.92f * linear : 1.055f * pow(linear, 0.41666666666f) - 0.055f;\n"
    "}\n"
    "\n"
    "// Linear RGB to XYZ\n"
    "float3 linearRgbToXyz(float3 linearRgb) {\n"
    "    return (whiteReference.x == d65WhitePoint.x) ? linearRgb * rgbToXyzMatrix : linearRgb * rgbToXyzMatrix * xyzD65ToD50Matrix;\n"
    "}\n"
    "\n"
    "// sRGB to linear RGB\n"
    "half3 srgbToLinear(half3 srgb) {\n"
    "    return half3(linearizeSRGB(srgb.x), linearizeSRGB(srgb.y), linearizeSRGB(srgb.z));\n"
    "}\n"
    "\n"
    "// Linear RGB to sRGB\n"
    "half3 linearToSrgb(half3 linear) {\n"
    "    return half3(gammaCorrectSRGB(linear.x), gammaCorrectSRGB(linear.y), gammaCorrectSRGB(linear.z));\n"
    "}\n"
    "\n"
    "// sRGB to XYZ\n"
    "float3 srgbToXyz(half3 srgb) {\n"
    "    return linearRgbToXyz(float3(srgbToLinear(srgb)));\n"
    "}\n"
    "\n"
    "// XYZ to LAB non-linear transform\n"
    "float xyzToLabNonlinear(float normalizedX) {\n"
    "    // Threshold: (24/116)^3 ≈ 0.00885645167\n"
    "    return normalizedX > 0.00885645167f ? pow(normalizedX, 1.0f / 3.0f) : 7.78703703704f * normalizedX + 0.13793103448f;\n"
    "}\n"
    "\n"
    "// XYZ to CIE LAB (perceptual uniform space)\n"
    "float3 xyzToLab(float3 xyz) {\n"
    "    float3 scaledXyz = xyz / whiteReference;\n"
    "    scaledXyz = float3(\n"
    "        xyzToLabNonlinear(scaledXyz.x),\n"
    "        xyzToLabNonlinear(scaledXyz.y),\n"
    "        xyzToLabNonlinear(scaledXyz.z)\n"
    "    );\n"
    "    return float3(\n"
    "        116.0f * scaledXyz.y - 16.0f,  // Lightness (L)\n"
    "        500.0f * (scaledXyz.x - scaledXyz.y),  // a* (green-red)\n"
    "        200.0f * (scaledXyz.y - scaledXyz.z)   // b* (blue-yellow)\n"
    "    );\n"
    "}\n"
    "\n"
    "// sRGB to LAB\n"
    "float3 srgbToLab(half3 srgb) {\n"
    "    return xyzToLab(srgbToXyz(srgb));\n"
    "}\n"
    "\n"
    "// LAB to LCH (cylindrical: Lightness, Chroma, Hue in degrees)\n"
    "float3 labToLch(float3 lab) {\n"
    "    float chroma = sqrt(dot(lab.yz, lab.yz));\n"
    "    float hueDegrees = atan2(lab.z, lab.y) * (180.0f / PI);\n"
    "    return float3(lab.x, chroma, hueDegrees);\n"
    "}\n"
    "\n"
    "// sRGB to LCH\n"
    "float3 srgbToLch(half3 srgb) {\n"
    "    return labToLch(srgbToLab(srgb));\n"
    "}\n"
    "\n"
    "// XYZ to linear RGB\n"
    "float3 xyzToLinearRgb(float3 xyz) {\n"
    "    return (whiteReference.x == d65WhitePoint.x) ? xyz * xyzToRgbMatrix : xyz * xyzD50ToD65Matrix * xyzToRgbMatrix;\n"
    "}\n"
    "\n"
    "// XYZ to sRGB\n"
    "half3 xyzToSrgb(float3 xyz) {\n"
    "    return linearToSrgb(half3(xyzToLinearRgb(xyz)));\n"
    "}\n"
    "\n"
    "// LAB to XYZ inverse non-linear\n"
    "float labToXyzNonlinear(float transformed) {\n"
    "    // Threshold: 6/29 ≈ 0.206897\n"
    "    return transformed > 0.206897f ? transformed * transformed * transformed : 0.12841854934f * (transformed - 0.137931034f);\n"
    "}\n"
    "\n"
    "// LAB to XYZ\n"
    "float3 labToXyz(float3 lab) {\n"
    "    float whiteScaled = (lab.x + 16.0f) / 116.0f;\n"
    "    return whiteReference * float3(\n"
    "        labToXyzNonlinear(whiteScaled + lab.y / 500.0f),\n"
    "        labToXyzNonlinear(whiteScaled),\n"
    "        labToXyzNonlinear(whiteScaled - lab.z / 200.0f)\n"
    "    );\n"
    "}\n"
    "\n"
    "// LAB to sRGB\n"
    "half3 labToSrgb(float3 lab) {\n"
    "    return xyzToSrgb(labToXyz(lab));\n"
    "}\n"
    "\n"
    "// LCH to LAB\n"
    "float3 lchToLab(float3 lch) {\n"
    "    float hueRadians = lch.z * (PI / 180.0f);\n"
    "    return float3(lch.x, lch.y * cos(hueRadians), lch.y * sin(hueRadians));\n"
    "}\n"
    "\n"
    "// LCH to sRGB\n"
    "half3 lchToSrgb(float3 lch) {\n"
    "    return labToSrgb(lchToLab(lch));\n"
    "}\n"
    "\n"
    "// HSV to RGB (for normal rainbow visualization)\n"
    "half3 hsvToRgb(half3 hsv) {\n"
    "    half4 k = half4(1.0h, 2.0h / 3.0h, 1.0h / 3.0h, 3.0h);\n"
    "    half3 p = abs(fract(hsv.xxx + k.xyz) * 6.0h - k.www);\n"
    "    return hsv.z * mix(k.xxx, clamp(p - k.xxx, 0.0h, 1.0h), hsv.y);\n"
    "}\n"
    "\n"
    "// Vector to angle [0, 2π]\n"
    "float vectorToAngle(float2 vector) {\n"
    "    float angle = atan2(vector.y, vector.x);\n"
    "    return (angle < 0.0f) ? angle + 2.0f * PI : angle;\n"
    "}\n"
    "\n"
    "// Normalized vector to rainbow color (HSV hue from angle)\n"
    "half3 vectorToRainbowColor(float2 vector) {\n"
    "    float angle = vectorToAngle(vector);\n"
    "    half hue = half(angle / (2.0f * PI));\n"
    "    half3 hsv = half3(hue, 1.0h, 1.0h);\n"
    "    return hsvToRgb(hsv);\n"
    "}\n"
    "\n"
    "// Texture sample with per-channel dispersion offset (simulates prism fringing).\n"
    "// Samples R/G/B separately with refractive index-based UV shifts.\n"
    "half4 sampleWithDispersion(texture2d<half> texture, float2 baseUv, float2 offset, float dispersionFactor) {\n"
    "    half4 color = half4(1.0h);\n"
    "    // Red: Minimal shift (lower index)\n"
    "    color.r = texture.sample(textureSampler, baseUv + offset * (1.0f - (refractiveIndexRed - 1.0f) * dispersionFactor)).r;\n"
    "    // Green: Neutral\n"
    "    color.g = texture.sample(textureSampler, baseUv + offset * (1.0f - (refractiveIndexGreen - 1.0f) * dispersionFactor)).g;\n"
    "    // Blue: Maximal shift (higher index)\n"
    "    color.b = texture.sample(textureSampler, baseUv + offset * (1.0f - (refractiveIndexBlue - 1.0f) * dispersionFactor)).b;\n"
    "    return color;\n"
    "}\n"
    "\n"
    "// =============================================================================\n"
    "// Fragment Shader: Full Progressive Effect Pipeline\n"
    "// =============================================================================\n"
    "fragment half4 liquidGlassEffect(VertexOutput input [[stage_in]],\n"
    "                                 constant ShaderUniforms& uniforms [[buffer(0)]],\n"
    "                                 texture2d<half> background [[texture(0)]]) {\n"
    "\n"
    "    // Logical resolution (scale-normalized)\n"
    "    float2 logicalResolution = uniforms.resolution / uniforms.contentsScale;\n"
    "\n"
    "    // Fragment coordinate in pixels (from UV, upper-left origin)\n"
    "    float2 fragmentPixelCoord = float2(input.uv) * uniforms.resolution;\n"
    "\n"
    "    // Primary merged SDF distance (normalized to resolution.y)\n"
    "    float shapeDistance = primaryShapeSDF(fragmentPixelCoord, uniforms);\n"
    "\n"
    "    half4 outputColor;\n"
    "\n"
    "    // Pixel size for anti-aliasing (y-dominant for aspect)\n"
    "//    float pixelSize = 2.0f / uniforms.resolution.y;\n"
    "\n"
    "    // Slightly expanded threshold for smoother AA\n"
    "    if (shapeDistance < 0.005f) {\n"
    "        float normalizedDepth = -shapeDistance * logicalResolution.y;\n"
    "\n"
    "        // Refraction shift factor\n"
    "        float depthRatio = 1.0f - normalizedDepth / uniforms.glassThickness;\n"
    "        float incidentAngle = asin(pow(depthRatio, 2.0f));\n"
    "        float transmittedAngle = asin(1.0f / uniforms.refractiveIndex * sin(incidentAngle));\n"
    "        float edgeShiftFactor = -tan(transmittedAngle - incidentAngle);\n"
    "        if (normalizedDepth >= uniforms.glassThickness) {\n"
    "            edgeShiftFactor = 0.0f;\n"
    "        }\n"
    "\n"
    "        if (edgeShiftFactor <= 0.0f) {\n"
    "            outputColor = background.sample(textureSampler, float2(input.uv));\n"
    "            outputColor = mix(outputColor, half4(half3(uniforms.materialTint.rgb), 1.0h), half(uniforms.materialTint.a * 0.8f));\n"
    "        } else {\n"
    "            float2 surfaceNormal = computeSurfaceNormal(fragmentPixelCoord, uniforms);\n"
    "            // Dispersion-sampled refraction (scale/aspect corrected)\n"
    "            half2 offsetUv = half2(-surfaceNormal * edgeShiftFactor * 0.05f * uniforms.contentsScale * float2(\n"
    "                uniforms.resolution.y / (logicalResolution.x * uniforms.contentsScale),\n"
    "                1.0f\n"
    "            ));\n"
    "            half4 refractedWithDispersion = sampleWithDispersion(background, float2(input.uv), float2(offsetUv), uniforms.dispersionStrength);\n"
    "\n"
    "            // Base material tint\n"
    "            outputColor = mix(refractedWithDispersion, half4(half3(uniforms.materialTint.rgb), 1.0h), half(uniforms.materialTint.a * 0.8f));\n"
    "\n"
    "            // Fresnel: LCH-lightness boosted reflection\n"
    "            float fresnelValue = clamp(\n"
    "                pow(\n"
    "                    1.0f + shapeDistance * logicalResolution.y / 1500.0f * pow(500.0f / uniforms.fresnelDistanceRange, 2.0f) + uniforms.fresnelEdgeSharpness,\n"
    "                    5.0f\n"
    "                ),\n"
    "                0.0f, 1.0f\n"
    "            );\n"
    "\n"
    "            half3 fresnelBaseTint = mix(half3(1.0h), half3(uniforms.materialTint.rgb), half(uniforms.materialTint.a * 0.5f));\n"
    "            float3 fresnelLch = srgbToLch(fresnelBaseTint);\n"
    "            fresnelLch.x += 20.0f * fresnelValue * uniforms.fresnelIntensity;\n"
    "            fresnelLch.x = clamp(fresnelLch.x, 0.0f, 100.0f);\n"
    "\n"
    "            outputColor = mix(\n"
    "                outputColor,\n"
    "                half4(lchToSrgb(fresnelLch), 1.0h),\n"
    "                half(fresnelValue * uniforms.fresnelIntensity * 0.7f * length(surfaceNormal))\n"
    "            );\n"
    "\n"
    "            // Glare: Directional, LCH-boosted (lightness + chroma)\n"
    "            float glareGeometryValue = clamp(\n"
    "                pow(\n"
    "                    1.0f + shapeDistance * logicalResolution.y / 1500.0f * pow(500.0f / uniforms.glareDistanceRange, 2.0f) + uniforms.glareEdgeSharpness,\n"
    "                    5.0f\n"
    "                ),\n"
    "                0.0f, 1.0f\n"
    "            );\n"
    "\n"
    "            float glareAngle = (vectorToAngle(normalize(surfaceNormal)) - PI / 4.0f + uniforms.glareDirectionOffset) * 2.0f;\n"
    "            int isFarSide = 0;\n"
    "            if ((glareAngle > PI * (2.0f - 0.5f) && glareAngle < PI * (4.0f - 0.5f)) || glareAngle < PI * (0.0f - 0.5f)) {\n"
    "                isFarSide = 1;\n"
    "            }\n"
    "            float angularGlare = (0.5f + sin(glareAngle) * 0.5f) *\n"
    "                                 (isFarSide == 1 ? 1.2f * uniforms.glareOppositeSideBias : 1.2f) *\n"
    "                                 uniforms.glareIntensity;\n"
    "            angularGlare = clamp(pow(angularGlare, 0.1f + uniforms.glareAngleConvergence * 2.0f), 0.0f, 1.0f);\n"
    "\n"
    "            half3 baseGlare = mix(refractedWithDispersion.rgb, half3(uniforms.materialTint.rgb), half(uniforms.materialTint.a * 0.5f));\n"
    "            float3 glareLch = srgbToLch(baseGlare);\n"
    "            glareLch.x += 150.0f * angularGlare * glareGeometryValue;\n"
    "            glareLch.y += 30.0f * angularGlare * glareGeometryValue;\n"
    "            glareLch.x = clamp(glareLch.x, 0.0f, 120.0f);\n"
    "\n"
    "            outputColor = mix(\n"
    "                outputColor,\n"
    "                half4(lchToSrgb(glareLch), 1.0h),\n"
    "                half(angularGlare * glareGeometryValue * length(surfaceNormal))\n"
    "            );\n"
    "        }\n"
    "    } else {\n"
    "        outputColor = half4(0);//background.sample(textureSampler, float2(input.uv));\n"
    "    }\n"
    "\n"
    "    // Boundary anti-aliasing (smoothstep blend)\n"
    "    outputColor = mix(outputColor, half4(0), smoothstep(-0.01f, 0.005f, shapeDistance));\n"
    "\n"
    "    return outputColor;\n"
    "}\n"
    "\n"
    "// Vertex shader: Hardcoded fullscreen quad.\n"
    "vertex VertexOutput fullscreenQuad(uint vertexID [[vertex_id]]) {\n"
    "    VertexOutput output;\n"
    "\n"
    "    // Unpacked quad: 0=BL, 1=BR, 2=TL, 3=TR (triangle strip order)\n"
    "    float2 positions[4] = {\n"
    "        float2(-1.0f, -1.0f),  // Bottom-left\n"
    "        float2( 1.0f, -1.0f),  // Bottom-right\n"
    "        float2(-1.0f,  1.0f),  // Top-left\n"
    "        float2( 1.0f,  1.0f)   // Top-right\n"
    "    };\n"
    "\n"
    "    float2 uvs[4] = {\n"
    "        float2(0.0f, 0.0f),\n"
    "        float2(1.0f, 0.0f),\n"
    "        float2(0.0f, 1.0f),\n"
    "        float2(1.0f, 1.0f)\n"
    "    };\n"
    "\n"
    "    output.position = float4(positions[vertexID], 0.0f, 1.0f);\n"
    "    output.uv = half2(uvs[vertexID]);\n"
    "    return output;\n"
    "}\n"
    "\n";

// mirrors the shader's ShaderUniforms (same layout as the Swift original's SIMD struct)
typedef struct {
    simd_float2 resolution;
    float contentsScale;
    simd_float2 touchPoint;
    float shapeMergeSmoothness;
    float cornerRadius;
    float cornerRoundnessExponent;
    simd_float4 materialTint;
    float glassThickness;
    float refractiveIndex;
    float dispersionStrength;
    float fresnelDistanceRange;
    float fresnelIntensity;
    float fresnelEdgeSharpness;
    float glareDistanceRange;
    float glareAngleConvergence;
    float glareOppositeSideBias;
    float glareIntensity;
    float glareEdgeSharpness;
    float glareDirectionOffset;
    int32_t rectangleCount;
    simd_float4 rectangles[16];
} MPLGUniforms;

// one Metal pipeline for every glass view
static id<MTLDevice> gLGDevice;
static id<MTLRenderPipelineState> gLGPipeline;
static BOOL gLGFailed;
static BOOL MPLGReady(void) {
    if (gLGPipeline) return YES;
    if (gLGFailed) return NO;
    gLGDevice = MTLCreateSystemDefaultDevice();
    if (!gLGDevice) { gLGFailed = YES; return NO; }
    NSError *err = nil;
    id<MTLLibrary> lib = [gLGDevice newLibraryWithSource:kMPLiquidGlassShader options:nil error:&err];
    id<MTLFunction> vf = [lib newFunctionWithName:@"fullscreenQuad"], ff = [lib newFunctionWithName:@"liquidGlassEffect"];
    if (!vf || !ff) { NSLog(@"[MusicPill] liquid glass shader: %@", err); gLGFailed = YES; return NO; }
    MTLRenderPipelineDescriptor *d = [MTLRenderPipelineDescriptor new];
    d.vertexFunction = vf; d.fragmentFunction = ff;
    d.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    gLGPipeline = [gLGDevice newRenderPipelineStateWithDescriptor:d error:&err];
    if (!gLGPipeline) { NSLog(@"[MusicPill] liquid glass pipeline: %@", err); gLGFailed = YES; return NO; }
    return YES;
}

// captures what's behind it (a CABackdropLayer)
@interface MPLGBackdrop : UIView
@end
@implementation MPLGBackdrop
+ (Class)layerClass { return NSClassFromString(@"CABackdropLayer") ?: [CALayer class]; }
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    self.userInteractionEnabled = NO;
    @try {
        [self.layer setValue:@NO forKey:@"layerUsesCoreImageFilters"];
        [self.layer setValue:@YES forKey:@"windowServerAware"];
        [self.layer setValue:[NSUUID UUID].UUIDString forKey:@"groupName"];
    } @catch (__unused id e) {}
    return self;
}
@end

@interface MPLiquidGlassView : MTKView
@property (nonatomic, strong) UIColor *glassTint;   // the material tint (alpha = how tinted)
// 1.7.2: several shapes (in our own coordinates) melted into one piece of glass (smooth union), each rounded
// up to shapeRadius; mergePts = how far apart they still blend. No shapes = our bounds with our corner radius.
@property (nonatomic, copy) NSArray<NSValue *> *shapes;
@property (nonatomic) CGFloat shapeRadius, mergePts;
@end
@implementation MPLiquidGlassView {
    id<MTLCommandQueue> _queue;
    id<MTLBuffer> _uniforms;
    CVMetalTextureCacheRef _cache;
    CVPixelBufferRef _buffer;
    CVMetalTextureRef _cvTex;
    id<MTLTexture> _bg;
    MPLGBackdrop *_backdrop;
    CGFloat _scaleCo, _blur;
    MPSImageGaussianBlur *_blurK;
}
- (instancetype)initWithFrame:(CGRect)f {
    if (!MPLGReady()) return nil;
    if (!(self = [super initWithFrame:f device:gLGDevice])) return nil;
    self.userInteractionEnabled = NO;
    self.opaque = NO; self.layer.opaque = NO;
    self.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    self.preferredFramesPerSecond = 60;
    self.paused = NO;
    _queue = [gLGDevice newCommandQueue];
    _uniforms = [gLGDevice newBufferWithLength:sizeof(MPLGUniforms) options:0];
    CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, gLGDevice, NULL, &_cache);
    _backdrop = [[MPLGBackdrop alloc] initWithFrame:f];
    _scaleCo = 0.35;   // the background is captured small (cheap) and blurred a touch
    _blur = 0.3;
    return self;
}
- (void)dealloc {
    if (_cvTex) CFRelease(_cvTex);
    if (_buffer) CVPixelBufferRelease(_buffer);
    if (_cache) CFRelease(_cache);
    [_backdrop removeFromSuperview];
}
- (void)removeFromSuperview { [_backdrop removeFromSuperview]; [super removeFromSuperview]; }
- (void)setupBuffer {
    CGFloat s = self.contentScaleFactor * _scaleCo;
    size_t w = MAX(4, (size_t)(self.bounds.size.width * s)), h = MAX(4, (size_t)(self.bounds.size.height * s));
    if (_buffer && CVPixelBufferGetWidth(_buffer) == w && CVPixelBufferGetHeight(_buffer) == h) return;
    if (_cvTex) { CFRelease(_cvTex); _cvTex = NULL; }
    if (_buffer) { CVPixelBufferRelease(_buffer); _buffer = NULL; }
    NSDictionary *attrs = @{(id)kCVPixelBufferMetalCompatibilityKey: @YES, (id)kCVPixelBufferCGImageCompatibilityKey: @YES, (id)kCVPixelBufferIOSurfacePropertiesKey: @{}};
    if (CVPixelBufferCreate(kCFAllocatorDefault, w, h, kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)attrs, &_buffer) != kCVReturnSuccess) return;
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _cache, _buffer, NULL, MTLPixelFormatBGRA8Unorm, w, h, 0, &_cvTex);
}
- (void)layoutSubviews {
    [super layoutSubviews];
    [self setupBuffer];
}
// the backdrop sits right under us, same frame, and is drawn into our small buffer
- (void)capture {
    UIView *sv = self.superview;
    if (!sv || !_buffer || !_cvTex) return;
    CALayer *cur = self.layer.presentationLayer ?: self.layer;
    CGRect f = [cur convertRect:cur.bounds toLayer:sv.layer];
    _backdrop.frame = f;
    if (_backdrop.superview != sv) [sv insertSubview:_backdrop belowSubview:self];
    CVPixelBufferLockBaseAddress(_buffer, 0);
    void *data = CVPixelBufferGetBaseAddress(_buffer);
    size_t w = CVPixelBufferGetWidth(_buffer), h = CVPixelBufferGetHeight(_buffer), bpr = CVPixelBufferGetBytesPerRow(_buffer);
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(data, w, h, 8, bpr, cs, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    CGColorSpaceRelease(cs);
    if (ctx) {
        CGContextClearRect(ctx, CGRectMake(0, 0, w, h));
        CGFloat s = self.contentScaleFactor * _scaleCo;
        CGContextScaleCTM(ctx, s, s);   // as in the original: the shader's UVs undo the flip
        UIGraphicsPushContext(ctx);
        [_backdrop drawViewHierarchyInRect:_backdrop.bounds afterScreenUpdates:NO];
        UIGraphicsPopContext();
        CGContextRelease(ctx);
    }
    CVPixelBufferUnlockBaseAddress(_buffer, 0);
    CVMetalTextureCacheFlush(_cache, 0);
    _bg = CVMetalTextureGetTexture(_cvTex);
}
- (void)blurBG:(id<MTLCommandBuffer>)cb {
    if (_blur <= 0 || !_bg) return;
    if (!_blurK) { _blurK = [[MPSImageGaussianBlur alloc] initWithDevice:gLGDevice sigma:(float)(_blur * self.contentScaleFactor)]; _blurK.edgeMode = MPSImageEdgeModeClamp; }
    MPSImageGaussianBlur *b = _blurK;
    id<MTLTexture> t = _bg;
    [b encodeToCommandBuffer:cb inPlaceTexture:&t fallbackCopyAllocator:nil];
    _bg = t;
}
- (void)updateUniforms {
    MPLGUniforms u; memset(&u, 0, sizeof(u));
    CGFloat sc = self.contentScaleFactor;
    u.resolution = simd_make_float2(self.bounds.size.width * sc, self.bounds.size.height * sc);
    u.contentsScale = sc;
    u.shapeMergeSmoothness = 0.2;
    u.cornerRadius = self.layer.cornerRadius;
    if (self.shapes.count) {
        u.cornerRadius = self.shapeRadius;
        u.shapeMergeSmoothness = MAX(0.001, self.mergePts / MAX(1, self.bounds.size.height));
    }
    u.cornerRoundnessExponent = 2;
    // the "regular" glass from LiquidGlassKit
    u.glassThickness = 10; u.refractiveIndex = 1.5; u.dispersionStrength = 5;
    u.fresnelDistanceRange = 70; u.fresnelIntensity = 0; u.fresnelEdgeSharpness = 0;
    u.glareDistanceRange = 30; u.glareAngleConvergence = 0.1; u.glareOppositeSideBias = 1;
    u.glareIntensity = 0.1; u.glareEdgeSharpness = -0.15; u.glareDirectionOffset = -M_PI / 4;
    CGFloat r = 0, g = 0, b = 0, a = 0;
    [self.glassTint getRed:&r green:&g blue:&b alpha:&a];
    u.materialTint = simd_make_float4(r, g, b, a);
    u.rectangleCount = 1;
    u.rectangles[0] = simd_make_float4(0, 0, self.bounds.size.width, self.bounds.size.height);
    if (self.shapes.count) {
        int n = 0;
        CGFloat H = self.bounds.size.height;
        // the shader measures from the bottom (its UVs are flipped), so the shapes are flipped too
        for (NSValue *v in self.shapes) { if (n >= 16) break; CGRect r = v.CGRectValue; u.rectangles[n++] = simd_make_float4(r.origin.x, H - CGRectGetMaxY(r), r.size.width, r.size.height); }
        u.rectangleCount = n;
    }
    memcpy(_uniforms.contents, &u, sizeof(u));
}
- (void)drawRect:(CGRect)rect {
    if (!self.window || self.bounds.size.width < 4) return;
    [self setupBuffer];
    @try { [self capture]; } @catch (__unused id e) {}
    [self updateUniforms];
    id<CAMetalDrawable> drawable = self.currentDrawable;
    MTLRenderPassDescriptor *rp = self.currentRenderPassDescriptor;
    if (!drawable || !rp) return;
    id<MTLCommandBuffer> cb = [_queue commandBuffer];
    [self blurBG:cb];
    id<MTLRenderCommandEncoder> enc = [cb renderCommandEncoderWithDescriptor:rp];
    [enc setRenderPipelineState:gLGPipeline];
    [enc setFragmentBuffer:_uniforms offset:0 atIndex:0];
    if (_bg) [enc setFragmentTexture:_bg atIndex:0];
    [enc drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [enc endEncoding];
    [cb presentDrawable:drawable];
    [cb commit];
}
@end

// 1.6.6: with LiquidAss installed, the clear glass IS LiquidAss's tab bar glass (its LGLiveBackdropView with the
// tab bar filter). That's rendered by the system itself, so it's as smooth as the tab bar. Our Metal glass above
// is only used without LiquidAss.
#import <objc/message.h>
static NSString *const kMPTabFilter = @"dylv.liquidglass.tabbar";
#include "../shared/NanoGlass.h"
// LiquidAss's glass whenever LiquidAss is installed
static Class MPLGClass(void) { return NGClass(); }
static BOOL MPIsLGGlass(UIView *v) { return [v.accessibilityIdentifier isEqualToString:@"nano.glass"]; }
static UIView *MPLGMake(CGRect f) {
    Class c = MPLGClass(); if (!c) return nil;
    UIView *v = nil;
    @try { v = ((id (*)(id, SEL, CGRect, id, id))objc_msgSend)([c alloc], NSSelectorFromString(@"initWithFrame:groupName:filterType:"), f, nil, kMPTabFilter); }
    @catch (__unused id e) { v = nil; }
    if (!v) return nil;
    v.userInteractionEnabled = NO;
    v.accessibilityIdentifier = @"nano.glass";   // ours: LiquidAss compatibility leaves it alone
    v.layer.masksToBounds = YES;
    if (@available(iOS 13.0, *)) v.layer.cornerCurve = kCACornerCurveContinuous;
    return v;
}
static void MPLGFit(UIView *v, CGRect f, CGFloat radius) {
    if (!v) return;
    BOOL rc = fabs(v.layer.cornerRadius - radius) > 0.25;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    if (!CGRectEqualToRect(v.frame, f)) v.frame = f;
    if (rc) v.layer.cornerRadius = radius;
    [CATransaction commit];
    @try {
        if ([v respondsToSelector:NSSelectorFromString(@"applyFilters")]) ((void (*)(id, SEL))objc_msgSend)(v, NSSelectorFromString(@"applyFilters"));
        if (rc && [v respondsToSelector:NSSelectorFromString(@"updateSpecular")]) ((void (*)(id, SEL))objc_msgSend)(v, NSSelectorFromString(@"updateSpecular"));
    } @catch (__unused id e) {}
}

// 1.6.7: one look for every glass: the tab bar glass, getting blurrier (frosted) and a little tinted as the
// Pill Glass slider goes toward tinted. Blur and tint live inside the glass view, under its edge and shine.
#define MPLG_BLUR_TAG 0x4D504C42
#define MPLG_TINT_TAG 0x4D504C54
static void MPLGStyle(UIView *lgv, CGFloat t, BOOL light) {
    if (!lgv) return;
    t = MAX(0, MIN(1, t));
    CGRect b = lgv.bounds; CGFloat r = lgv.layer.cornerRadius;
    UIView *bl = nil, *tn = nil;
    for (UIView *v in lgv.subviews) { if (v.tag == MPLG_BLUR_TAG) bl = v; else if (v.tag == MPLG_TINT_TAG) tn = v; }
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    CGFloat br = round(18 * t * 2) / 2;
    if (br >= 0.5) {
        if (!bl) {
            bl = [[MPLGBackdrop alloc] initWithFrame:b]; bl.tag = MPLG_BLUR_TAG;
            bl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [lgv insertSubview:bl atIndex:0];
            @try { [bl.layer setValue:@0.5 forKey:@"scale"]; } @catch (__unused id e) {}
        }
        NSNumber *was = [bl.layer valueForKey:@"mpBr"];
        if (!was || fabs(was.doubleValue - br) > 0.01) {
            @try {
                Class F = NSClassFromString(@"CAFilter");
                id f = ((id (*)(id, SEL, NSString *))objc_msgSend)(F, NSSelectorFromString(@"filterWithType:"), @"gaussianBlur");
                [f setValue:@(br) forKey:@"inputRadius"];
                if (f) bl.layer.filters = @[f];
            } @catch (__unused id e) {}
            [bl.layer setValue:@(br) forKey:@"mpBr"];
        }
        if (!CGRectEqualToRect(bl.frame, b)) bl.frame = b;
        bl.layer.cornerRadius = r; bl.layer.masksToBounds = YES;
    } else [bl removeFromSuperview];
    CGFloat ta = (light ? 0.42 : 0.32) * t;
    if (ta > 0.01) {
        if (!tn) {
            tn = [[UIView alloc] initWithFrame:b]; tn.tag = MPLG_TINT_TAG; tn.userInteractionEnabled = NO;
            tn.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        }
        UIView *under = bl.superview ? bl : nil;
        if (tn.superview != lgv) { if (under) [lgv insertSubview:tn aboveSubview:under]; else [lgv insertSubview:tn atIndex:0]; }
        if (!CGRectEqualToRect(tn.frame, b)) tn.frame = b;
        tn.layer.cornerRadius = r;
        tn.backgroundColor = light ? [UIColor colorWithWhite:1 alpha:ta] : [UIColor colorWithWhite:0.06 alpha:ta];
    } else [tn removeFromSuperview];
    [CATransaction commit];
}
// LiquidAss's own rim and shine off (for the drop's pieces, which get one outline for the whole shape)
static void MPLGBare(UIView *lgv) {
    for (CALayer *l in lgv.layer.sublayers) if (([l isKindOfClass:[CAShapeLayer class]] || [l isKindOfClass:[CAGradientLayer class]]) && l.opacity != 0) l.opacity = 0;
}
