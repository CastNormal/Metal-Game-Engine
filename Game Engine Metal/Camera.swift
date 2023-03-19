import MetalKit

class Camera {
    var position: vector_float3
    var orientation: vector_float3
    var fov: Float
    
    init(position: vector_float3, orientation: vector_float3, fov: Float) {
        self.position = position
        self.orientation = orientation
        self.fov = fov
    }
}

