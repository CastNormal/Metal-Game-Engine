import MetalKit
import ModelIO
import GameController

struct Light {
    var worldPosition = SIMD3<Float>(0, 0, 0)
    var color = SIMD3<Float>(0, 0, 0)
}
struct FragmentUniforms {
    var cameraWorldPosition = SIMD3<Float>(0, 0, 0)
    var ambientLightColor = SIMD3<Float>(0, 0, 0)
    var specularColor = SIMD3<Float>(1, 1, 1)
    var specularPower = Float(1)
    var light0 = Light()
    var light1 = Light()
    var light2 = Light()
}

class Renderer : NSObject, MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    let device: MTLDevice!
    let commandQueue: MTLCommandQueue!
    let pipelineState: MTLRenderPipelineState!
    var camera: Camera
    var scene: Scene
    var key_events = [Bool].init(repeating: false, count: 160)
    var depthStencilState: MTLDepthStencilState
    var terrain_struct: UnsafeMutablePointer<Terrain>!
    var terrain_indexBuffer: MTLBuffer!
    var terrain_instanceBuffer: MTLBuffer!
    var terrain_descriptor: MDLVertexDescriptor!
    
    init?(mtkView: MTKView) {
        
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.depthStencilPixelFormat = .depth32Float
        //represents the gpu
        device = mtkView.device
        //keeps track of MTLCommandBuffers
        commandQueue = device.makeCommandQueue()
        
        camera = Camera(position: vector_float3(x: 0, y: 1, z: 5), orientation: vector_float3(x: 0, y: 0, z: 0), fov: 60)
        
        
        
        scene = Scene(device: device)
        
        //create own pipeline for loading shaders
        //do { pipelineState = try Renderer.buildRenderPipelineWith(device: device, metalKitView: mtkView)
        //} catch { return nil }
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        let library = device.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_main")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_main")
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(scene.objects[0].mesh.vertexDescriptor)
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        //terrain
        terrain_struct = perlin_noise_array(100, 100)
        
        let terrain_verts = Array(UnsafeBufferPointer(start: terrain_struct.pointee.verts, count: 100 * 100 * 3))
        let terrain_instances = Array(UnsafeBufferPointer(start: terrain_struct.pointee.faces, count: 99 * 99 * 3))
        
        terrain_indexBuffer = device.makeBuffer(bytes: terrain_verts, length: MemoryLayout<Float>.size * terrain_verts.count, options: .storageModeShared)
        
        terrain_instanceBuffer = device.makeBuffer(bytes: terrain_instances, length: MemoryLayout<Int32>.size * terrain_instances.count, options: .storageModeShared)
        
        terrain_descriptor = MDLVertexDescriptor()
        terrain_descriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        terrain_descriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: MemoryLayout<Float>.size * 3, bufferIndex: 0)
        terrain_descriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: MemoryLayout<Float>.size * 6, bufferIndex: 0)
        terrain_descriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)
        
    }
    
    func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor) {
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return }
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setCullMode(.front)
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setDepthStencilState(depthStencilState)
        
        var fragmentUniforms = FragmentUniforms(
            cameraWorldPosition: camera.position,
            ambientLightColor: SIMD3<Float>(0, 0, 0),
            specularColor: SIMD3<Float>(0.2, 0.2, 0.2),
            specularPower: Float(0.1),
            light0: Light(worldPosition: SIMD3<Float>( 5,  5, 0), color: SIMD3<Float>(1, 1, 1)),
            light1: Light(worldPosition: SIMD3<Float>(-5,  5, 0), color: SIMD3<Float>(1, 1, 1)),
            light2: Light(worldPosition: SIMD3<Float>( 0,  5, 0), color: SIMD3<Float>(1, 1, 1)))
        
        renderEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.size, index: 0)
        
        for i in scene.objects {
            let vertexBuffer = i.mesh.vertexBuffers.first!
            renderEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
            
            renderEncoder.setFragmentTexture(scene.textures[i.texture_id].texture, index: 0)
            renderEncoder.setFragmentSamplerState(scene.textures[i.texture_id].sampler, index: 0)
            
            renderEncoder.setVertexBytes(&i.shared_uniform, length: MemoryLayout<sharedUniforms>.stride, index: 1)
            
            renderEncoder.setVertexBytes(&i.instances_uniform, length: MemoryLayout<Uniforms>.stride * i.instances.count, index: 2)
            
            for submesh in i.mesh.submeshes {
                let indexBuffer = submesh.indexBuffer
                renderEncoder.drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: indexBuffer.buffer, indexBufferOffset: indexBuffer.offset, instanceCount: i.instances.count)
            }
        }
        
        
        //terrain
        
        renderEncoder.setVertexBuffer(terrain_indexBuffer, offset: 0, index: 1)
        
        renderEncoder.setFragmentTexture(scene.textures[0].texture, index: 0)
        renderEncoder.setFragmentSamplerState(scene.textures[0].sampler, index: 0)
        
        renderEncoder.setVertexBytes(&scene.objects[0].shared_uniform, length: MemoryLayout<sharedUniforms>.stride, index: 1)
        
        renderEncoder.setVertexBytes(&scene.objects[0].instances_uniform, length: MemoryLayout<Uniforms>.stride * scene.objects[0].instances.count, index: 2)
        
        
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: 100 * 100 * 3, indexType: .uint16, indexBuffer: terrain_instanceBuffer, indexBufferOffset: 0)
        
        renderEncoder.endEncoding()
    }
    func draw(in view: MTKView) {
        
        let delta = 1 / Float(view.preferredFramesPerSecond)
        let speed: Float = 5
        
        for i in scene.objects {
            
            let instance = UnsafeMutablePointer<SIMD3<Float>>.allocate(capacity: 1)
            instance.initialize(from: &i.instances[0].position, count: 1)
            
            withUnsafeMutablePointer(to: &i.rigid_body) { body in
                update_rigid_body(body, &i.instances[0].position, delta)
            }
            
            instance.deallocate()
        }
        
        let sx = sin(camera.orientation.x) * delta * speed
        let cx = cos(camera.orientation.x) * delta * speed
        
        if (Controller.is_controller > 0) {
            let dx = Controller.leftThumbstick_x
            let dy = Controller.leftThumbstick_y
            camera.position.x += sx * dy + cx * dx
            camera.position.z += cx * dy - sx * dx
            
            camera.orientation.x += Controller.rightThumbstick_x / 10
            camera.orientation.z -= Controller.rightThumbstick_y / 10
        }
        
        for (i, e) in key_events.enumerated() {
            if e == true {
                switch KeyboardEvents(rawValue: i) {
                case .W_key:
                    camera.position.x += sx
                    camera.position.z += cx
                case .S_key:
                    camera.position.x -= sx
                    camera.position.z -= cx
                case .A_key:
                    camera.position.x -= cx
                    camera.position.z += sx
                case .D_key:
                    camera.position.x += cx
                    camera.position.z -= sx
                case .key1: camera.orientation.z -= 0.1
                case .key2: camera.orientation.z += 0.1
                case .ArrowDown: camera.position.y -= 0.1
                case .ArrowUp: camera.position.y += 0.1
                case .none: break
                default: break
                }
            }
            
            
            let aspect_ratio = Float(view.window!.frame.height/view.window!.frame.width)
            let proj_mat = ProjectionMatrix(0.01, 100, 60, aspect_ratio)
            
            let view_mat = FPSview(camera.position, camera.orientation.z, camera.orientation.x)
            
            for i in scene.objects {
                i.instances_uniform.removeAll()
                
                for j in i.instances {
                    let world_mat = MatMult(TranslationMatrix4x4(j.position), MatMult( ScaleMatrix4x4(j.scale), RotationMatrix4x4(j.rotation)))
                    
                    i.instances_uniform.append(Uniforms(worldMat: world_mat, normMat: MatrixTo3x3(world_mat).transpose.inverse))
                }
                
                i.shared_uniform.projMat = proj_mat
                i.shared_uniform.viewMat = view_mat
            }
            //the info to be sent to the gpu (includes the render pipeline)
            let commandBuffer = commandQueue.makeCommandBuffer()!
            
            // configure interface and pipeline (not inside of pipeline)
            guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1)
            
            //prepare the vertex data and drawing commands to send to the pipeline
            
            render(commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor);
            
            commandBuffer.present(view.currentDrawable!)
            commandBuffer.commit()
        }
    }
}
