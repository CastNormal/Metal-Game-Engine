import simd

func ProjectionMatrix(near: Float, far: Float, fov: Float, aspect_ratio: Float) -> simd_float4x4 {
    
    let rFov = 1/tan((fov * 0.5) * (.pi / 180));
        
    let m1: Float = rFov / aspect_ratio;
    let m2: Float = rFov;
    let m3: Float = far / (near - far);
    let m4: Float = (far * near) / (near - far);

    return simd_float4x4(
        SIMD4<Float>(m1,  0,  0,  0),
        SIMD4<Float>( 0, m2,  0,  0),
        SIMD4<Float>( 0,  0, m3, -1),
        SIMD4<Float>( 0,  0, m4,  0)
    )
}

func normalMatrix(modelMatrix: simd_float4x4) -> simd_float3x3 {

    let matrix = simd_float3x3(columns: (
        SIMD3<Float>(
            modelMatrix.columns.0.x,
            modelMatrix.columns.0.y,
            modelMatrix.columns.0.z
        ),
        SIMD3<Float>(
            modelMatrix.columns.1.x,
            modelMatrix.columns.1.y,
            modelMatrix.columns.1.z
        ),
        SIMD3<Float>(
            modelMatrix.columns.2.x,
            modelMatrix.columns.2.y,
            modelMatrix.columns.2.z
        )
    ))

    return simd_transpose(simd_inverse(matrix))
}

func modelMatrix(instance: ObjectInstance) -> simd_float4x4 {

    var translation = matrix_identity_float4x4

    translation.columns.3 = SIMD4<Float>(instance.position, 1)

    let rotationX = simd_float4x4(simd_quatf(angle: instance.rotation.x, axis: SIMD3<Float>(1, 0, 0)))

    let rotationY = simd_float4x4(simd_quatf(angle: instance.rotation.y,axis: SIMD3<Float>(0, 1, 0)))

    let rotationZ = simd_float4x4(simd_quatf(angle: instance.rotation.z,axis: SIMD3<Float>(0, 0, 1)))

    let scale = simd_float4x4(diagonal: SIMD4<Float>(instance.scale, 1))

    return translation * rotationZ * rotationY * rotationX * scale
}

func FPSview(eye: simd_float3, pitch: Float, yaw: Float) -> simd_float4x4 {
    let sinPitch = sin(pitch);
    let cosPitch = cos(pitch);
    
    let sinYaw = sin(yaw);
    let cosYaw = cos(yaw);
    
    let xaxis = simd_float3(cosYaw, 0, -sinYaw)
    let yaxis = simd_float3(sinYaw * sinPitch, cosPitch, cosYaw * sinPitch)
    let zaxis = simd_float3(sinYaw * cosPitch, -sinPitch, cosPitch * cosYaw)
    
    return simd_float4x4(columns: (
        SIMD4<Float>(xaxis.x, yaxis.x, zaxis.x, 0),
        SIMD4<Float>(xaxis.y, yaxis.y, zaxis.y, 0),
        SIMD4<Float>(xaxis.z, yaxis.z, zaxis.z, 0),
        SIMD4<Float>(-dot(xaxis, eye), -dot(yaxis, eye), -dot(zaxis, eye), 1)
    ))
}
