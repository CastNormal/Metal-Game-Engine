//
//  Update.h
//  Game Engine Metal
//
//  Created by Sebastian Arrieta Geagea on 2023-05-22.
//

#ifndef Update_h
#define Update_h

struct BASIC_RIGID_BODY {
    vector_float3 position;
    vector_float3 angle;
    
    vector_float3 velocity;
    vector_float3 angular_velocity;
};

struct ObjectInstance {
    vector_float3 position;
    vector_float3 rotation;
    vector_float3 scale;
};


void update_rigid_body(void *body, vector_float3 *main, float dt) {
    //printf("is_circle: %f\n", ((struct Cuboid_Rigid_Body*)body)->position.x); //if radius > 0 then it's a sphere, otherwise it's a rectangle
    
    struct BASIC_RIGID_BODY *b = (struct BASIC_RIGID_BODY*)body;
    
    b->position += b->velocity * dt;
    *main += b->velocity * dt;
    
}

#endif /* Update_h */
