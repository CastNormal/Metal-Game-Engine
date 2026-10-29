import MetalKit
import simd

class Camera {
    var position: vector_float3
    var pitch: Float
    var yaw: Float
    var fov: Float
    var near: Float
    var far: Float
    
    init(position: vector_float3, pitch: Float, yaw: Float, fov: Float, near: Float = 0.01, far: Float = 10000.0) {
        self.position = position
        self.pitch = pitch
        self.yaw = yaw
        self.fov = fov
        self.near = near
        self.far = far
    }
    
    func getProjectionMatrix(aspectRatio: Float) -> simd_float4x4 {
        return ProjectionMatrix(near: near, far: far, fov: fov, aspect_ratio: aspectRatio)
    }
    
    func getViewMatrix() -> simd_float4x4 {
        return FPSview(eye: position, pitch: pitch, yaw: yaw)
    }
}
