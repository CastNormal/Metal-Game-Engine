#ifndef Vertex_h
#define Vertex_h

#include <simd/simd.h>

struct Vertex {
    vector_float2 texCoord;
    vector_float4 pos;
    //vector_float3 normal;
};

#endif
