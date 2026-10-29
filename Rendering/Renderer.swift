
import MetalKit
import ModelIO
import GameController
import QuartzCore
import simd

@available(macOS 26.4, *)
class Renderer : NSObject, MTKViewDelegate {

    let device: MTLDevice
    let commandQueue: MTL4CommandQueue
    let commandBuffer: MTL4CommandBuffer
    let commandAllocators: [MTL4CommandAllocator]
    let cameraController = CameraController()
    private var lastFrameTime: CFTimeInterval?

    let scene: Scene
    let residencySet: MTLResidencySet

    private static let maxFramesInFlight = 3

    let vertexArgumentTable: MTL4ArgumentTable
    let fragmentArgumentTable: MTL4ArgumentTable

    var pipelineState: MTLRenderPipelineState
    let depthStencilState: MTLDepthStencilState

    let sharedUniformBuffers: [MTLBuffer]
    let instanceUniformBuffers: [MTLBuffer]
    let fragmentUniformBuffers: [MTLBuffer]

    let sharedEvent: MTLSharedEvent
    private var frameNumber: Int = 0


    static func inscribeResidencySet(device: MTLDevice, scene: Scene, sharedUniformBuffers: [MTLBuffer], instanceUniformBuffers: [MTLBuffer], fragmentUniformBuffers: [MTLBuffer]) -> MTLResidencySet? {

        do {
            let descriptor = MTLResidencySetDescriptor()
            descriptor.label = "EngineWorldTexturesSet"
            descriptor.initialCapacity = 100

            let residencySet = try device.makeResidencySet(descriptor: descriptor)

            for object in scene.objects {

                for meshBuffer in object.mesh.vertexBuffers {
                    residencySet.addAllocation(meshBuffer.buffer)
                }

                for submesh in object.mesh.submeshes {
                    residencySet.addAllocation(submesh.indexBuffer.buffer)
                }
            }

            for texture in scene.textures {
                residencySet.addAllocation(texture.texture)
            }

            for buffer in sharedUniformBuffers {
                residencySet.addAllocation(buffer)
            }

            for buffer in instanceUniformBuffers {
                residencySet.addAllocation(buffer)
            }

            for buffer in fragmentUniformBuffers {
                residencySet.addAllocation(buffer)
            }

            residencySet.commit()
            return residencySet

        } catch {
            print("Could not create residency set: \(error)")
            return nil
        }
    }

    init?(view: MTKView) {

        guard let device = view.device else { return nil }

        view.depthStencilPixelFormat = .depth32Float
        view.clearDepth = 1.0

        self.device = device

        self.commandQueue = device.makeMTL4CommandQueue()!
        self.commandBuffer = device.makeCommandBuffer()!

        self.commandAllocators = (0..<Self.maxFramesInFlight).map { _ in device.makeCommandAllocator()! }

        self.scene = Scene(device: device)

        let instanceCount = max(1, scene.objects.reduce(0) { $0 + $1.instances.count })

        self.sharedUniformBuffers = (0..<Self.maxFramesInFlight).map { _ in device.makeBuffer(length: MemoryLayout<sharedUniforms>.stride, options: .storageModeShared)!}

        self.instanceUniformBuffers = (0..<Self.maxFramesInFlight).map {_ in device.makeBuffer(length: instanceCount * MemoryLayout<Uniforms>.stride, options: .storageModeShared)!}

        self.fragmentUniformBuffers = (0..<Self.maxFramesInFlight).map {_ in device.makeBuffer(length: MemoryLayout<FragmentUniforms>.stride, options: .storageModeShared)!}

        self.residencySet = Self.inscribeResidencySet(device: device, scene: scene, sharedUniformBuffers: sharedUniformBuffers, instanceUniformBuffers: instanceUniformBuffers, fragmentUniformBuffers: fragmentUniformBuffers)!

        let vertexDesc = MTL4ArgumentTableDescriptor()
        vertexDesc.maxBufferBindCount = 3

        self.vertexArgumentTable = try! device.makeArgumentTable(descriptor: vertexDesc)

        let fragmentDesc = MTL4ArgumentTableDescriptor()
        fragmentDesc.maxBufferBindCount = 1
        fragmentDesc.maxTextureBindCount = 1
        fragmentDesc.maxSamplerStateBindCount = 1

        self.fragmentArgumentTable = try! device.makeArgumentTable(descriptor: fragmentDesc)

        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true

        self.depthStencilState = device.makeDepthStencilState(descriptor: depthDescriptor)!

        self.sharedEvent = device.makeSharedEvent()!

        do {
            self.pipelineState = try Renderer.buildRenderPipelineWithDevice(
                device: device,
                metalKitView: view,
                mtlVertexDescriptor: Self.makeVertexDescriptor()
            )
        } catch {
            print("Could not create render pipeline state: \(error)")
            return nil
        }

        super.init()

        commandQueue.addResidencySet(residencySet)
        commandQueue.addResidencySet(view.residencySet)

        if let layer = view.layer as? CAMetalLayer {
            commandQueue.addResidencySet(layer.residencySet)
        }

        view.delegate = self
    }

    static func makeVertexDescriptor() -> MTLVertexDescriptor {

        let descriptor = MTLVertexDescriptor()

        // Position
        descriptor.attributes[0].format = .float3
        descriptor.attributes[0].offset = 0
        descriptor.attributes[0].bufferIndex = 0

        // Normal
        descriptor.attributes[1].format = .float3
        descriptor.attributes[1].offset = 12
        descriptor.attributes[1].bufferIndex = 0

        // Texture coordinates
        descriptor.attributes[2].format = .float2
        descriptor.attributes[2].offset = 24
        descriptor.attributes[2].bufferIndex = 0

        descriptor.layouts[0].stride = 32
        descriptor.layouts[0].stepFunction = .perVertex
        descriptor.layouts[0].stepRate = 1

        return descriptor
    }

    class func buildRenderPipelineWithDevice(device: MTLDevice, metalKitView: MTKView, mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {

        let library = device.makeDefaultLibrary()

        let compiler = try device.makeCompiler(
            descriptor: MTL4CompilerDescriptor()
        )

        let vertexFunctionDescriptor = MTL4LibraryFunctionDescriptor()
        vertexFunctionDescriptor.library = library
        vertexFunctionDescriptor.name = "vertex_main"

        let fragmentFunctionDescriptor = MTL4LibraryFunctionDescriptor()
        fragmentFunctionDescriptor.library = library
        fragmentFunctionDescriptor.name = "fragment_main"

        let pipelineDescriptor = MTL4RenderPipelineDescriptor()

        pipelineDescriptor.label = "RenderPipeline"
        pipelineDescriptor.rasterSampleCount = metalKitView.sampleCount

        pipelineDescriptor.vertexFunctionDescriptor = vertexFunctionDescriptor

        pipelineDescriptor.fragmentFunctionDescriptor = fragmentFunctionDescriptor

        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor

        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat

        return try compiler.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }


    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }

    func isFrameSlotAvailable(_ frameIndex: Int) -> Bool {

        if frameNumber < Self.maxFramesInFlight { return true }

        let requiredValue = UInt64(frameNumber - Self.maxFramesInFlight + 1)

        return sharedEvent.signaledValue >= requiredValue
    }
    
    func updateCamera(view: MTKView) {
        let currentTime = CACurrentMediaTime()

        let deltaTime: Float

        if let lastFrameTime {
            deltaTime = min(Float(currentTime - lastFrameTime), 0.05)
        } else {
            deltaTime = 0
        }

        lastFrameTime = currentTime

        if let inputView = view as? InputView {
            cameraController.update(camera: scene.camera, input: inputView.input,deltaTime: deltaTime)
        }
    }
    
    func updateSharedUniforms(frameIndex: Int, view: MTKView) {
        let sharedBuffer = sharedUniformBuffers[frameIndex]

        var sharedUniform = sharedUniforms()

        let aspectRatio = Float(view.drawableSize.width / view.drawableSize.height)

        sharedUniform.viewMat = scene.camera.getViewMatrix()
        sharedUniform.projMat = scene.camera.getProjectionMatrix(aspectRatio: aspectRatio)
        
        sharedBuffer.contents().assumingMemoryBound(to: sharedUniforms.self).pointee = sharedUniform
    }
    
    func updateFragmentUniforms(frameIndex: Int) {
        let fragmentBuffer = fragmentUniformBuffers[frameIndex]

        var fragmentUniform = FragmentUniforms()

        fragmentUniform.cameraWorldPosition = scene.camera.position
        fragmentUniform.ambientLightColor = SIMD3<Float>(0.15, 0.15, 0.15)

        fragmentUniform.specularColor = SIMD3<Float>(1, 1, 1)
        fragmentUniform.specularPower = 16

        fragmentUniform.light0.worldPosition = SIMD3<Float>(3, 5, 5)
        fragmentUniform.light0.color = SIMD3<Float>(1, 1, 1)

        fragmentUniform.light1.worldPosition = SIMD3<Float>(-4, 2, 1)
        fragmentUniform.light1.color = SIMD3<Float>(0.4, 0.4, 0.5)

        fragmentUniform.light2.worldPosition = SIMD3<Float>(0, -3, 2)
        fragmentUniform.light2.color = SIMD3<Float>(0.2, 0.2, 0.2)

        fragmentBuffer.contents().assumingMemoryBound(to: FragmentUniforms.self).pointee = fragmentUniform
    }
    
    func updateInstanceUniforms(frameIndex: Int) {
        let instanceBuffer = instanceUniformBuffers[frameIndex]

        let instancePointer = instanceBuffer.contents().bindMemory(to: Uniforms.self, capacity: instanceBuffer.length / MemoryLayout<Uniforms>.stride)

        var instanceIndex = 0

        for object in scene.objects {

            for instance in object.instances {

                var uniform = Uniforms()

                let modelMatrix = modelMatrix(instance: instance)
                uniform.worldMat = modelMatrix
                uniform.normMat = normalMatrix(modelMatrix: modelMatrix)

                instancePointer[instanceIndex] = uniform
                instanceIndex += 1
            }
        }
    }
    
    private func configureRenderEncoder(encoder: MTL4RenderCommandEncoder, view: MTKView, frameIndex: Int) {
        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthStencilState)

        encoder.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(view.drawableSize.width), height: Double(view.drawableSize.height), znear: 0, zfar: 1))

        vertexArgumentTable.setAddress(sharedUniformBuffers[frameIndex].gpuAddress, index: 1)
        fragmentArgumentTable.setAddress(fragmentUniformBuffers[frameIndex].gpuAddress, index: 0)

        encoder.setArgumentTable(vertexArgumentTable, stages: .vertex)
        encoder.setArgumentTable(fragmentArgumentTable, stages: .fragment)
    }
    
    func encode(encoder: MTL4RenderCommandEncoder, frameIndex: Int) {
        var instanceIndex = 0
        let instanceBuffer = instanceUniformBuffers[frameIndex]
        
        for object in scene.objects {
    
            if object.instances.isEmpty { continue }

            let vertexBuffer = object.mesh.vertexBuffers[0]

            vertexArgumentTable.setAddress(vertexBuffer.buffer.gpuAddress + UInt64(vertexBuffer.offset), index: 0)

            let instanceOffset = instanceIndex * MemoryLayout<Uniforms>.stride

            vertexArgumentTable.setAddress(instanceBuffer.gpuAddress + UInt64(instanceOffset), index: 2)

            let texture = scene.textures[object.texture_id]

            fragmentArgumentTable.setTexture(texture.texture.gpuResourceID, index: 0)

            fragmentArgumentTable.setSamplerState(texture.sampler.gpuResourceID, index: 0)

            for submesh in object.mesh.submeshes {

                encoder.drawIndexedPrimitives(
                    primitiveType: submesh.primitiveType,
                    indexCount: submesh.indexCount,
                    indexType: submesh.indexType,
                    indexBuffer: submesh.indexBuffer.buffer.gpuAddress +
                        UInt64(submesh.indexBuffer.offset),
                    indexBufferLength: submesh.indexBuffer.length,
                    instanceCount: object.instances.count
                )
            }

            instanceIndex += object.instances.count
        }
    }

    func draw(in view: MTKView) {
        updateCamera(view: view)

        let frameIndex = frameNumber % Self.maxFramesInFlight
        let allocator = commandAllocators[frameIndex]

        guard isFrameSlotAvailable(frameIndex) else {
            return
        }

        guard view.drawableSize.width > 0, view.drawableSize.height > 0,
              let passDescriptor = view.currentMTL4RenderPassDescriptor,
              let drawable = view.currentDrawable
        else {
            return
        }

        updateSharedUniforms(frameIndex: frameIndex, view: view)
        updateFragmentUniforms(frameIndex: frameIndex)
        updateInstanceUniforms(frameIndex: frameIndex)

        allocator.reset()
        commandBuffer.beginCommandBuffer(allocator: allocator)

        guard let encoder = commandBuffer.makeRenderCommandEncoder(
            descriptor: passDescriptor
        ) else {
            commandBuffer.endCommandBuffer()
            return
        }
        
        configureRenderEncoder(encoder: encoder, view: view, frameIndex: frameIndex)

        encode(encoder: encoder, frameIndex: frameIndex)

        encoder.endEncoding()
        commandBuffer.endCommandBuffer()

        commandQueue.waitForDrawable(drawable)
        commandQueue.commit([commandBuffer])
        commandQueue.signalDrawable(drawable)

        drawable.present()

        commandQueue.signalEvent(sharedEvent, value: UInt64(frameNumber + 1))

        frameNumber += 1
    }
}
