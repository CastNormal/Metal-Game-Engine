import MetalKit

class Scene {
    public var objects: [Object] = []
    public var textures: [Texture] = []
    
    func add_object(device: MTLDevice, texture_id: Int, file_name: String, pos: vector_float3, rot: vector_float3, scale: vector_float3) {
        let mesh_url = Bundle.main.url(forResource: file_name, withExtension: "obj")!
        
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: MemoryLayout<Float>.size * 3, bufferIndex: 0)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: MemoryLayout<Float>.size * 6, bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)

        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(url: mesh_url, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)

        objects.append(Object(mesh: try! MTKMesh(mesh: asset.childObjects(of: MDLMesh.self).first as! MDLMesh, device: device), texture_id: texture_id))
        objects.last?.add_instance(position: pos, rotation: rot, scale: scale)
        }
    
    init(device: MTLDevice) {
        //self.add_object(device: device, texture_id: 0, file_name: "utah_teapot", pos: vector_float3(x: 10, y: 0, z: 0), rot: vector_float3(repeating: 0), scale: vector_float3(repeating: 0.03))
        self.add_object(device: device, texture_id: 1, file_name: "teapot", pos: vector_float3(repeating: 0), rot: vector_float3(repeating: 0), scale: vector_float3(repeating: 1))
        
        for i in 0...4 {
            self.objects[0].instances.append(ObjectInstance(position: vector_float3(x: Float(i), y: Float(i), z: 0), rotation: vector_float3(repeating: 0), scale: vector_float3(repeating: 1)))
        }
        
        
        self.textures.append(Texture.init(device: device, file_name: "end", file_extension: "png"))
        self.textures.append(Texture.init(device: device, file_name: "board_pattern", file_extension: "png"))
        
    }
}

struct ObjectInstance {
    public var position: vector_float3
    public var rotation: vector_float3
    public var scale: vector_float3
}

class Object {
    public var mesh: MTKMesh
    public var texture_id: Int
    public var instances: [ObjectInstance] = []
    public var instances_uniform: [Uniforms] = []
    public var shared_uniform = sharedUniforms()
    
    func add_instance(position: vector_float3, rotation: vector_float3, scale: vector_float3) {
        instances.append(ObjectInstance(position: position, rotation: rotation, scale: scale))
    }
    
    init(mesh: MTKMesh, texture_id: Int) {
        self.mesh = mesh
        self.texture_id = texture_id
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
