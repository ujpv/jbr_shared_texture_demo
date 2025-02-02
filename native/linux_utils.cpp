#include "linux_utils.h"

namespace platform_utils {
    jlong loadIOSurfaceFromPNG(JNIEnv *env, const std::string &path) {
        env->ThrowNew(env->FindClass("java/lang/UnsupportedOperationException"),
                      "This operation is not supported on this platform.");
        return 0;
    }

    jlong getMTLTextureFromIOSurface(JNIEnv *env, jlong pIOSurface) {
        env->ThrowNew(env->FindClass("java/lang/UnsupportedOperationException"),
                      "This operation is not supported on this platform.");
        return 0;
    }

    jlong getOpenGLTextureFromIOSurface(JNIEnv *env, jlong pIOSurface) {
        env->ThrowNew(env->FindClass("java/lang/UnsupportedOperationException"),
                      "This operation is not supported on this platform.");
        return 0;
    }

    bool createOpenGLContext(JNIEnv *env, jlong sharedContex, jlong pixelFormat) {
        env->ThrowNew(env->FindClass("java/lang/UnsupportedOperationException"),
              "This operation is not supported on this platform.");
        return false;
    }

    jlong loadOpenGLTextureFromPNG(JNIEnv *env, const std::string &path) {
        env->ThrowNew(env->FindClass("java/lang/UnsupportedOperationException"),
              "This operation is not supported on this platform.");
        return 0;
    }

    bool saveOpenGLTextureToPNG(JNIEnv *env, jlong textureId, const std::string &path) {
        env->ThrowNew(env->FindClass("java/lang/UnsupportedOperationException"),
              "This operation is not supported on this platform.");
        return false;
    }

    jlong loadMTLTextureFromPNG(JNIEnv *env, const std::string &path) {
        env->ThrowNew(env->FindClass("java/lang/UnsupportedOperationException"),
              "This operation is not supported on this platform.");
        return 0;
    }

    void releaseMTLTexture(JNIEnv *env, jlong) {
        env->ThrowNew(env->FindClass("java/lang/UnsupportedOperationException"),
              "This operation is not supported on this platform.");
    }

    jboolean scaleMTLTexture(JNIEnv *env, jlong pSrc, jlong dDst, jdouble scale) {
        env->ThrowNew(env->FindClass("java/lang/UnsupportedOperationException"),
              "This operation is not supported on this platform.");
        return false;
    }

    jboolean copyMTLTexture(JNIEnv *env, jlong pSrc, jlong pDst) {
        env->ThrowNew(env->FindClass("java/lang/UnsupportedOperationException"),
              "This operation is not supported on this platform.");
        return false;
    }

    jbyteArray MTLTextureToByteArray(JNIEnv *env, jlong ptr) {
        env->ThrowNew(env->FindClass("java/lang/UnsupportedOperationException"),
              "This operation is not supported on this platform.");
        return nullptr;
    }

    std::pair<int, int> getMTLTextureSize(JNIEnv *env, jlong ptr) {
        env->ThrowNew(env->FindClass("java/lang/UnsupportedOperationException"),
              "This operation is not supported on this platform.");
        return {-1, -1};
    }

    jlong getTextureFromVolatileImage(JNIEnv *env, jobject vi) {
        env->ThrowNew(env->FindClass("java/lang/UnsupportedOperationException"),
              "This operation is not supported on this platform.");
        return 0;
    }

    void releaseOpenGLTexture(JNIEnv *env, jlong texture) {
        env->ThrowNew(env->FindClass("java/lang/UnsupportedOperationException"),
              "This operation is not supported on this platform.");
    }
}
