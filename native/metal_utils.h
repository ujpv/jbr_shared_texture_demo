#ifndef NATIVE_METAL_UTILS_H
#define NATIVE_METAL_UTILS_H

#include <jni.h>
#include <string>
#include <utility>

namespace metal_utils {
    jlong loadMTLTextureFromPNG(const std::string &path);
    void releaseMTLTexture(jlong);
    jbyteArray MTLTextureToByteArray(JNIEnv *env, jlong ptr);
    std::pair<int, int> getMTLTextureSize(jlong ptr);
    jboolean wrapMTLTextureToVolatileImage(JNIEnv *env, jobject vi, jlong ptr);
    jlong getTextureFromVolatileImage(JNIEnv *env, jobject vi);
    jboolean scaleTexture(jlong pSrc, jlong dDst, jdouble scale);
}

#endif //NATIVE_METAL_UTILS_H