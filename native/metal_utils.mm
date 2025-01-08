#include "metal_utils.h"

#include <Foundation/Foundation.h>
#include <Metal/Metal.h>
#include <QuartzCore/CAMetalLayer.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSBitmapImageRep.h>

namespace metal_utils {
    jlong loadMTLTextureFromPNG(const std::string &filePath){
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

        // Get Bitmap representation of the image
        NSBitmapImageRep* rep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
        if (!rep) {
            NSLog(@"Failed to create bitmap representation of the image.");
            return 0;
        }

        // Describe the texture and set its properties
        MTLTextureDescriptor* textureDescriptor = [[MTLTextureDescriptor alloc] init];

        textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
        textureDescriptor.width = rep.pixelsWide;
        textureDescriptor.height = rep.pixelsHigh;
        textureDescriptor.usage = MTLTextureUsageShaderRead;

        // Create the texture
        id<MTLTexture> texture = [device newTextureWithDescriptor:textureDescriptor];
        if (!texture) {
            NSLog(@"Failed to create Metal texture.");
            return 0;
        }

        // Copy pixel data from the NSBitmapImageRep into the Metal texture
        NSUInteger bytesPerRow = rep.bytesPerRow;
        const void* pixels = [rep bitmapData];
        if (pixels) {
            [texture replaceRegion:MTLRegionMake2D(0, 0, textureDescriptor.width, textureDescriptor.height)
                       mipmapLevel:0
                         withBytes:pixels
                       bytesPerRow:bytesPerRow];
        } else {
            NSLog(@"Bitmap data is null.");
            return 0;
        }

        return reinterpret_cast<jlong>(texture);
    }
}
