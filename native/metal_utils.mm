#include "metal_utils.h"

#include <chrono>
#include <thread>

#include <Foundation/Foundation.h>
#include <Metal/Metal.h>
#include <MetalKit//MetalKit.h>
#include <QuartzCore/CAMetalLayer.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSBitmapImageRep.h>

namespace metal_utils {
//    jlong loadMTLTextureFromPNG(const std::string &filePath) {
//        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
//        if (!device) {
//            NSLog(@"Unable to create Metal device.");
//            return 0;
//        }
//
//        MTLPixelFormat targetPixelFormat = MTLPixelFormatRGBA8Unorm;
//
//        if (![device supportsTextureSampleCount:1]) {
//            NSLog(@"Device does not support 1x MSAA.");
//            return 0;
//        }
//
//        MTKTextureLoader* textureLoader = [[MTKTextureLoader alloc] initWithDevice:device];
//        if (!textureLoader) {
//            NSLog(@"Failed to create MTKTextureLoader.");
//            return 0;
//        }
//
//        NSString* nsFilePath = [NSString stringWithUTF8String:filePath.c_str()];
//
//        validatePNGFile(filePath);
//        std::this_thread::sleep_for(std::chrono::seconds (20));
//
//// Log the image details
//
//        NSData* imageData = [NSData dataWithContentsOfFile:nsFilePath];
//        if (!imageData) {
//            NSLog(@"Failed to load image data from file.");
//            return 0;
//        }
//
//        NSDictionary* options = @{
//                MTKTextureLoaderOptionSRGB : @NO, // Use linear colorspace (non-sRGB)
//                MTKTextureLoaderOptionAllocateMipmaps : @NO,
//                MTKTextureLoaderOptionTextureUsage : @(MTLTextureUsageShaderRead),
//                MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModePrivate)
//        };
//
//        NSError* error = nil;
////        id<MTLTexture> texture = [textureLoader newTextureWithContentsOfURL:[NSURL fileURLWithPath:nsFilePath]
////                                                                    options:options
////                                                                      error:&error];
//        id<MTLTexture> texture = [textureLoader newTextureWithData:imageData
//                                                           options:options
//                                                             error:&error];
//        if (!texture || error) {
//            NSLog(@"Failed to load texture: %@", error.localizedDescription);
//            return 0;
//        }
//
//        NSLog(@"Texture loaded successfully. Size: %lu x %lu", (unsigned long)texture.width, (unsigned long)texture.height);
//
//        return reinterpret_cast<jlong>(texture);
//    }
    jlong loadMTLTextureFromPNG(const std::string &filePath) {
        // Create the Metal device
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) {
            NSLog(@"Unable to create Metal device.");
            return 0;
        }

        // Create the MTKTextureLoader
        MTKTextureLoader* textureLoader = [[MTKTextureLoader alloc] initWithDevice:device];
        if (!textureLoader) {
            NSLog(@"Failed to create MTKTextureLoader.");
            return 0;
        }

        // Convert file path to NSString
        NSString* nsFilePath = [NSString stringWithUTF8String:filePath.c_str()];
        NSLog(@"Loading PNG from path: %@", nsFilePath);

        // Load PNG data
        NSData* imageData = [NSData dataWithContentsOfFile:nsFilePath];
        if (!imageData) {
            NSLog(@"Failed to load image data from file: %@", nsFilePath);
            return 0;
        }

        // Validate PNG header
        const unsigned char* bytes = (const unsigned char*)imageData.bytes;
        if (imageData.length < 8 || bytes[0] != 0x89 || bytes[1] != 0x50 || bytes[2] != 0x4E || bytes[3] != 0x47) {
            NSLog(@"The file is not a valid PNG. Invalid PNG header.");
            return 0;
        }
        NSLog(@"Valid PNG header detected.");

        // Use CGImageSource for image validation and loading
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
        if (!imageSource) {
            NSLog(@"Failed to create CGImageSource from PNG data.");
            return 0;
        }

        CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
        CFRelease(imageSource);

        if (!cgImage) {
            NSLog(@"Failed to create CGImage from PNG data. The file may be corrupted or unsupported.");
            return 0;
        }

        // Log CGImage properties
        NSUInteger width = CGImageGetWidth(cgImage);
        NSUInteger height = CGImageGetHeight(cgImage);
        NSLog(@"CGImage loaded successfully. Width: %lu, Height: %lu", (unsigned long)width, (unsigned long)height);

        // Create texture using MTKTextureLoader
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

        // Return Metal texture
        return reinterpret_cast<jlong>(texture);
    }

    void releaseMTLTexture(jlong texturePtr)  {
        id<MTLTexture> texture = reinterpret_cast<id<MTLTexture>>(texturePtr);
        [texture release];
    }

//    jbyteArray MTLTextureToByteArray(JNIEnv *env, jlong ptr) {
//        if (ptr == 0) {
//            return nullptr; // Invalid texture pointer
//        }
//        id<MTLTexture> texture = reinterpret_cast<id<MTLTexture>>(ptr);
//
//        NSUInteger width = texture.width;
//        NSUInteger height = texture.height;
//
//        if (texture.pixelFormat != MTLPixelFormatBGRA8Unorm) {
//            NSLog(@"Unsupported pixel format.");
//            return nullptr; // Unsupported texture format
//        }
//
//        NSUInteger bytesPerPixel = 4; // BGRA format
//        NSUInteger bytesPerRow = width * bytesPerPixel;
//        NSUInteger dataSize = bytesPerRow * height;
//        void* textureData = malloc(dataSize); // Allocate memory for texture data
//
//        if (!textureData) {
//            NSLog(@"Failed to allocate memory for texture data.");
//            return nullptr; // Memory allocation failed
//        }
//
//        MTLRegion region = MTLRegionMake2D(0, 0, width, height);
//        [texture getBytes:textureData bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
//
//        NSBitmapImageRep* bitmapRep = [[NSBitmapImageRep alloc]
//                initWithBitmapDataPlanes:NULL
//                              pixelsWide:width
//                              pixelsHigh:height
//                           bitsPerSample:8
//                         samplesPerPixel:4
//                                hasAlpha:YES
//                                isPlanar:NO
//                          colorSpaceName:NSDeviceRGBColorSpace
//                            bitmapFormat:NSBitmapFormatAlphaFirst
//                             bytesPerRow:bytesPerRow
//                            bitsPerPixel:32];
//
//        if (!bitmapRep) {
//            NSLog(@"Failed to create NSBitmapImageRep.");
//            free(textureData);
//            return nullptr; // Image representation creation failed
//        }
//
//        memcpy([bitmapRep bitmapData], textureData, dataSize);
//        free(textureData);
//
//        NSImage* image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
//        [image addRepresentation:bitmapRep];
//
//        if (!image) {
//            NSLog(@"Failed to create NSImage.");
//            return nullptr; // Image creation failed
//        }
//
//        NSData* pngData = [bitmapRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
//        if (!pngData) {
//            NSLog(@"Failed to create PNG data.");
//            return nullptr; // PNG representation failed
//        }
//
//        jbyteArray byteArray = env->NewByteArray([pngData length]);
//        if (!byteArray) {
//            NSLog(@"Failed to create Java byte array.");
//            return nullptr; // Byte array creation failed
//        }
//
//        env->SetByteArrayRegion(byteArray, 0, [pngData length], (jbyte*)[pngData bytes]);
//
//        return byteArray;
//    }

// Last version
    jbyteArray MTLTextureToByteArray(JNIEnv* env, jlong ptr) {
        if (ptr == 0) {
            NSLog(@"Invalid Metal texture pointer.");
            return nullptr; // Invalid texture pointer
        }

        id<MTLTexture> texture = reinterpret_cast<id<MTLTexture>>(ptr);
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

        // Verifying pixel format
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

        // Fill the buffer with zeros (to clear unused padding rows)
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
        jbyteArray byteArray = env->NewByteArray(outputSize);
        if (!byteArray) {
            NSLog(@"Failed to create Java byte array.");
            free(textureData);
            return nullptr;
        }

        // Copy row-by-row, skipping the padding
        unsigned char* src = (unsigned char*)textureData;
        unsigned char* rowBuffer = (unsigned char*)malloc(usedBytesPerRow * height);
        for (NSUInteger row = 0; row < height; row++) {
            memcpy(rowBuffer + row * usedBytesPerRow, src + row * alignedBytesPerRow, usedBytesPerRow);
        }

        env->SetByteArrayRegion(byteArray, 0, outputSize, (jbyte*)rowBuffer);

        // Free allocated memory
        free(textureData);
        free(rowBuffer);

        NSLog(@"Successfully transferred texture to Java byte array.");
        return byteArray;
    }

//    jbyteArray MTLTextureToByteArray(JNIEnv* env, jlong ptr) {
//        if (ptr == 0) {
//            NSLog(@"Invalid texture pointer.");
//            return nullptr; // Handle invalid texture
//        }
//
//        id<MTLTexture> texture = reinterpret_cast<id<MTLTexture>>(ptr);
//
//        NSUInteger width = texture.width;
//        NSUInteger height = texture.height;
//
//        // Check if texture dimensions are valid
//        if (width == 0 || height == 0) {
//            NSLog(@"Invalid texture size: width = %lu, height = %lu", (unsigned long)width, (unsigned long)height);
//            return nullptr;
//        }
//
//        // Verify pixel format
//        if (texture.pixelFormat != MTLPixelFormatBGRA8Unorm) {
//            NSLog(@"Unsupported Metal texture format.");
//            return nullptr;
//        }
//
//        NSUInteger bytesPerPixel = 4; // BGRA8Unorm format: 4 bytes per pixel (B, G, R, A)
//        NSUInteger usedBytesPerRow = width * bytesPerPixel;
//        NSLog(@"Used bytes per row: %lu", (unsigned long)usedBytesPerRow);
//
//        // Ensure bytesPerRow aligns with Metal's requirements (multiple of 256 bytes)
//        NSUInteger alignedBytesPerRow = ((usedBytesPerRow + 255) / 256) * 256;
//        NSLog(@"Aligned bytes per row: %lu", (unsigned long)alignedBytesPerRow);
//
//        NSUInteger dataSize = alignedBytesPerRow * height; // Total size for the texture data
//
//        // Allocate memory for aligned texture data
//        void* textureData = malloc(dataSize);
//        if (!textureData) {
//            NSLog(@"Failed to allocate memory for texture data.");
//            return nullptr;
//        }
//
//        // Zero-out the memory to avoid unexpected data
//        memset(textureData, 0, dataSize);
//
//        // Define the Metal region to read from (entire texture)
//        MTLRegion region = MTLRegionMake2D(0, 0, width, height);
//
//        // Attempt to read data from the Metal texture
//        [texture getBytes:textureData bytesPerRow:alignedBytesPerRow fromRegion:region mipmapLevel:0];
//
//        // Debugging step: Check if the data contains non-zero elements
//        bool hasData = false;
//        unsigned char* dataBytes = static_cast<unsigned char*>(textureData);
//        for (NSUInteger i = 0; i < usedBytesPerRow * height; i++) {
//            if (dataBytes[i] != 0) {
//                hasData = true;
//                break;
//            }
//        }
//
//        if (!hasData) {
//            NSLog(@"No data found in the texture. It might be uninitialized or empty.");
//            free(textureData);
//            return nullptr; // Return null if no meaningful data is found
//        }
//
//        // Create a Java byte array to return the data to the Java side
//        jbyteArray byteArray = env->NewByteArray(usedBytesPerRow * height);
//        if (byteArray == nullptr) {
//            NSLog(@"Failed to create Java byte array.");
//            free(textureData);
//            return nullptr;
//        }
//
//        // Copy only the "used" bytes (excluding padding) into the Java byte array
//        env->SetByteArrayRegion(byteArray, 0, usedBytesPerRow * height, (jbyte*)textureData);
//
//        // Free allocated memory
//        free(textureData);
//
//        return byteArray;
//    }

    std::pair<int, int> getMTLTextureSize(jlong ptr) {
        if (ptr == 0) {
            return {-1, -1}; // Invalid texture pointer
        }
        id<MTLTexture> texture = reinterpret_cast<id<MTLTexture>>(ptr);
        return {texture.width, texture.height};
    }
}
