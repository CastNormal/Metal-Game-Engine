#ifndef Shapes_h
#define Shapes_h

#include <simd/simd.h>
#include <stdio.h>

struct Sphere_Rigid_Body {
    vector_float3 position;
    vector_float3 angle;
    vector_float3 velocity;
    vector_float3 angular_velocity;
    
    float inertia; //moment of inertia
    float restitution;
    float radius;
};

struct Cuboid_Rigid_Body {
    vector_float3 position;
    vector_float3 angle;
    vector_float3 scale;
    
    vector_float3 velocity;
    vector_float3 angular_velocity;
    
    float inertia;
    /*vector_float3 points[] = {
        vector_float3(-1, -1, -1),
        vector_float3(1, -1, -1),
        vector_float3(1, 1, -1),
        vector_float3(-1, 1, -1),
        vector_float3(-1, -1, 1),
        vector_float3(1, -1, 1),
        vector_float3(1, 1, 1),
        vector_float3(-1, 1, 1)};*/
};

#endif /* Shapes_h */
