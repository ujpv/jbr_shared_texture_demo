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
//    jlong loadMTLTextureFromPNG(JNIEnv *env, const std::string &filePath) {
//        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
//        if (!device) {
//            NSLog(@"Unable to create Metal device.");
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
//        NSLog(@"Loading PNG from path: %@", nsFilePath);
//
//        NSData* imageData = [NSData dataWithContentsOfFile:nsFilePath];
//        if (!imageData) {
//            NSLog(@"Failed to load image data from file: %@", nsFilePath);
//            return 0;
//        }
//
//        // Validate PNG header
//        const auto* bytes = (const unsigned char*)imageData.bytes;
//        if (imageData.length < 8 || bytes[0] != 0x89 || bytes[1] != 0x50 || bytes[2] != 0x4E || bytes[3] != 0x47) {
//            NSLog(@"The file is not a valid PNG. Invalid PNG header.");
//            return 0;
//        }
//        NSLog(@"Valid PNG header detected.");
//
//        // Use CGImageSource for image validation and loading
//        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, nullptr);
//        if (!imageSource) {
//            NSLog(@"Failed to create CGImageSource from PNG data.");
//            return 0;
//        }
//
//        CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nullptr);
//        CFRelease(imageSource);
//
//        if (!cgImage) {
//            NSLog(@"Failed to create CGImage from PNG data. The file may be corrupted or unsupported.");
//            return 0;
//        }
//
//        NSUInteger width = CGImageGetWidth(cgImage);
//        NSUInteger height = CGImageGetHeight(cgImage);
//        NSLog(@"CGImage loaded successfully. Width: %lu, Height: %lu", (unsigned long)width, (unsigned long)height);
//
//        NSDictionary* options = @{
//                MTKTextureLoaderOptionSRGB : @NO, // Use linear colorspace
//                MTKTextureLoaderOptionAllocateMipmaps : @NO,
//                MTKTextureLoaderOptionTextureUsage : @(MTLTextureUsageShaderRead),
//                MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModeShared)
//        };
//
//        NSError* error = nil;
//        id<MTLTexture> texture = [textureLoader newTextureWithCGImage:cgImage
//                                                              options:options
//                                                                error:&error];
//        CGImageRelease(cgImage);
//
//        if (!texture || error) {
//            NSLog(@"Failed to load texture: %@", error.localizedDescription);
//            return 0;
//        }
//
//        NSLog(@"Texture loaded successfully. Width: %lu, Height: %lu", (unsigned long)texture.width, (unsigned long)texture.height);
//
//        return reinterpret_cast<jlong>(texture);
//    }
//
//    jlong loadIOSurfaceFromPNG(JNIEnv *env, const std::string &path) {
//        // Convert C++ std::string to an NSString
//        NSString *filePath = [NSString stringWithUTF8String:path.c_str()];
//        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
//            NSLog(@"File does not exist at path: %@", filePath);
//            return 0; // Return 0 if file is not found
//        }
//
//        // Load image data using CoreGraphics
//        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
//        CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)fileURL, NULL);
//        if (!imageSource) {
//            NSLog(@"Failed to create image source.");
//            return 0;
//        }
//
//        CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
//        CFRelease(imageSource);
//        if (!image) {
//            NSLog(@"Failed to create CGImage.");
//            return 0;
//        }
//
//        // Get image dimensions
//        size_t width = CGImageGetWidth(image);
//        size_t height = CGImageGetHeight(image);
//        if (width == 0 || height == 0) {
//            NSLog(@"Image dimensions are invalid.");
//            CGImageRelease(image);
//            return 0;
//        }
//
//        // Create an IOSurface descriptor
//        NSMutableDictionary *surfaceProperties = [NSMutableDictionary dictionary];
//        [surfaceProperties setValue:@(width) forKey:(NSString *)kIOSurfaceWidth];
//        [surfaceProperties setValue:@(height) forKey:(NSString *)kIOSurfaceHeight];
//        [surfaceProperties setValue:@(4) forKey:(NSString *)kIOSurfaceBytesPerElement]; // Correct: 4 bytes (32 bits) for BGRA
//        [surfaceProperties setValue:@(width * 4) forKey:(NSString *)kIOSurfaceBytesPerRow]; // Correct: 4 bytes per pixel
//        [surfaceProperties setValue:@(kCVPixelFormatType_32BGRA) forKey:(NSString *)kIOSurfacePixelFormat];
//
//        IOSurfaceRef surface = IOSurfaceCreate((CFDictionaryRef)surfaceProperties);
//        if (!surface) {
//            NSLog(@"Failed to create IOSurface. Check descriptor properties and memory constraints.");
//            CGImageRelease(image);
//            return 0;
//        }
//
//
//        // Lock the IOSurface and copy pixel data from the CGImage
//        IOSurfaceLock(surface, kIOSurfaceLockReadOnly, NULL);
//        void *surfaceAddress = IOSurfaceGetBaseAddress(surface);
//        if (!surfaceAddress) {
//            NSLog(@"Failed to get base address of IOSurface.");
//            IOSurfaceUnlock(surface, kIOSurfaceLockReadOnly, NULL);
//            CFRelease(surface);
//            CGImageRelease(image);
//            return 0;
//        }
//
//        CGContextRef context = CGBitmapContextCreate(surfaceAddress,
//                                                     width,
//                                                     height,
//                                                     8,                      // Bits per component
//                                                     IOSurfaceGetBytesPerRow(surface),
//                                                     CGImageGetColorSpace(image),
//                                                     kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
//        if (!context) {
//            NSLog(@"Failed to create CGContext.");
//            IOSurfaceUnlock(surface, kIOSurfaceLockReadOnly, NULL);
//            CFRelease(surface);
//            CGImageRelease(image);
//            return 0;
//        }
//
//        // Draw the image into the IOSurface
//        CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
//        CGContextRelease(context);
//        IOSurfaceUnlock(surface, kIOSurfaceLockReadOnly, NULL);
//        CGImageRelease(image);
//
//        // Return the IOSurface as a jlong handle
//        return (jlong)surface;
//    }
//
//    void releaseMTLTexture(JNIEnv *env, jlong texturePtr)  {
//        auto texture = reinterpret_cast<id<MTLTexture>>(texturePtr);
//        [texture release];
//    }
//
//    jbyteArray MTLTextureToByteArray(JNIEnv* env, jlong ptr) {
//        if (ptr == 0) {
//            NSLog(@"Invalid Metal texture pointer.");
//            return nullptr; // Invalid texture pointer
//        }
//
//        auto texture = reinterpret_cast<id<MTLTexture>>(ptr);
//        if (!texture) {
//            NSLog(@"Metal texture pointer is nil.");
//            return nullptr;
//        }
//
//        NSLog(@"Texture properties: width=%lu, height=%lu, pixelFormat=%lu",
//              (unsigned long)texture.width,
//              (unsigned long)texture.height,
//              (unsigned long)texture.pixelFormat);
//
//        NSUInteger width = texture.width;
//        NSUInteger height = texture.height;
//
//        if (texture.pixelFormat != MTLPixelFormatBGRA8Unorm) {
//            NSLog(@"Unsupported Metal texture format.");
//            return nullptr;
//        }
//
//        NSUInteger bytesPerPixel = 4; // BGRA has 4 bytes per pixel
//        NSUInteger usedBytesPerRow = width * bytesPerPixel; // Actual bytes per row
//        NSUInteger alignedBytesPerRow = ((usedBytesPerRow + 255) & ~255); // Aligned to 256 bytes
//
//        NSLog(@"Bytes per row (actual): %lu, Bytes per row (aligned): %lu", (unsigned long)usedBytesPerRow, (unsigned long)alignedBytesPerRow);
//
//        NSUInteger dataSize = alignedBytesPerRow * height; // Total buffer size (including padding)
//        NSLog(@"Total texture buffer size: %lu bytes", (unsigned long)dataSize);
//
//        // Allocate memory for the full texture data (including padding)
//        void* textureData = malloc(dataSize);
//        if (!textureData) {
//            NSLog(@"Failed to allocate memory for texture data.");
//            return nullptr;
//        }
//
//        memset(textureData, 0, dataSize);
//
//        // Define the Metal region to read from
//        MTLRegion region = MTLRegionMake2D(0, 0, width, height);
//        NSLog(@"MTLRegion: origin=(%lu, %lu), size=(%lu, %lu)",
//              (unsigned long)region.origin.x, (unsigned long)region.origin.y,
//              (unsigned long)region.size.width, (unsigned long)region.size.height);
//
//        if (texture.storageMode == MTLStorageModePrivate) {
//            NSLog(@"The texture is in private storage mode and cannot be read.");
//            free(textureData);
//            return nullptr;
//        }
//
//        // Read the texture data into the allocated buffer
//        [texture getBytes:textureData bytesPerRow:alignedBytesPerRow fromRegion:region mipmapLevel:0];
//
//        // Allocate memory for the Java byte array (without padding)
//        NSUInteger outputSize = usedBytesPerRow * height;
//        jbyteArray byteArray = env->NewByteArray(static_cast<jint>(outputSize));
//        if (!byteArray) {
//            NSLog(@"Failed to create Java byte array.");
//            free(textureData);
//            return nullptr;
//        }
//
//        // Copy row-by-row, skipping the padding
//        auto* src = (unsigned char*)textureData;
//        auto* rowBuffer = (unsigned char*)malloc(usedBytesPerRow * height);
//        for (NSUInteger row = 0; row < height; row++) {
//            memcpy(rowBuffer + row * usedBytesPerRow, src + row * alignedBytesPerRow, usedBytesPerRow);
//        }
//
//        env->SetByteArrayRegion(byteArray, 0, static_cast<jint>(outputSize), (jbyte*)rowBuffer);
//
//        free(textureData);
//        free(rowBuffer);
//
//        NSLog(@"Successfully transferred texture to Java byte array.");
//        return byteArray;
//    }
//
//    std::pair<int, int> getMTLTextureSize(JNIEnv *env, jlong ptr) {
//        if (ptr == 0) {
//            return {-1, -1}; // Invalid texture pointer
//        }
//        auto texture = reinterpret_cast<id<MTLTexture>>(ptr);
//        return {texture.width, texture.height};
//    }
//
//    jlong getTextureFromVolatileImage(JNIEnv *env, jobject vi) {
//        if (!vi) {
//            NSLog(@"Error: VolatileImage object is null.");
//            return 0;
//        }
//
//        jclass volatileImageClass = env->GetObjectClass(vi);
//        if (!volatileImageClass) {
//            NSLog(@"Error: Failed to retrieve VolatileImage class.");
//            return 0;
//        }
//
//        jfieldID volSurfaceManagerField = env->GetFieldID(volatileImageClass, "volSurfaceManager", "Lsun/awt/image/VolatileSurfaceManager;");
//        if (!volSurfaceManagerField) {
//            NSLog(@"Error: Failed to find volSurfaceManager field in VolatileImage.");
//            return 0;
//        }
//
//        jobject volSurfaceManager = env->GetObjectField(vi, volSurfaceManagerField);
//        if (!volSurfaceManager) {
//            NSLog(@"Error: volSurfaceManager is null.");
//            return 0;
//        }
//
//        // Step 2: Access the `getPrimarySurfaceData` method
//        jclass volSurfaceManagerClass = env->GetObjectClass(volSurfaceManager);
//        if (!volSurfaceManagerClass) {
//            NSLog(@"Error: Failed to retrieve VolatileSurfaceManager class.");
//            return 0;
//        }
//
//        jmethodID getPrimarySurfaceDataMethod = env->GetMethodID(volSurfaceManagerClass, "getPrimarySurfaceData", "()Lsun/java2d/SurfaceData;");
//        if (!getPrimarySurfaceDataMethod) {
//            NSLog(@"Error: Failed to retrieve getPrimarySurfaceData method in VolatileSurfaceManager.");
//            return 0;
//        }
//
//        jobject surfaceData = env->CallObjectMethod(volSurfaceManager, getPrimarySurfaceDataMethod);
//        if (!surfaceData) {
//            NSLog(@"Error: SurfaceData object retrieval failed.");
//            return 0;
//        }
//
//        // Step 3: Retrieve the `getNativeOps` method from SurfaceData
//        jclass surfaceDataClass = env->GetObjectClass(surfaceData);
//        if (!surfaceDataClass) {
//            NSLog(@"Error: Failed to retrieve SurfaceData class.");
//            return 0;
//        }
//
//        jmethodID getNativeOpsMethod = env->GetMethodID(surfaceDataClass, "getNativeOps", "()J");
//        if (!getNativeOpsMethod) {
//            NSLog(@"Error: Failed to retrieve getNativeOps method.");
//            return 0;
//        }
//
//        jlong nativeOpsHandle = env->CallLongMethod(surfaceData, getNativeOpsMethod);
//        if (nativeOpsHandle == 0) {
//            NSLog(@"Error: getNativeOps returned an invalid handle.");
//            return 0;
//        }
//
//        // Step 4: Use the Java `getMTLTexturePointer` method
//        // Call the SurfaceData's getMTLTexturePointer() method
//        jmethodID getMTLTexturePointerMethod = env->GetMethodID(surfaceDataClass, "getMTLTexturePointer", "(J)J");
//        if (!getMTLTexturePointerMethod) {
//            NSLog(@"Error: Failed to retrieve getMTLTexturePointer method from SurfaceData.");
//            return 0;
//        }
//
//        jlong texturePointer = env->CallLongMethod(surfaceData, getMTLTexturePointerMethod, nativeOpsHandle);
//        if (!texturePointer) {
//            NSLog(@"Error: getMTLTexturePointer returned an invalid Metal texture pointer.");
//            return 0;
//        }
//
//        NSLog(@"Successfully retrieved Metal texture pointer: %ld", texturePointer);
//        return texturePointer;
//    }
//
//    jboolean scaleMTLTexture(JNIEnv *env, jlong pSrc, jlong pDst, jdouble scale) {
//        if (!pSrc || !pDst || scale <= 0.0) {
//            NSLog(@"Error: Invalid inputs.");
//            return JNI_FALSE;
//        }
//
//        id <MTLTexture> srcTexture = (id <MTLTexture>) pSrc;
//        id <MTLTexture> dstTexture = (id <MTLTexture>) pDst;
//
//        if (!srcTexture || !dstTexture || srcTexture.device != dstTexture.device) {
//            NSLog(@"Error: Invalid Metal textures.");
//            return JNI_FALSE;
//        }
//
//        NSUInteger scaledWidth = static_cast<NSUInteger>(srcTexture.width * scale);
//        NSUInteger scaledHeight = static_cast<NSUInteger>(srcTexture.height * scale);
//        if (scaledWidth > dstTexture.width || scaledHeight > dstTexture.height) {
//            NSLog(@"Error: Destination texture is too small.");
//            return JNI_FALSE;
//        }
//
//
//        @autoreleasepool {
//            id <MTLCommandQueue> commandQueue = [[srcTexture.device newCommandQueue] autorelease];
//            if (!commandQueue) {
//                NSLog(@"Failed to create Metal command queue.");
//                return JNI_FALSE;
//            }
//
//            id <MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
//            if (!commandBuffer) {
//                return JNI_FALSE;
//            }
//
//            MTLRenderPassDescriptor *descriptor = [MTLRenderPassDescriptor renderPassDescriptor];
//            descriptor.colorAttachments[0].texture = dstTexture;
//            descriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
//            descriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
//            descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
//
//            id <MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:descriptor];
//            [encoder endEncoding];
//
//            MPSImageLanczosScale *lanczos = [[[MPSImageLanczosScale alloc] initWithDevice:srcTexture.device] autorelease];
//            MPSScaleTransform transform = {.scaleX = scale, .scaleY = scale};
//            lanczos.scaleTransform = &transform;
//
//            [lanczos encodeToCommandBuffer:commandBuffer sourceTexture:srcTexture destinationTexture:dstTexture];
//
//            [commandBuffer commit];
//            [commandBuffer waitUntilCompleted];
//
//            if (commandBuffer.error) {
//                NSLog(@"Error: Command buffer failed with error: %@", commandBuffer.error);
//                return JNI_FALSE;
//            }
//        }
//
//        return JNI_TRUE;
//    }
//
//    jboolean copyMTLTexture(JNIEnv *env, jlong pSrc, jlong pDst) {
//        if (!pSrc || !pDst) {
//            NSLog(@"Error: Invalid texture pointers.");
//            return JNI_FALSE;
//        }
//
//        id<MTLTexture> srcTexture = (id<MTLTexture>)pSrc;
//        id<MTLTexture> dstTexture = (id<MTLTexture>)pDst;
//
//        if (!srcTexture || !dstTexture || srcTexture.device != dstTexture.device) {
//            NSLog(@"Error: Invalid Metal textures or mismatched devices.");
//            return JNI_FALSE;
//        }
//
//        @autoreleasepool {
//            id<MTLCommandQueue> commandQueue = [[srcTexture.device newCommandQueue] autorelease];
//            if (!commandQueue) {
//                NSLog(@"Error: Failed to create Metal command queue.");
//                return JNI_FALSE;
//            }
//
//            id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
//            if (!commandBuffer) {
//                NSLog(@"Error: Failed to create Metal command buffer.");
//                return JNI_FALSE;
//            }
//
//            id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
//            if (!blitEncoder) {
//                NSLog(@"Error: Failed to create Metal blit command encoder.");
//                return JNI_FALSE;
//            }
//
//            MTLSize size = MTLSizeMake(srcTexture.width, srcTexture.height, 1);
//            [blitEncoder copyFromTexture:srcTexture
//                             sourceSlice:0
//                             sourceLevel:0
//                            sourceOrigin:MTLOriginMake(0, 0, 0)
//                              sourceSize:size
//                               toTexture:dstTexture
//                        destinationSlice:0
//                        destinationLevel:0
//                       destinationOrigin:MTLOriginMake(0, 0, 0)];
//
//            [blitEncoder endEncoding];
//            [commandBuffer commit];
//            [commandBuffer waitUntilCompleted];
//
//            if (commandBuffer.error) {
//                NSLog(@"Error: Command buffer failed with error: %@", commandBuffer.error);
//                return JNI_FALSE;
//            }
//        }
//
//        return JNI_TRUE;
//    }
//
//    jlong getMTLTextureFromIOSurface(JNIEnv *env, jlong pIOSurface) {
//        IOSurfaceRef iosurface = (__bridge IOSurfaceRef)(void *)pIOSurface;
//        if (!iosurface) {
//            NSLog(@"Invalid IOSurface provided.");
//            return 0; // Return 0 if the IOSurface is invalid
//        }
//
//        // Get the Metal device
//        id<MTLDevice> metalDevice = MTLCreateSystemDefaultDevice();
//        if (!metalDevice) {
//            NSLog(@"Failed to create Metal device.");
//            return 0; // Return 0 if Metal device could not be created
//        }
//
//        // Configure a Metal texture descriptor for the IOSurface
//        MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
//        textureDescriptor.width = IOSurfaceGetWidth(iosurface);
//        textureDescriptor.height = IOSurfaceGetHeight(iosurface);
//        textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm; // Set appropriate pixel format
//        textureDescriptor.textureType = MTLTextureType2D;
//        textureDescriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite;
//        textureDescriptor.storageMode = MTLStorageModeShared;
//
//        // Create a Metal texture backed by the IOSurface
//        id<MTLTexture> texture = [metalDevice newTextureWithDescriptor:textureDescriptor iosurface:iosurface plane:0];
//        if (!texture) {
//            NSLog(@"Failed to create Metal texture from IOSurface.");
//            return 0; // Return 0 if texture creation fails
//        }
//
//        // Return the Metal texture as a jlong handle
//        return (jlong)texture;
//    }
//
//    namespace {
//        CGLContextObj gOpenGlContext = nullptr;
//
////        CGLContextObj createOpenGLContext() {
////            CGLPixelFormatAttribute attributes[] = {
////                    kCGLPFAOpenGLProfile, (CGLPixelFormatAttribute)kCGLOGLPVersion_3_2_Core,
////                    kCGLPFAAccelerated,
////                    kCGLPFADoubleBuffer,
////                    kCGLPFAColorSize, (CGLPixelFormatAttribute)24,
////                    kCGLPFAAlphaSize, (CGLPixelFormatAttribute)8,
////                    kCGLPFADepthSize, (CGLPixelFormatAttribute)24,
////                    (CGLPixelFormatAttribute)0
////            };
////
////
////            CGLPixelFormatObj pixelFormat;
////            GLint numFormats;
////            CGLContextObj ctx;
////
////            CGLChoosePixelFormat(attributes, &pixelFormat, &numFormats);
////            if (!pixelFormat) {
////                NSLog(@"Failed to choose pixel format.");
////                return NULL;
////            }
////
////            CGLCreateContext(pixelFormat, NULL, &ctx);
////            CGLReleasePixelFormat(pixelFormat);
////
////            if (!ctx) {
////                NSLog(@"Failed to create OpenGL gOpenGlContext.");
////                return NULL;
////            }
////
////            CGLSetCurrentContext(ctx);
////            NSLog(@"OpenGL gOpenGlContext successfully created and set.");
////
////            return ctx;
////        }
//
//        CGLContextObj getOpenGLContext() {
//            return gOpenGlContext;
//        }
//
//
//    }
//
//    jlong getOpenGLTextureFromIOSurface(JNIEnv *env, jlong pIOSurface) {
//        CGLContextObj cglContext = getOpenGLContext();
//        if (!cglContext) {
//            NSLog(@"No current OpenGL gOpenGlContext available.");
//            return 0;
//        }
//
//        CGLSetCurrentContext(cglContext);
//
//        IOSurfaceRef iosurface = (__bridge IOSurfaceRef)(void *)pIOSurface;
//        if (!iosurface) {
//            NSLog(@"Invalid IOSurface provided.");
//            return 0; // Return 0 if the IOSurface is invalid
//        }
//
//        // Create a new OpenGL texture object
//        GLuint textureID;
//        glGenTextures(1, &textureID);
//        if (textureID == 0) {
//            NSLog(@"Failed to generate OpenGL texture.");
//            return 0; // Return 0 if texture generation failed
//        }
//
//        // Bind the texture to the target
//        glBindTexture(GL_TEXTURE_2D, textureID);
//        GLenum error = glGetError();
//        if (error != GL_NO_ERROR) {
//            NSLog(@"OpenGL Error: 0x%04X", error);
//            glDeleteTextures(1, &textureID);  // Cleanup
//        }
//
//        GLsizei width = IOSurfaceGetWidth(iosurface);
//        GLsizei height = IOSurfaceGetHeight(iosurface);
//
//        // Configure texture to use IOSurface
//        CGLError cglError = CGLTexImageIOSurface2D(cglContext,
//                               GL_TEXTURE_2D,              // Texture target
//                               GL_RGBA,                           // Internal format
//                               width,  // Width
//                               height, // Height
//                               GL_BGRA,                           // Format
//                               GL_UNSIGNED_INT_8_8_8_8_REV,       // Data type
//                               iosurface,                         // IOSurface
//                               0);                                // Plane index
//        if (cglError != kCGLNoError) {
//            NSLog(@"Failed to create OpenGL texture from IOSurface: 0x%04X", cglError);
//        }
//
//        error = glGetError();
//        if (error != GL_NO_ERROR) {
//            NSLog(@"OpenGL Error: 0x%04X", error);
//            glDeleteTextures(1, &textureID);  // Cleanup
//        }
//
//        // Set texture filtering parameters
//        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//
//        // Set texture wrapping mode
//        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//
//
//        // Unbind the texture to leave a clean state
//        glBindTexture(GL_TEXTURE_2D, 0);
//
//        error = glGetError();
//        if (error != GL_NO_ERROR) {
//            NSLog(@"OpenGL Error: 0x%04X", error);
//            glDeleteTextures(1, &textureID);  // Cleanup
//        }
//
//        // Return the OpenGL texture ID as a jlong
//        NSLog(@"Successfully created OpenGL texture with ID: %lu, width=%lu, height=%lu", (unsigned long)textureID, (unsigned long)width, (unsigned long)height);
//        return (jlong)textureID;
//    }
//
//    bool saveOpenGLTextureToPNG(JNIEnv *env, jlong textureId, const std::string& path) {
//        CGLContextObj cglContext = getOpenGLContext();
//        if (!cglContext) {
//            NSLog(@"No current OpenGL gOpenGlContext available.");
//            return 0;
//        }
//
//        CGLSetCurrentContext(cglContext);
//
//        if (textureId == 0 || path.empty()) {
//            NSLog(@"Invalid texture ID or file path.");
//            return false;
//        }
//
//        auto texture = static_cast<GLuint>(textureId);
//
//        // Bind texture to access its data
//        glBindTexture(GL_TEXTURE_2D, texture);
//
//        // Get texture width, height
//        GLint width = 0, height = 0;
//        glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH, &width);
//        GLenum error = glGetError();
//        if (error != GL_NO_ERROR) {
//            NSLog(@"OpenGL Error: 0x%04X", error);
//        }
//
//        glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT, &height);
//        error = glGetError();
//        if (error != GL_NO_ERROR) {
//            NSLog(@"OpenGL Error: 0x%04X", error);
//        }
//
//        if (width == 0 || height == 0) {
//            glBindTexture(GL_TEXTURE_2D, 0);
//            NSLog(@"Error: Texture dimensions are invalid.");
//            return false;
//        }
//
//        NSLog(@"Saving texture with dimensions: width=%d, height=%d", width, height);
//
//        // Allocate memory to read texture data
//        size_t dataSize = width * height * 4; // Assuming GL_RGBA (4 bytes per pixel)
//        auto* pixelData = new GLubyte[dataSize];
//        if (!pixelData) {
//            glBindTexture(GL_TEXTURE_2D, 0);
//            NSLog(@"Error: Failed to allocate memory for texture data.");
//            return false;
//        }
//
//        // Read texture data
//        glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixelData);
//
//        // Check for OpenGL errors
//        error = glGetError();
//        if (error != GL_NO_ERROR) {
//            NSLog(@"OpenGL Error while reading texture data: 0x%04X", error);
//            delete[] pixelData;
//            glBindTexture(GL_TEXTURE_2D, 0);
//            return false;
//        }
//
//        glBindTexture(GL_TEXTURE_2D, 0); // Unbind texture
//
//        NSString* nsPath = [NSString stringWithUTF8String:path.c_str()];
//
//        if (!nsPath) {
//            NSLog(@"Error: Failed to convert path to NSString.");
//            delete[] pixelData;
//            return false;
//        }
//
//        // Create an NSBitmapImageRep using the pixel data
//        NSBitmapImageRep* imageRep = [[NSBitmapImageRep alloc]
//                initWithBitmapDataPlanes:nullptr
//                              pixelsWide:width
//                              pixelsHigh:height
//                           bitsPerSample:8
//                         samplesPerPixel:4
//                                hasAlpha:YES
//                                isPlanar:NO
//                          colorSpaceName:NSDeviceRGBColorSpace
//                             bytesPerRow:width * 4
//                            bitsPerPixel:32];
//        if (!imageRep) {
//            NSLog(@"Error: Failed to create NSBitmapImageRep.");
//            delete[] pixelData;
//            return false;
//        }
//
//        // Copy the pixel data into the image representation
//        memcpy([imageRep bitmapData], pixelData, dataSize);
//        delete[] pixelData; // Free pixel data after copying
//
//        // Save the image representation as a PNG file
//        NSDictionary* properties = @{};
//        NSData* pngData = [imageRep representationUsingType:NSBitmapImageFileTypePNG properties:properties];
//        if (![pngData writeToFile:nsPath atomically:YES]) {
//            NSLog(@"Error: Failed to write PNG file to path: %@", nsPath);
//            return false;
//        }
//
//        NSLog(@"Successfully saved texture to PNG: %@", nsPath);
//        return true; // Return success        return 0;
//    }
//
//    jlong loadOpenGLTextureFromPNG(JNIEnv *env, const std::string &path) {
//        // Convert C++ std::string to an NSString
//        CGLSetCurrentContext(getOpenGLContext());
//        NSString *filePath = [NSString stringWithUTF8String:path.c_str()];
//        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
//            NSLog(@"Error: File does not exist at path: %@", filePath);
//            return 0; // Return 0 if the file is not found
//        }
//
//        // Load image data using NSImage/NSBitmapImageRep
//        NSData *imageData = [NSData dataWithContentsOfFile:filePath];
//        if (!imageData) {
//            NSLog(@"Error: Failed to load image data from file: %@", filePath);
//            return 0;
//        }
//
//        NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:imageData];
//        if (!imageRep) {
//            NSLog(@"Error: Failed to create NSBitmapImageRep from file: %@", filePath);
//            return 0;
//        }
//
//        NSUInteger width = [imageRep pixelsWide];
//        NSUInteger height = [imageRep pixelsHigh];
//
//        // Ensure the dimensions are valid
//        if (width == 0 || height == 0) {
//            NSLog(@"Error: Invalid image dimensions. Width: %lu, Height: %lu", (unsigned long)width, (unsigned long)height);
//            return 0;
//        }
//
//        NSLog(@"Successfully loaded image. Width: %lu, Height: %lu", (unsigned long)width, (unsigned long)height);
//
//        // Check the image's color properties
//        if (![imageRep hasAlpha]) {
//            NSLog(@"Warning: Image does not have an alpha channel. Transparency may not be preserved.");
//        }
//
//        if (![imageRep respondsToSelector:@selector(bitmapData)]) {
//            NSLog(@"Error: NSBitmapImageRep does not support bitmapData extraction.");
//            return 0;
//        }
//
//        // Get raw RGBA pixel data
//        NSUInteger bytesPerPixel = 4; // Assume PNG is RGBA (8-bit per channel, 4 channels)
//        NSUInteger bytesPerRow = width * bytesPerPixel;
//        NSUInteger dataSize = height * bytesPerRow;
//
//        unsigned char *pixelBuffer = new unsigned char[dataSize];
//        if (!pixelBuffer) {
//            NSLog(@"Error: Failed to allocate memory for pixel data.");
//            return 0;
//        }
//
//        unsigned char *bitmapData = (unsigned char *)[imageRep bitmapData];
//        if (!bitmapData) {
//            NSLog(@"Error: Failed to extract bitmap data from image.");
//            delete[] pixelBuffer;
//            return 0;
//        }
//
//        // Copy pixel data into our buffer
//        memcpy(pixelBuffer, bitmapData, dataSize);
//
//        // Create an OpenGL texture
//        GLuint textureID;
//        glGenTextures(1, &textureID);
//        if (textureID == 0) {
//            NSLog(@"Error: Failed to generate OpenGL texture.");
//            delete[] pixelBuffer;
//            return 0;
//        }
//
//        // Bind texture and set parameters
//        glBindTexture(GL_TEXTURE_2D, textureID);
//
//        glTexImage2D(GL_TEXTURE_2D,            // Texture target
//                     0,                        // Mipmap level
//                     GL_RGBA,                  // Internal format
//                     (GLsizei)width,           // Texture width
//                     (GLsizei)height,          // Texture height
//                     0,                        // Border (must be 0)
//                     GL_RGBA,                  // Format of input data
//                     GL_UNSIGNED_BYTE,         // Data type of input data
//                     pixelBuffer);             // Pixel data
//
//        GLenum error = glGetError();
//        if (error != GL_NO_ERROR) {
//            NSLog(@"OpenGL Error: Failed to upload texture data. Error code: 0x%04X", error);
//            delete[] pixelBuffer;
//            glDeleteTextures(1, &textureID);
//            return 0;
//        }
//
//        // Set texture parameters (minification/magnification filters and wrapping modes)
//        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//
//        // Unbind the texture
//        glBindTexture(GL_TEXTURE_2D, 0);
//
//        // Free the pixel buffer
//        delete[] pixelBuffer;
//
//        NSLog(@"Texture loaded successfully. OpenGL texture ID: %u", textureID);
//
//        // Return the texture ID as a long integer
//        return static_cast<jlong>(textureID);
//    }
//
//    bool createOpenGLContext(JNIEnv *env, jlong sharedContext, jlong pixelFormatArg) {
//        // Use the pixelFormatArg if provided; otherwise, create default attributes
//        CGLPixelFormatObj pixelFormat = reinterpret_cast<CGLPixelFormatObj>(pixelFormatArg);
//        bool customPixelFormat = (pixelFormatArg != 0);
//        GLint numPixelFormats = 0;
//
//        // If custom pixel format is not provided, create new pixel format
//        if (!customPixelFormat) {
//            CGLPixelFormatAttribute attributes[] = {
//                    kCGLPFAOpenGLProfile, (CGLPixelFormatAttribute)kCGLOGLPVersion_3_2_Core, // Set OpenGL profile to 3.2 Core
//                    kCGLPFADoubleBuffer,                                                  // Enable double buffer
//                    kCGLPFAColorSize, (CGLPixelFormatAttribute)24,                        // 24-bit color buffer
//                    kCGLPFAAlphaSize, (CGLPixelFormatAttribute)8,                         // 8-bit alpha channel
//                    (CGLPixelFormatAttribute)0                                            // Terminator
//            };
//
//            // Choose Pixel Format
//            CGLError error = CGLChoosePixelFormat(attributes, &pixelFormat, &numPixelFormats);
//            if (error != kCGLNoError || pixelFormat == nullptr) {
//                NSLog(@"Error: Failed to choose pixel format. Error code: %d", error);
//                return false;
//            }
//        }
//
//        // Create OpenGL Context
//        // If sharedContext is non-zero, share resources with it
//        CGLContextObj sharedCGLContext = reinterpret_cast<CGLContextObj>(sharedContext);
//        CGLError error = CGLCreateContext(pixelFormat, sharedCGLContext, &gOpenGlContext);
//
//        // Release pixel format only if it was created here
//        if (!customPixelFormat) {
//            CGLReleasePixelFormat(pixelFormat);
//        }
//
//        if (error != kCGLNoError || gOpenGlContext == nullptr) {
//            NSLog(@"Error: Failed to create OpenGL gOpenGlContext. Error code: %d", error);
//            gOpenGlContext = nullptr;
//            return false;
//        }
//
//        // Make the created gOpenGlContext the current one
//        error = CGLSetCurrentContext(gOpenGlContext);
//        if (error != kCGLNoError) {
//            NSLog(@"Error: Failed to set the current OpenGL gOpenGlContext. Error code: %d", error);
//            CGLDestroyContext(gOpenGlContext);
//            gOpenGlContext = nullptr;
//            return false;
//        }
//
//        NSLog(@"OpenGL gOpenGlContext created successfully.");
//        return true;
//    }
//
//    void releaseOpenGLTexture(JNIEnv *env, jlong texture) {
//        GLuint textureID = static_cast<GLuint>(texture);
//        glDeleteTextures(1, &textureID);
//    }
    jboolean renderTriangleToMTLTexture(jlong pTexture) {
        NSLog(@"renderTriangleToMTLTexture %lu", (unsigned long)pTexture);
        // Cast the jlong to the Metal texture object
        id<MTLTexture> metalTexture = reinterpret_cast<id<MTLTexture>>(pTexture);
        if (!metalTexture) {
            NSLog(@"Invalid Metal texture pointer");
            return 0; // Return failure if the texture pointer is not valid
        }

        // Create the Metal device
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) {
            NSLog(@"Failed to create Metal device!");
            return 0; // Return failure if no Metal device was created
        }

        // Create a Metal command queue
        id<MTLCommandQueue> commandQueue = [device newCommandQueue];
        if (!commandQueue) {
            NSLog(@"Failed to create command queue!");
            return 0; // Return failure if command queue creation failed
        }

        // Create a Metal command buffer
        id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
        if (!commandBuffer) {
            NSLog(@"Failed to create command buffer!");
            return 0; // Return failure if command buffer is not valid
        }

        // Create a Metal render pass descriptor
        MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        if (!renderPassDescriptor) {
            NSLog(@"Failed to create render pass descriptor!");
            return 0; // Return failure if render pass descriptor creation failed
        }

        // Configure the render pass descriptor with the target texture
        renderPassDescriptor.colorAttachments[0].texture = metalTexture;
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0); // Clear to black
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

        // Create a Metal render command encoder
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        if (!renderEncoder) {
            NSLog(@"Failed to create render command encoder!");
            return 0; // Return failure if the render encoder creation failed
        }

        // Setup the vertices for the triangle
        static const float triangleVertices[] = {
                0.0f,  1.0f,  0.0f, // Top vertex
                -1.0f, -1.0f,  0.0f, // Bottom-left vertex
                1.0f, -1.0f,  0.0f  // Bottom-right vertex
        };

        // Create a Metal buffer for the triangle vertices
        id<MTLBuffer> vertexBuffer = [device newBufferWithBytes:triangleVertices
                                                         length:sizeof(triangleVertices)
                                                        options:MTLResourceStorageModeShared];
        if (!vertexBuffer) {
            NSLog(@"Failed to create vertex buffer!");
            return 0; // Return failure if vertex buffer creation failed
        }

        // Configure the render pipeline (shaders must be precompiled or configured separately)
        static const char *vertexShaderSource = R"(
        #include <metal_stdlib>
        using namespace metal;
        struct VertexOut {
            float4 position [[ position ]];
        };
        vertex VertexOut vertex_main(const device float3 *vertices [[ buffer(0) ]], uint vertexID [[ vertex_id ]]) {
            VertexOut out;
            out.position = float4(vertices[vertexID], 1.0);
            return out;
        })";

        static const char *fragmentShaderSource = R"(
        #include <metal_stdlib>
        using namespace metal;
        fragment float4 fragment_main() {
            return float4(1.0, 0.0, 0.0, 1.0); // Red color
        })";

        NSError *error = nil;

        // Create the default library with these shaders
        id<MTLLibrary> library = [device newLibraryWithSource:[NSString stringWithUTF8String:vertexShaderSource]
                                                      options:nil
                                                        error:&error];
        if (!library || error) {
            NSLog(@"Failed to create Metal library: %@", error.localizedDescription);
            return 0;
        }

        // Load shaders from the library
        id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertex_main"];
        id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragment_main"];

        if (!vertexFunction || !fragmentFunction) {
            NSLog(@"Failed to load vertex or fragment shader functions from the library!");
            return 0;
        }

        // Configure a Metal pipeline state descriptor
        MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineDescriptor.vertexFunction = vertexFunction;
        pipelineDescriptor.fragmentFunction = fragmentFunction;
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalTexture.pixelFormat;

        id<MTLRenderPipelineState> pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
        if (!pipelineState || error) {
            NSLog(@"Failed to create render pipeline state: %@", error.localizedDescription);
            return 0;
        }

        // Set the pipeline state and vertex buffer for the render encoder
        [renderEncoder setRenderPipelineState:pipelineState];
        [renderEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];

        // Draw the triangle
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];

        // End encoding
        [renderEncoder endEncoding];

        // Commit the command buffer and wait until it is completed
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];

        NSLog(@"Rendering triangle to Metal texture completed successfully!");
        return 1; // Success
    }
}
