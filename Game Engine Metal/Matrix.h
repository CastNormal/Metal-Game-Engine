#ifndef Matrix_h
#define Matrix_h

#include <simd/simd.h>

#define PI 3.141592653589

struct Matrix4x4 {
    float mat[4][4];
};

struct sharedUniforms {
    struct Matrix4x4 projMat;
    struct Matrix4x4 viewMat;
};

struct Uniforms {
    struct Matrix4x4 worldMat;
    simd_float3x3 normMat;
};

typedef struct Matrix4x4 Matrix4x4;

float vec3_dot(vector_float3 v1, vector_float3 v2) {
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
}

vector_float4 MatVecMult(Matrix4x4 matrix, vector_float4 vector) {
    
    vector_float4 vec;
    
    vec.x = matrix.mat[0][0] * vector.x + matrix.mat[1][0] * vector.y + matrix.mat[2][0] * vector.z + matrix.mat[3][0];
    vec.y = matrix.mat[0][1] * vector.x + matrix.mat[1][1] * vector.y + matrix.mat[2][1] * vector.z + matrix.mat[3][1];
    vec.z = matrix.mat[0][2] * vector.x + matrix.mat[1][2] * vector.y + matrix.mat[2][2] * vector.z + matrix.mat[3][2];
    vec.w = matrix.mat[0][3] * vector.x + matrix.mat[1][3] * vector.y + matrix.mat[2][3] * vector.z + matrix.mat[3][3];
    
    return vec;
}

Matrix4x4 MatMult(Matrix4x4 m1, Matrix4x4 m2) {
    Matrix4x4 matrix;

    for (int c = 0; c < 4; c++) {
        for (int r = 0; r < 4; r++) {
            matrix.mat[r][c] = m1.mat[r][0] * m2.mat[0][c] + m1.mat[r][1] * m2.mat[1][c] + m1.mat[r][2] * m2.mat[2][c] + m1.mat[r][3] * m2.mat[3][c];
        }
    }
    return matrix;
}

Matrix4x4 initMatrix4x4() {
    Matrix4x4 matrix;
    
    for (int c = 0; c < 4; c++) {
        for (int r = 0; r < 4; r++) {
            matrix.mat[r][c] = 0;
        }
    }
    
    return matrix;
}

Matrix4x4 ScaleMatrix4x4(vector_float3 scale) {
    Matrix4x4 matrix = initMatrix4x4();
    
    matrix.mat[0][0] = scale.x;
    matrix.mat[1][1] = scale.y;
    matrix.mat[2][2] = scale.z;
    matrix.mat[3][3] = 1;
    
    return matrix;
}


Matrix4x4 TranslationMatrix4x4(vector_float3 translation) {
    Matrix4x4 matrix = initMatrix4x4();
    
    matrix.mat[0][0] = 1;
    matrix.mat[1][1] = 1;
    matrix.mat[2][2] = 1;
    matrix.mat[3][3] = 1;

    matrix.mat[3][0] = translation.x;
    matrix.mat[3][1] = translation.y;
    matrix.mat[3][2] = translation.z;
    
    return matrix;
}

Matrix4x4 RotationXMatrix4x4(float angle) {
    Matrix4x4 matrix = initMatrix4x4();
    
    float s = sin(angle);
    float c = cos(angle);

    matrix.mat[0][0] = 1;
    matrix.mat[1][1] = c;
    matrix.mat[1][2] = s;
    matrix.mat[2][1] = -s;
    matrix.mat[2][2] = c;
    matrix.mat[3][3] = 1;
    
    return matrix;
}

Matrix4x4 RotationYMatrix4x4(float angle) {
    Matrix4x4 matrix = initMatrix4x4();
    
    float s = sin(angle);
    float c = cos(angle);
    
    matrix.mat[0][0] = c;
    matrix.mat[0][2] = -s;
    matrix.mat[1][1] = 1;
    matrix.mat[2][0] = s;
    matrix.mat[2][2] = c;
    matrix.mat[3][3] = 1;
    
    return matrix;
}

Matrix4x4 RotationZMatrix4x4(float angle) {
    Matrix4x4 matrix = initMatrix4x4();
    
    float s = sin(angle);
    float c = cos(angle);
    
    matrix.mat[0][0] = c;
    matrix.mat[0][1] = s;
    matrix.mat[1][0] = -s;
    matrix.mat[1][1] = c;
    matrix.mat[2][2] = 1;
    matrix.mat[3][3] = 1;
    
    return matrix;
}

Matrix4x4 RotationMatrix4x4(vector_float3 angle) {
    return MatMult(MatMult(RotationYMatrix4x4(angle.y * (PI / 180)), RotationXMatrix4x4(angle.x * (PI / 180))), RotationZMatrix4x4(angle.z * (PI / 180)));
}

Matrix4x4 ProjectionMatrix(float near, float far, float fov, float aspect_ratio) {
    Matrix4x4 matrix = initMatrix4x4();
    
    float rFov = 1/tan((fov * 0.5) * (PI / 180));
        
    float m1 = aspect_ratio * rFov;
    float m2 = rFov;
    float m3 = far / (far - near);
    float m4 = -(far * near) / (far - near);

    matrix.mat[0][0] = m1;
    matrix.mat[1][1] = m2;
    matrix.mat[2][2] = m3;
    matrix.mat[2][3] = 1;
    matrix.mat[3][2] = m4;
    
    
    return matrix;
}

Matrix4x4 FPSview(vector_float3 eye, float pitch, float yaw) {
    Matrix4x4 matrix;
    
    float sinPitch = sin(pitch);
    float cosPitch = cos(pitch);
    
    float sinYaw = sin(yaw);
    float cosYaw = cos(yaw);
    
    vector_float3 xaxis;
    vector_float3 yaxis;
    vector_float3 zaxis;
    
    xaxis.x = cosYaw;
    xaxis.y = 0;
    xaxis.z = -sinYaw;
    
    yaxis.x = sinYaw * sinPitch;
    yaxis.y = cosPitch;
    yaxis.z = cosYaw * sinPitch;
    
    zaxis.x = sinYaw * cosPitch;
    zaxis.y = -sinPitch;
    zaxis.z = cosPitch * cosYaw;
    
    matrix.mat[0][0] = xaxis.x;
    matrix.mat[0][1] = yaxis.x;
    matrix.mat[0][2] = zaxis.x;
    matrix.mat[0][3] = 0;

    matrix.mat[1][0] = xaxis.y;
    matrix.mat[1][1] = yaxis.y;
    matrix.mat[1][2] = zaxis.y;
    matrix.mat[1][3] = 0;

    matrix.mat[2][0] = xaxis.z;
    matrix.mat[2][1] = yaxis.z;
    matrix.mat[2][2] = zaxis.z;
    matrix.mat[2][3] = 0;
    
    matrix.mat[3][0] = -vec3_dot(xaxis, eye);
    matrix.mat[3][1] = -vec3_dot(yaxis, eye);
    matrix.mat[3][2] = -vec3_dot(zaxis, eye);
    matrix.mat[3][3] = 1;
    
    return matrix;
}

simd_float3x3 MatrixTo3x3(Matrix4x4 m) {
    vector_float3 temp[3];
    for (int i = 0; i < 3; i++) {
        temp[i].x = m.mat[i][0];
        temp[i].y = m.mat[i][1];
        temp[i].z = m.mat[i][2];
    }
    
    simd_float3x3 matrix = {temp[0], temp[1], temp[2]};
    return matrix;
}

#endif
