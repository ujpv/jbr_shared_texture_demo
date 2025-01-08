#include <jni.h>

#include "metal_utils.h"

extern "C" jstring Java_org_example_NativeHelpers_sayHallo(JNIEnv * env, jclass) {
    return env->NewStringUTF("Hallo");
}

extern "C" jlong Java_org_example_NativeHelpers_loadTextureFromPng(JNIEnv * env, jclass, jstring path) {
    return metal_utils::loadMTLTextureFromPNG(env->GetStringUTFChars(path, nullptr));
}
