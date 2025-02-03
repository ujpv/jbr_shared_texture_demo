#include "windows_utils.h"

namespace {
    void notImplemented(JNIEnv *env) {
        env->ThrowNew(env->FindClass("java/lang/UnsupportedOperationException"), "Not implemented");
    }
}

namespace platform_utils {
    jlong loadIOSurfaceFromPNG(JNIEnv *env, const std::string &path) {
        notImplemented(env);
        return 0;
    }

    jlong getMTLTextureFromIOSurface(JNIEnv *env, jlong pIOSurface) {
        notImplemented(env);
        return 0;
    }

    jlong getOpenGLTextureFromIOSurface(JNIEnv *env, jlong pIOSurface) {
        notImplemented(env);
        return 0;
    }

    bool createOpenGLContext(JNIEnv *env, jlong sharedContex, jlong pixelFormat) {
        notImplemented(env);
        return false;
    }

    jlong loadOpenGLTextureFromPNG(JNIEnv *env, const std::string &path) {
        notImplemented(env);
        return 0;
    }

    bool saveOpenGLTextureToPNG(JNIEnv *env, jlong textureId, const std::string &path) {
        notImplemented(env);
        return false;
    }

    jlong loadMTLTextureFromPNG(JNIEnv *env, const std::string &path) {
        notImplemented(env);
        return 0;
    }

    void releaseMTLTexture(JNIEnv *env, jlong) {
        notImplemented(env);
    }

    jboolean scaleMTLTexture(JNIEnv *env, jlong pSrc, jlong dDst, jdouble scale) {
        notImplemented(env);
        return 0;
    }

    jboolean copyMTLTexture(JNIEnv *env, jlong pSrc, jlong pDst) {
        notImplemented(env);
        return 0;
    }

    jbyteArray MTLTextureToByteArray(JNIEnv *env, jlong ptr) {
        notImplemented(env);
        return nullptr;
    }

    std::pair<int, int> getMTLTextureSize(JNIEnv *env, jlong ptr) {
        notImplemented(env);
        return std::pair<int, int>();
    }

    jlong getTextureFromVolatileImage(JNIEnv *env, jobject vi) {
        notImplemented(env);
        return 0;
    }

    void releaseOpenGLTexture(JNIEnv *env, jlong texture) {
        notImplemented(env);
    }
}