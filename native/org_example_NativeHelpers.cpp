#include <jni.h>

#include "metal_utils.h"

extern "C" jstring Java_org_example_NativeHelpers_sayHallo(JNIEnv * env, jclass) {
    return env->NewStringUTF("Hallo");
}

extern "C" jlong Java_org_example_NativeHelpers_loadTextureFromPng(JNIEnv * env, jclass, jstring path) {
    return metal_utils::loadMTLTextureFromPNG(env->GetStringUTFChars(path, nullptr));
}

extern "C" void Java_org_example_NativeHelpers_releaseTexture(JNIEnv *, jclass, jlong ptr) {
    metal_utils::releaseMTLTexture(ptr);
}

extern "C" jbyteArray Java_org_example_NativeHelpers_textureToByteArray(JNIEnv *env, jclass, jlong ptr) {
    return metal_utils::MTLTextureToByteArray(env, ptr);
}

extern "C" jobject Java_org_example_NativeHelpers_getTextureSize(JNIEnv *env, jclass, jlong ptr) {
    auto size = metal_utils::getMTLTextureSize(ptr);
    if (size.first == -1 || size.second == -1) {
        return nullptr;
    }

    jclass dimensionClass = env->FindClass("java/awt/Dimension");
    if (!dimensionClass) {
        return nullptr;
    }

    jmethodID constructor = env->GetMethodID(dimensionClass, "<init>", "(II)V");
    if (!constructor) {
        return nullptr; // Constructor not found
    }

    return env->NewObject(dimensionClass, constructor, size.first, size.second);
}

extern "C" jboolean Java_org_example_NativeHelpers_wrapToVolatileImage(JNIEnv *env, jclass, jobject vi, jlong ptr) {
    return metal_utils::wrapMTLTextureToVolatileImage(env, vi, ptr);
}
