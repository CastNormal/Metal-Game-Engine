//
//  Collision.h
//  Game Engine Metal
//
//  Created by Sebastian Arrieta Geagea on 2023-05-22.
//

#ifndef Collision_h
#define Collision_h

#include "Shapes.h"
#include <stdio.h>

void broad_phase() {
    
}

void narrow_phase() {
    
}

int sphereCollision(struct Sphere_Rigid_Body *c1, struct Sphere_Rigid_Body *c2) {
    if (simd_distance_squared(c1->position, c2->position) < (c1->radius + c2->radius) * (c1->radius + c2->radius)) {
        printf("collision");
    }
    return 0;
}

#endif /* Collision_h */
