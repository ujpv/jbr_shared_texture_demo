#ifndef NATIVE_METAL_UTILS_H
#define NATIVE_METAL_UTILS_H

#include <jni.h>
#include <string>

namespace metal_utils {
    jlong loadMTLTextureFromPNG(const std::string &path);
}

#endif //NATIVE_METAL_UTILS_H
