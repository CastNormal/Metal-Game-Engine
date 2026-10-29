import MetalKit

class Scene {
    public var objects: [Object] = []
    public var textures: [Texture] = []
    public var lights: [Light] = []
    public var camera: Camera
    
    func add_object(device: MTLDevice, texture_id: Int, file_name: String, pos: vector_float3, rot: vector_float3, scale: vector_float3) {
        let mesh_url = Bundle.main.url(forResource: file_name, withExtension: "obj")!
        
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: MemoryLayout<Float>.size * 3, bufferIndex: 0)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: MemoryLayout<Float>.size * 6, bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)

        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(url: mesh_url, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        
        let AABB = AABB(asset: asset)

        objects.append(Object(mesh: try! MTKMesh(mesh: asset.childObjects(of: MDLMesh.self).first as! MDLMesh, device: device), AABB: AABB, texture_id: texture_id))
        objects.last?.add_instance(position: pos, rotation: rot, scale: scale)
    }
    
    init(device: MTLDevice) {
        self.camera = Camera(position: .zero, pitch: 0, yaw: 0, fov: 90)
        
        self.add_object(device: device, texture_id: 0, file_name: "cube", pos: vector_float3(0, 0, -3), rot: .zero, scale: .one)
        
        
        self.add_object(device: device, texture_id: 0, file_name: "cube", pos: vector_float3(0, 0, -3), rot: .zero, scale: .one)
        
        lights.append(Light(worldPosition: SIMD3<Float>(3, 5, 5), color: SIMD3<Float>(1, 1, 1)))
        lights.append(Light(worldPosition: SIMD3<Float>(-4, 2, 1), color: SIMD3<Float>(0.4, 0.4, 0.5)))
        lights.append(Light(worldPosition: SIMD3<Float>(0, -3, 2), color: SIMD3<Float>(0.2, 0.2, 0.2)))

        for x in 0..<100 {
            for y in 0..<100 {

                let position = vector_float3((Float(x) - 4.5) * 3, (Float(y) - 4.5) * 3, -30)

                objects[0].add_instance(position: position, rotation: .zero, scale: .one)
            }
        }

        print(objects[0].instances.count)
        
        
        self.textures.append(Texture.init(device: device, file_name: "end", file_extension: "png"))
        self.textures.append(Texture.init(device: device, file_name: "wall_texture", file_extension: "png"))
    }
}
