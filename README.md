# Metal Game Engine

A work-in-progress 3D rendering engine built with **Swift**, **Metal 4**, and **MetalKit** for macOS. The project focuses on low-level graphics programming, explicit GPU resource management, and efficient rendering of instanced geometry. The next major milestone is **GPU-driven frustum culling with indirect drawing**.

## Current Features

### 3D rendering and scene management

- **Indexed, instanced rendering:** Draw multiple instances of the same mesh using a shared vertex/index buffer and per-instance transforms.
- **OBJ model loading:** Import mesh geometry with Model I/O (`MDLAsset` / `MDLMesh`) and convert it into MetalKit meshes (`MTKMesh`).
- **Submesh support:** Issue indexed draw calls for the submeshes of a loaded mesh.
- **Object transforms:** Position, rotate, and scale individual instances using model matrices and correctly transformed normal matrices.
- **Perspective camera:** View and projection matrices built with SIMD, with camera movement/look input.
- **Textured geometry:** Load image textures with `MTKTextureLoader` and sample them in the fragment shader using configurable Metal sampler state.
- **Depth testing:** Use a 32-bit floating-point depth buffer to resolve visibility between overlapping surfaces.

### Lighting and shaders

- **Custom Metal vertex and fragment shaders** for geometry transformation, texturing, and per-fragment lighting.
- **Ambient, diffuse, and Blinn–Phong specular lighting** using surface normals, light positions, and the camera position.
- **Three configurable point-light parameters** in the current lighting uniform setup.
- **Shared shader data structures** for camera and instance transformations.

### Metal 4 rendering infrastructure

- **Explicit command management** with `MTL4CommandQueue`, a reusable `MTL4CommandBuffer`, and per-frame `MTL4CommandAllocator` objects.
- **Metal 4 pipeline compilation** and separate vertex/fragment argument tables for binding buffers, textures, and samplers.
- **GPU resource residency management** for mesh buffers, textures, and uniform buffers using `MTLResidencySet`.
- **Up to three frames in flight**, with separate shared, instance, and fragment uniform buffers for each frame slot.
- **CPU–GPU synchronization** with `MTLSharedEvent` to avoid reusing frame resources before the GPU has finished with them.

## Technology Stack

- **Language:** Swift and Metal Shading Language (MSL)
- **Graphics:** Metal 4, MetalKit
- **Assets:** Model I/O
- **Platform:** macOS
- **Math:** Apple's SIMD library
- **Application framework:** AppKit / Core Animation

## Getting Started

### Requirements

- A Mac with support for the Metal 4 APIs used by the project
- **macOS 26.4 or later**, as specified by the current renderer's availability annotation
- Xcode with the corresponding macOS SDK and Metal 4 support

### Build and run

1. Clone the repository:

   ```bash
   git clone https://github.com/CastNormal/Metal-Game-Engine.git
   cd Metal-Game-Engine
   ```

2. Open the project's `.xcodeproj` file in Xcode.
3. Select the macOS application scheme and a compatible Mac as the run destination.
4. Build and run the application.

The scene is currently initialized in code. Models and textures used by the scene must be included in the application's bundled resources.

## Rendering Pipeline

The current frame is CPU-directed: the application prepares instance data and issues an indexed draw for each object's submeshes.

```text
Keyboard / Mouse Input
         |
         v
    Camera Update
         |
         v
CPU: View / Projection / Lighting / Instance Matrices
         |
         v
Triple-Buffered GPU Uniform Buffers
         |
         v
Metal 4 Render Command Encoder
         |
         v
Indexed Instanced Draws
         |
         v
Vertex Shader -> Rasterization -> Fragment Shader
         |
         v
Depth Test / Color Output -> Drawable Presentation
```

Each mesh's geometry is stored once and reused across instances. Per-instance model and normal matrices are kept in a contiguous GPU buffer, and the renderer binds the appropriate offset for each object before drawing it.

## Moving Forward: GPU Frustum Culling

The next milestone is to move **instance visibility decisions** from the CPU-directed draw path to a Metal compute pass. The goal is to avoid submitting vertex work for instances completely outside the camera frustum, without reading visibility results back to the CPU every frame.

### Planned implementation

1. **Generate mesh bounds.** Obtain each mesh's local-space axis-aligned bounding box from Model I/O. Store its center and half-extents once per mesh, rather than duplicating bounds for every instance.
2. **Build camera frustum planes.** Extract the six world-space planes from the view-projection matrix, accounting for Metal's `z` clip-space convention of `[0, 1]`.
3. **Dispatch a compute culling kernel.** Run one GPU thread per candidate instance. Combine the local bounding box with its instance world matrix and test the resulting oriented box against all six planes. Reject an instance when its box lies entirely outside any one plane.
4. **Compact visible instance IDs.** Append accepted original instance indices to a `visibleIndices` buffer using an atomic counter. Reset the counter before each dispatch.
5. **Generate indirect draw arguments on the GPU.** Write the compacted visible count into the appropriate indexed indirect-draw argument structure, removing the need for CPU readback.
6. **Render the compacted list.** Update the vertex shader to access instance transforms through `visibleIndices[instance_id]`, then replace fixed instance counts with GPU-generated indirect indexed draws.
7. **Synchronize and validate.** Ensure compute writes are visible to the indirect-argument pass and render pass; preserve per-frame buffer ownership and residency. Compare results against a CPU visibility reference, including near-plane, far-plane, camera rotation, and partially intersecting bounding boxes.
8. **Benchmark the result.** Compare the existing instanced path against GPU-culling/indirect drawing at different instance counts and visible fractions. Record GPU frame time, compute cost, and actual rendered instance counts before drawing performance conclusions.

**Status:** The current renderer uses CPU-specified instance counts. GPU frustum culling, visible-instance compaction, and indirect rendering are **planned**, not yet implemented.

## Project Status

This is an experimental graphics-engine project intended to explore Metal 4, graphics architecture, and GPU-driven rendering techniques. It is not yet a general-purpose, production-ready game engine. Features and implementation details will evolve as the rendering pipeline develops.
