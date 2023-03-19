import MetalKit
import ModelIO

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
    
    let device: MTLDevice!
    let commandQueue: MTLCommandQueue!
    let pipelineState: MTLRenderPipelineState!
    var camera: Camera
    var scene: Scene
    var key_events = [Bool].init(repeating: false, count: 160)
    var depthStencilState: MTLDepthStencilState
    
    init?(mtkView: MTKView) {
        
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.depthStencilPixelFormat = .depth32Float
        //represents the gpu
        device = mtkView.device
        //keeps track of MTLCommandBuffers
        commandQueue = device.makeCommandQueue()
                
        camera = Camera(position: vector_float3(x: 0, y: 0, z: 0), orientation: vector_float3(x: 0, y: 0, z: 0), fov: 60)
        
        
        
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
            specularColor: SIMD3<Float>(1, 1, 1),
            specularPower: Float(1),
            light0: Light(worldPosition: SIMD3<Float>( 5,  5, 0), color: SIMD3<Float>(0.3, 0.3, 0.3)),
            light1: Light(worldPosition: SIMD3<Float>(-5,  5, 0), color: SIMD3<Float>(0.3, 0.3, 0.3)),
            light2: Light(worldPosition: SIMD3<Float>( 0,  5, 0), color: SIMD3<Float>(0.3, 0.3, 0.3)))
    
        renderEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.size, index: 0)
        
            //for mesh in meshes {
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
        renderEncoder.endEncoding()
    }

    func draw(in view: MTKView) {
        
        let delta = 1 / Float(view.preferredFramesPerSecond)
        
        //camera.orientation.z = time / 10
        //mesh_rotation.y += 0.5
        
        let sx = sin(camera.orientation.x) * delta
        let cx = cos(camera.orientation.x) * delta
        
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
                }
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
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
