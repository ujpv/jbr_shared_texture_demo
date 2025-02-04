#include "metal_utils.h"

#include <Foundation/Foundation.h>
#include <Metal/Metal.h>
#include <MetalKit/MetalKit.h>
#include <MetalPerformanceShaders/MetalPerformanceShaders.h>
#include <QuartzCore/CAMetalLayer.h>
#include <AppKit/NSBitmapImageRep.h>

#include <OpenGL/gl3.h>
#include <IOSurface/IOSurface.h>

namespace platform_utils {
    jboolean renderTriangleToMTLTexture(jlong pTexture) {
        NSLog(@"Starting renderTriangleToMTLTexture with texture handle: %lu", (unsigned long)pTexture);

        // Verify the texture pointer
        if (!pTexture) {
            NSLog(@"Invalid texture pointer provided.");
            return JNI_FALSE; // Failure
        }

        // Cast the jlong texture pointer to id<MTLTexture>
        id<MTLTexture> texture = (__bridge id<MTLTexture>)((void*)pTexture);

        // Create a Metal device
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) {
            NSLog(@"Metal is not supported on this device.");
            return JNI_FALSE; // Failure
        }

        // Create a command queue
        id<MTLCommandQueue> commandQueue = [device newCommandQueue];
        if (!commandQueue) {
            NSLog(@"Failed to create command queue.");
            return JNI_FALSE; // Failure
        }

        // Create a render pass descriptor
        MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        if (!passDescriptor) {
            NSLog(@"Failed to create render pass descriptor.");
            return JNI_FALSE; // Failure
        }

        // Attach the texture as the color attachment
        passDescriptor.colorAttachments[0].texture = texture;
        passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;

        // Set clear color with transparency (alpha channel = 0 for transparency)
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0); // RGBA: fully transparent
        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

        // Start a new command buffer
        id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
        if (!commandBuffer) {
            NSLog(@"Failed to create command buffer.");
            return JNI_FALSE; // Failure
        }

        // Create a render command encoder
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
        if (!renderEncoder) {
            NSLog(@"Failed to create render command encoder.");
            return JNI_FALSE; // Failure
        }

        // Setup shaders, vertex data, and render a triangle
        {
            // Metal shader source code
            NSString *shaderSource = @"\
            #include <metal_stdlib>\n\
            using namespace metal;\n\
            struct Vertex {\n\
                float4 position [[position]];\n\
                float4 color;\n\
            };\n\
            vertex Vertex vertex_main(const device float4* vertices [[ buffer(0) ]], uint vertexID [[ vertex_id ]]) {\n\
                Vertex out;\n\
                out.position = vertices[vertexID];\n\
                out.color = float4(vertices[vertexID].xyz, 1.0);\n\
                return out;\n\
            }\n\
            fragment float4 fragment_main(Vertex in [[stage_in]]) {\n\
                return in.color;\n\
            }";

            // Compile the shader library
            NSError *error = nil;
            id<MTLLibrary> library = [device newLibraryWithSource:shaderSource options:nil error:&error];
            if (!library) {
                NSLog(@"Failed to compile shaders: %@", error.localizedDescription);
                [renderEncoder endEncoding];
                return JNI_FALSE; // Failure
            }

            // Create render pipeline descriptor
            MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
            pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertex_main"];
            pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_main"];
            pipelineDescriptor.colorAttachments[0].pixelFormat = texture.pixelFormat;

            // Create render pipeline state
            id<MTLRenderPipelineState> pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
            if (!pipelineState) {
                NSLog(@"Failed to create pipeline state: %@", error.localizedDescription);
                [renderEncoder endEncoding];
                return JNI_FALSE; // Failure
            }

            // Set the pipeline state
            [renderEncoder setRenderPipelineState:pipelineState];

            // Define vertex data for a triangle
            const float vertexData[] = {
                0.0f,  1.0f, 0.0f, 1.0f, // Top vertex
               -1.0f, -1.0f, 0.0f, 1.0f, // Bottom-left vertex
                1.0f, -1.0f, 0.0f, 1.0f  // Bottom-right vertex
            };

            // Create a Metal buffer for the vertex data
            id<MTLBuffer> vertexBuffer = [device newBufferWithBytes:vertexData length:sizeof(vertexData) options:MTLResourceStorageModeShared];

            // Bind the vertex buffer
            [renderEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];

            // Draw the triangle
            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        }

        // Finalize rendering
        [renderEncoder endEncoding];

        // Commit the command buffer and wait for completion
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];

        // Successful completion
        return JNI_TRUE;
    }


}
