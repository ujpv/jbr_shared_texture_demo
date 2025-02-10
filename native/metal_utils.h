#ifndef NATIVE_METAL_UTILS_H
#define NATIVE_METAL_UTILS_H

#include <jni.h>
#include <string>
#include <utility>

namespace platform_utils {
    jboolean renderTriangleToMTLTexture(jlong pTexture);
    jlong loadBitmapFromPNG(const std::string& path);
    void releaseBitmap(jlong);
}

#endif //NATIVE_METAL_UTILS_H
