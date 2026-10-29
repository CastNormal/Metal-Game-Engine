
#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

struct sharedUniforms {
    simd_float4x4 projMat;
    simd_float4x4 viewMat;
};

struct Uniforms {
    simd_float4x4 worldMat;
    simd_float3x3 normMat;
};

#endif