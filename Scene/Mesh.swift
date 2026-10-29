import MetalKit

struct AABB {
    var center: SIMD3<Float>
    var extents: SIMD3<Float> //half widths
    
    init(asset : MDLAsset) {
        center = (asset.boundingBox.maxBounds + asset.boundingBox.minBounds) * 0.5
        extents = (asset.boundingBox.maxBounds + asset.boundingBox.minBounds) * 0.5
    }
}

struct ObjectInstance {
    public var position: vector_float3
    public var rotation: vector_float3
    public var scale: vector_float3
}

class Object {
    public var mesh: MTKMesh
    public var AABB: AABB
    public var texture_id: Int
    public var instances: [ObjectInstance] = []
    public var instances_uniform: [Uniforms] = []
    public var shared_uniform = sharedUniforms()
    
    func add_instance(position: vector_float3, rotation: vector_float3, scale: vector_float3) {
        instances.append(ObjectInstance(position: position, rotation: rotation, scale: scale))
    }
    
    init(mesh: MTKMesh, AABB: AABB, texture_id: Int) {
        self.mesh = mesh
        self.texture_id = texture_id
        self.AABB = AABB
    }
}

class Texture {
    var texture: MTLTexture
    var sampler: MTLSamplerState
    
    init(device: MTLDevice, file_name: String, file_extension: String) {
        let loader = MTKTextureLoader(device: device)
        let url = Bundle.main.url(forResource: file_name, withExtension: file_extension)!
        texture = try! loader.newTexture(URL: url, options: nil)

        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.normalizedCoordinates = true
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        sampler = device.makeSamplerState(descriptor: samplerDescriptor)!
    }
}
