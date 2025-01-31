#include "metal_utils.h"

#include <Foundation/Foundation.h>
#include <Metal/Metal.h>
#include <MetalKit//MetalKit.h>
#include <MetalPerformanceShaders/MetalPerformanceShaders.h>
#include <QuartzCore/CAMetalLayer.h>
#include <AppKit/NSBitmapImageRep.h>

namespace metal_utils {
    jlong loadMTLTextureFromPNG(const std::string &filePath) {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) {
            NSLog(@"Unable to create Metal device.");
            return 0;
        }

        MTKTextureLoader* textureLoader = [[MTKTextureLoader alloc] initWithDevice:device];
        if (!textureLoader) {
            NSLog(@"Failed to create MTKTextureLoader.");
            return 0;
        }

        NSString* nsFilePath = [NSString stringWithUTF8String:filePath.c_str()];
        NSLog(@"Loading PNG from path: %@", nsFilePath);

        NSData* imageData = [NSData dataWithContentsOfFile:nsFilePath];
        if (!imageData) {
            NSLog(@"Failed to load image data from file: %@", nsFilePath);
            return 0;
        }

        // Validate PNG header
        const auto* bytes = (const unsigned char*)imageData.bytes;
        if (imageData.length < 8 || bytes[0] != 0x89 || bytes[1] != 0x50 || bytes[2] != 0x4E || bytes[3] != 0x47) {
            NSLog(@"The file is not a valid PNG. Invalid PNG header.");
            return 0;
        }
        NSLog(@"Valid PNG header detected.");

        // Use CGImageSource for image validation and loading
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, nullptr);
        if (!imageSource) {
            NSLog(@"Failed to create CGImageSource from PNG data.");
            return 0;
        }

        CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nullptr);
        CFRelease(imageSource);

        if (!cgImage) {
            NSLog(@"Failed to create CGImage from PNG data. The file may be corrupted or unsupported.");
            return 0;
        }

        NSUInteger width = CGImageGetWidth(cgImage);
        NSUInteger height = CGImageGetHeight(cgImage);
        NSLog(@"CGImage loaded successfully. Width: %lu, Height: %lu", (unsigned long)width, (unsigned long)height);

        NSDictionary* options = @{
                MTKTextureLoaderOptionSRGB : @NO, // Use linear colorspace
                MTKTextureLoaderOptionAllocateMipmaps : @NO,
                MTKTextureLoaderOptionTextureUsage : @(MTLTextureUsageShaderRead),
                MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModeShared)
        };

        NSError* error = nil;
        id<MTLTexture> texture = [textureLoader newTextureWithCGImage:cgImage
                                                              options:options
                                                                error:&error];
        CGImageRelease(cgImage);

        if (!texture || error) {
            NSLog(@"Failed to load texture: %@", error.localizedDescription);
            return 0;
        }

        NSLog(@"Texture loaded successfully. Width: %lu, Height: %lu", (unsigned long)texture.width, (unsigned long)texture.height);

        return reinterpret_cast<jlong>(texture);
    }

    void releaseMTLTexture(jlong texturePtr)  {
        auto texture = reinterpret_cast<id<MTLTexture>>(texturePtr);
        [texture release];
    }

    jbyteArray MTLTextureToByteArray(JNIEnv* env, jlong ptr) {
        if (ptr == 0) {
            NSLog(@"Invalid Metal texture pointer.");
            return nullptr; // Invalid texture pointer
        }

        auto texture = reinterpret_cast<id<MTLTexture>>(ptr);
        if (!texture) {
            NSLog(@"Metal texture pointer is nil.");
            return nullptr;
        }

        NSLog(@"Texture properties: width=%lu, height=%lu, pixelFormat=%lu",
              (unsigned long)texture.width,
              (unsigned long)texture.height,
              (unsigned long)texture.pixelFormat);

        NSUInteger width = texture.width;
        NSUInteger height = texture.height;

        if (texture.pixelFormat != MTLPixelFormatBGRA8Unorm) {
            NSLog(@"Unsupported Metal texture format.");
            return nullptr;
        }

        NSUInteger bytesPerPixel = 4; // BGRA has 4 bytes per pixel
        NSUInteger usedBytesPerRow = width * bytesPerPixel; // Actual bytes per row
        NSUInteger alignedBytesPerRow = ((usedBytesPerRow + 255) & ~255); // Aligned to 256 bytes

        NSLog(@"Bytes per row (actual): %lu, Bytes per row (aligned): %lu", (unsigned long)usedBytesPerRow, (unsigned long)alignedBytesPerRow);

        NSUInteger dataSize = alignedBytesPerRow * height; // Total buffer size (including padding)
        NSLog(@"Total texture buffer size: %lu bytes", (unsigned long)dataSize);

        // Allocate memory for the full texture data (including padding)
        void* textureData = malloc(dataSize);
        if (!textureData) {
            NSLog(@"Failed to allocate memory for texture data.");
            return nullptr;
        }

        memset(textureData, 0, dataSize);

        // Define the Metal region to read from
        MTLRegion region = MTLRegionMake2D(0, 0, width, height);
        NSLog(@"MTLRegion: origin=(%lu, %lu), size=(%lu, %lu)",
              (unsigned long)region.origin.x, (unsigned long)region.origin.y,
              (unsigned long)region.size.width, (unsigned long)region.size.height);

        if (texture.storageMode == MTLStorageModePrivate) {
            NSLog(@"The texture is in private storage mode and cannot be read.");
            free(textureData);
            return nullptr;
        }

        // Read the texture data into the allocated buffer
        [texture getBytes:textureData bytesPerRow:alignedBytesPerRow fromRegion:region mipmapLevel:0];

        // Allocate memory for the Java byte array (without padding)
        NSUInteger outputSize = usedBytesPerRow * height;
        jbyteArray byteArray = env->NewByteArray(static_cast<jint>(outputSize));
        if (!byteArray) {
            NSLog(@"Failed to create Java byte array.");
            free(textureData);
            return nullptr;
        }

        // Copy row-by-row, skipping the padding
        auto* src = (unsigned char*)textureData;
        auto* rowBuffer = (unsigned char*)malloc(usedBytesPerRow * height);
        for (NSUInteger row = 0; row < height; row++) {
            memcpy(rowBuffer + row * usedBytesPerRow, src + row * alignedBytesPerRow, usedBytesPerRow);
        }

        env->SetByteArrayRegion(byteArray, 0, static_cast<jint>(outputSize), (jbyte*)rowBuffer);

        free(textureData);
        free(rowBuffer);

        NSLog(@"Successfully transferred texture to Java byte array.");
        return byteArray;
    }

    std::pair<int, int> getMTLTextureSize(jlong ptr) {
        if (ptr == 0) {
            return {-1, -1}; // Invalid texture pointer
        }
        auto texture = reinterpret_cast<id<MTLTexture>>(ptr);
        return {texture.width, texture.height};
    }

    jlong getTextureFromVolatileImage(JNIEnv *env, jobject vi) {
        if (!vi) {
            NSLog(@"Error: VolatileImage object is null.");
            return 0;
        }

        jclass volatileImageClass = env->GetObjectClass(vi);
        if (!volatileImageClass) {
            NSLog(@"Error: Failed to retrieve VolatileImage class.");
            return 0;
        }

        jfieldID volSurfaceManagerField = env->GetFieldID(volatileImageClass, "volSurfaceManager", "Lsun/awt/image/VolatileSurfaceManager;");
        if (!volSurfaceManagerField) {
            NSLog(@"Error: Failed to find volSurfaceManager field in VolatileImage.");
            return 0;
        }

        jobject volSurfaceManager = env->GetObjectField(vi, volSurfaceManagerField);
        if (!volSurfaceManager) {
            NSLog(@"Error: volSurfaceManager is null.");
            return 0;
        }

        // Step 2: Access the `getPrimarySurfaceData` method
        jclass volSurfaceManagerClass = env->GetObjectClass(volSurfaceManager);
        if (!volSurfaceManagerClass) {
            NSLog(@"Error: Failed to retrieve VolatileSurfaceManager class.");
            return 0;
        }

        jmethodID getPrimarySurfaceDataMethod = env->GetMethodID(volSurfaceManagerClass, "getPrimarySurfaceData", "()Lsun/java2d/SurfaceData;");
        if (!getPrimarySurfaceDataMethod) {
            NSLog(@"Error: Failed to retrieve getPrimarySurfaceData method in VolatileSurfaceManager.");
            return 0;
        }

        jobject surfaceData = env->CallObjectMethod(volSurfaceManager, getPrimarySurfaceDataMethod);
        if (!surfaceData) {
            NSLog(@"Error: SurfaceData object retrieval failed.");
            return 0;
        }

        // Step 3: Retrieve the `getNativeOps` method from SurfaceData
        jclass surfaceDataClass = env->GetObjectClass(surfaceData);
        if (!surfaceDataClass) {
            NSLog(@"Error: Failed to retrieve SurfaceData class.");
            return 0;
        }

        jmethodID getNativeOpsMethod = env->GetMethodID(surfaceDataClass, "getNativeOps", "()J");
        if (!getNativeOpsMethod) {
            NSLog(@"Error: Failed to retrieve getNativeOps method.");
            return 0;
        }

        jlong nativeOpsHandle = env->CallLongMethod(surfaceData, getNativeOpsMethod);
        if (nativeOpsHandle == 0) {
            NSLog(@"Error: getNativeOps returned an invalid handle.");
            return 0;
        }

        // Step 4: Use the Java `getMTLTexturePointer` method
        // Call the SurfaceData's getMTLTexturePointer() method
        jmethodID getMTLTexturePointerMethod = env->GetMethodID(surfaceDataClass, "getMTLTexturePointer", "(J)J");
        if (!getMTLTexturePointerMethod) {
            NSLog(@"Error: Failed to retrieve getMTLTexturePointer method from SurfaceData.");
            return 0;
        }

        jlong texturePointer = env->CallLongMethod(surfaceData, getMTLTexturePointerMethod, nativeOpsHandle);
        if (!texturePointer) {
            NSLog(@"Error: getMTLTexturePointer returned an invalid Metal texture pointer.");
            return 0;
        }

        NSLog(@"Successfully retrieved Metal texture pointer: %ld", texturePointer);
        return texturePointer;
    }

    jboolean scaleTexture(jlong pSrc, jlong pDst, jdouble scale) {
        if (!pSrc || !pDst || scale <= 0.0) {
            NSLog(@"Error: Invalid inputs.");
            return JNI_FALSE;
        }

        id <MTLTexture> srcTexture = (id <MTLTexture>) pSrc;
        id <MTLTexture> dstTexture = (id <MTLTexture>) pDst;

        if (!srcTexture || !dstTexture || srcTexture.device != dstTexture.device) {
            NSLog(@"Error: Invalid Metal textures.");
            return JNI_FALSE;
        }

        NSUInteger scaledWidth = static_cast<NSUInteger>(srcTexture.width * scale);
        NSUInteger scaledHeight = static_cast<NSUInteger>(srcTexture.height * scale);
        if (scaledWidth > dstTexture.width || scaledHeight > dstTexture.height) {
            NSLog(@"Error: Destination texture is too small.");
            return JNI_FALSE;
        }


        @autoreleasepool {
            id <MTLCommandQueue> commandQueue = [[srcTexture.device newCommandQueue] autorelease];
            if (!commandQueue) {
                NSLog(@"Failed to create Metal command queue.");
                return JNI_FALSE;
            }

            id <MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
            if (!commandBuffer) {
                return JNI_FALSE;
            }

            MTLRenderPassDescriptor *descriptor = [MTLRenderPassDescriptor renderPassDescriptor];
            descriptor.colorAttachments[0].texture = dstTexture;
            descriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
            descriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
            descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);

            id <MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:descriptor];
            [encoder endEncoding];

            MPSImageLanczosScale *lanczos = [[[MPSImageLanczosScale alloc] initWithDevice:srcTexture.device] autorelease];
            MPSScaleTransform transform = {.scaleX = scale, .scaleY = scale};
            lanczos.scaleTransform = &transform;

            [lanczos encodeToCommandBuffer:commandBuffer sourceTexture:srcTexture destinationTexture:dstTexture];

            [commandBuffer commit];
            [commandBuffer waitUntilCompleted];

            if (commandBuffer.error) {
                NSLog(@"Error: Command buffer failed with error: %@", commandBuffer.error);
                return JNI_FALSE;
            }
        }


        return JNI_TRUE;
    }
}
