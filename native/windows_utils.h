#ifndef NATIVE_WINDOWS_UTILS_H
#define NATIVE_WINDOWS_UTILS_H

#include <jni.h>
#include <string>
#include <utility>

namespace platform_utils {
    jlong loadIOSurfaceFromPNG(JNIEnv *env, const std::string &path);
    jlong getMTLTextureFromIOSurface(JNIEnv *env, jlong pIOSurface);
    jlong getOpenGLTextureFromIOSurface(JNIEnv *env, jlong pIOSurface);

    bool createOpenGLContext(JNIEnv *env, jlong sharedContex, jlong pixelFormat);
    jlong loadOpenGLTextureFromPNG(JNIEnv *env, const std::string &path);
    bool saveOpenGLTextureToPNG(JNIEnv *env, jlong textureId, const std::string& path);

    jlong loadMTLTextureFromPNG(JNIEnv *env, const std::string &path);
    void releaseMTLTexture(JNIEnv *env, jlong);
    jboolean scaleMTLTexture(JNIEnv *env, jlong pSrc, jlong dDst, jdouble scale);
    jboolean copyMTLTexture(JNIEnv *env, jlong pSrc, jlong pDst);
    jbyteArray MTLTextureToByteArray(JNIEnv *env, jlong ptr);
    std::pair<int, int> getMTLTextureSize(JNIEnv *env, jlong ptr);

    jlong loadD3D12TextureFromPNG(JNIEnv *env, const std::string& filename);
    bool saveD3D12TextureToPNG(JNIEnv *env, const std::string& filename, jlong handle);
    void releaseD3D12Texture(JNIEnv *env, jlong handle);
    jlong getD3D9TextureFromSharedHandle(JNIEnv *env, jlong handle);
    void releaseD3D9Texture(JNIEnv *env, jlong texture);
    bool saveD3D9TextureToPNG(JNIEnv *env, const std::string& path, jlong texture);


    jlong getTextureFromVolatileImage(JNIEnv *env, jobject vi);
    void releaseOpenGLTexture(JNIEnv *env, jlong texture);
}

#endif //NATIVE_WINDOWS_UTILS_H
