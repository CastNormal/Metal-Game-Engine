import MetalKit

struct Light {
    var worldPosition = SIMD3<Float>(0, 0, 0)
    var color = SIMD3<Float>(0, 0, 0)
}

struct FragmentUniforms {
    var cameraWorldPosition = SIMD3<Float>(0, 0, 0)
    var ambientLightColor = SIMD3<Float>(0, 0, 0)
    var specularColor = SIMD3<Float>(1, 1, 1)
    var specularPower = Float(16)

    var light0 = Light()
    var light1 = Light()
    var light2 = Light()
}
