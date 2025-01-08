#include "metal_utils.h"

#include <Foundation/Foundation.h>
#include <Metal/Metal.h>
#include <QuartzCore/CAMetalLayer.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSBitmapImageRep.h>

namespace metal_utils {
    jlong loadMTLTextureFromPNG(const std::string &filePath) {
        // Set up a shared Metal device
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();

        if (!device) {
            NSLog(@"Unable to create Metal device.");
            return 0;
        }

        // Convert file path string to NSString
        NSString* nsFilePath = [NSString stringWithUTF8String:filePath.c_str()];

        // Load the image into an NSImage object
        NSImage* image = [[NSImage alloc] initWithContentsOfFile:nsFilePath];
        if (!image) {
            NSLog(@"Failed to load image at path: %@", nsFilePath);
            return 0;
        }
        NSLog(@"Image loaded successfully. Size: %lu x %lu", (unsigned long)image.size.width, (unsigned long)image.size.height);

        // Get Bitmap representation of the image
        NSBitmapImageRep* rep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
        if (!rep) {
            NSLog(@"Failed to create bitmap representation of the image.");
            return 0;
        }

        NSUInteger width = rep.pixelsWide;
        NSUInteger height = rep.pixelsHigh;

        // Describe the texture and set its properties
        MTLTextureDescriptor* textureDescriptor = [[MTLTextureDescriptor alloc] init];
        textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
        textureDescriptor.width = width;
        textureDescriptor.height = height;
        textureDescriptor.usage = MTLTextureUsageShaderRead;

        // Create the Metal texture
        id<MTLTexture> texture = [device newTextureWithDescriptor:textureDescriptor];
        if (!texture) {
            NSLog(@"Failed to create Metal texture.");
            return 0;
        }

        // Calculate the aligned bytesPerRow
        NSUInteger bytesPerPixel = 4; // BGRA8Unorm format (4 bytes per pixel)
        NSUInteger usedBytesPerRow = width * bytesPerPixel;
        NSUInteger alignedBytesPerRow = ((usedBytesPerRow + 255) / 256) * 256; // Align to 256 bytes

        // Allocate a new buffer with correct alignment
        NSUInteger dataSize = alignedBytesPerRow * height;
        void* alignedData = malloc(dataSize);
        if (!alignedData) {
            NSLog(@"Failed to allocate memory for aligned texture data.");
            return 0;
        }

        // Copy the pixel data into the aligned buffer
        memset(alignedData, 0, dataSize); // Zero out padding bytes
        const void* pixels = [rep bitmapData];
        for (NSUInteger row = 0; row < height; row++) {
            memcpy((void*)((char*)alignedData + row * alignedBytesPerRow),           // Destination address
                   (void*)((char*)pixels + row * rep.bytesPerRow),                   // Source address
                   usedBytesPerRow);                                                 // Copy only the usable bytes
        }

        // Replace the Metal texture region with the aligned pixel data
        [texture replaceRegion:MTLRegionMake2D(0, 0, width, height)
                   mipmapLevel:0
                     withBytes:alignedData
                   bytesPerRow:alignedBytesPerRow];

        // Free the temporary buffer
        free(alignedData);

        NSLog(@"Texture created successfully.");
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
            return nullptr; // Invalid texture pointer
        }

        id<MTLTexture> texture = reinterpret_cast<id<MTLTexture>>(ptr);
        NSUInteger width = texture.width;
        NSUInteger height = texture.height;

        // Verifying pixel format
        if (texture.pixelFormat != MTLPixelFormatBGRA8Unorm) {
            NSLog(@"Unsupported Metal texture format.");
            return nullptr;
        }

        NSUInteger bytesPerPixel = 4; // BGRA has 4 bytes per pixel
        NSUInteger usedBytesPerRow = width * bytesPerPixel;

        // Align bytesPerRow to Metal's requirements (aligned to 256 bytes)
        NSUInteger alignedBytesPerRow = ((usedBytesPerRow + 255) & ~255);

        NSUInteger dataSize = alignedBytesPerRow * height; // Compute total size

        // Allocate aligned memory for texture data
        void* textureData = malloc(dataSize);
        if (!textureData) {
            NSLog(@"Failed to allocate memory for texture data.");
            return nullptr;
        }

        // Filling the unused padding bytes to zero
        memset(textureData, 0, dataSize);

        // Metal region to read from
        MTLRegion region = MTLRegionMake2D(0, 0, width, height);

        // Read texture into the allocated buffer
        [texture getBytes:textureData bytesPerRow:alignedBytesPerRow fromRegion:region mipmapLevel:0];

        // Create a Java byte array to pass to Java
        jbyteArray byteArray = env->NewByteArray(usedBytesPerRow * height);
        if (byteArray == nullptr) {
            NSLog(@"Failed to create Java byte array.");
            free(textureData);
            return nullptr;
        }

        env->SetByteArrayRegion(byteArray, 0, usedBytesPerRow * height, (jbyte*)textureData);

        // Free the allocated memory
        free(textureData);

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
