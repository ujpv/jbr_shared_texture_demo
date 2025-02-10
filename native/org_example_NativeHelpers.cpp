#include <jni.h>

#include "org_example_NativeHelpers.h"

#if __APPLE__
#include "metal_utils.h"
#elif _WIN32
#include "windows_utils.h"
#elif __linux__
#include "linux_utils.h"
#endif

extern "C" jboolean Java_org_example_NativeHelpers_renderTriangleToMTLTexture(JNIEnv *, jclass, jlong texture) {
    return platform_utils::renderTriangleToMTLTexture(texture);
}

extern "C" jlong Java_org_example_NativeHelpers_loadBitmapFromPNG(JNIEnv *env, jclass, jstring path) {
    return platform_utils::loadBitmapFromPNG(env->GetStringUTFChars(path, 0));
}

extern "C" void Java_org_example_NativeHelpers_releaseBitmapFromJPG(JNIEnv *, jclass, jlong pBitmap) {
    platform_utils::releaseBitmap(0);
}

