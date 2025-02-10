#include "metal_utils.h"

#include <Foundation/Foundation.h>
#include <Metal/Metal.h>
#include <MetalKit/MetalKit.h>
#include <MetalPerformanceShaders/MetalPerformanceShaders.h>
#include <QuartzCore/CAMetalLayer.h>
#include <ImageIO/ImageIO.h>
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

        // Set clear color with transparency (alpha = 0)
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0); // Fully transparent
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

        // Setup shaders and render pipeline
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
                out.color = float4(1.0, 0.0, 0.0, 1.0); // Red color\n\
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

            // Calculate aspect ratio to transform the triangle and center it within the texture dimensions
            float textureWidth = (float)texture.width;
            float textureHeight = (float)texture.height;
            float aspectRatio = textureWidth / textureHeight;

            // Define vertex data for a triangle (positions are scaled and centered)
            const float vertexData[] = {
                0.0f,  0.5f / aspectRatio, 0.0f, 1.0f, // Top vertex (centered at the top middle of texture)
               -0.5f, -0.5f / aspectRatio, 0.0f, 1.0f, // Bottom-left vertex
                0.5f, -0.5f / aspectRatio, 0.0f, 1.0f  // Bottom-right vertex
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

        // Completed successfully
        return JNI_TRUE;
    }

    jlong loadBitmapFromPNG(const std::string& path) {
        // Create a CFString from the file path
        CFStringRef cfPath = CFStringCreateWithCString(nullptr, path.c_str(), kCFStringEncodingUTF8);
        if (!cfPath) {
            NSLog(@"Failed to create CFString for file path.");
            return 0;
        }

        // Create a CFURL from the CFString
        CFURLRef url = CFURLCreateWithFileSystemPath(nullptr, cfPath, kCFURLPOSIXPathStyle, false);
        CFRelease(cfPath); // Release CFString as it is no longer needed
        if (!url) {
            NSLog(@"Failed to create CFURL for file path.");
            return 0;
        }

        // Create an image source from the file URL
        CGImageSourceRef imageSource = CGImageSourceCreateWithURL(url, nullptr);
        CFRelease(url); // Release CFURL as it is no longer needed
        if (!imageSource) {
            NSLog(@"Failed to create CGImageSource from URL.");
            return 0;
        }

        // Load the first image in the file (index 0)
        CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, nullptr);
        CFRelease(imageSource); // Release CGImageSource as it is no longer needed
        if (!image) {
            NSLog(@"Failed to create CGImage from image source.");
            return 0;
        }

        // Get image width, height, and bytes per row
        size_t width = CGImageGetWidth(image);
        size_t height = CGImageGetHeight(image);
        size_t bytesPerRow = width * 4; // Assuming RGBA format (4 bytes per pixel)

        // Allocate memory for the bitmap data
        void* bitmapData = malloc(bytesPerRow * height);
        if (!bitmapData) {
            NSLog(@"Failed to allocate memory for bitmap data.");
            CGImageRelease(image);
            return 0;
        }

        // Create a color space
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        if (!colorSpace) {
            NSLog(@"Failed to create color space.");
            free(bitmapData);
            CGImageRelease(image);
            return 0;
        }

        // Create a bitmap context
        CGContextRef context = CGBitmapContextCreate(bitmapData, width, height, 8, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(colorSpace); // Release color space as it is no longer needed
        if (!context) {
            NSLog(@"Failed to create CGContext.");
            free(bitmapData);
            CGImageRelease(image);
            return 0;
        }

        // Log the image dimensions
        NSLog(@"Successfully created CGContext. Image dimensions: %zu x %zu pixels", width, height);

        // Draw the image into the context to populate the bitmap data
        CGRect rect = CGRectMake(0, 0, width, height);
        CGContextDrawImage(context, rect, image);
        CGContextRelease(context); // Release the context
        CGImageRelease(image);     // Release the image

        // Log a success message
        NSLog(@"Bitmap successfully loaded from path: %s", path.c_str());

        // Return the pointer to the raw bitmap data
        return reinterpret_cast<jlong>(bitmapData);
    }

    void releaseBitmap(jlong pBitmap) {
        if (pBitmap == 0) {
            NSLog(@"releaseBitmap: Received a null pointer. Nothing to release.");
            return;
        }

        // Cast the jlong to a void* pointer
        void* bitmapData = reinterpret_cast<void*>(pBitmap);

        // Free the allocated memory
        free(bitmapData);
        NSLog(@"releaseBitmap: Bitmap memory at address %p has been successfully released.", bitmapData);
    }
}
