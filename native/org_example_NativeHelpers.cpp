#include <jni.h>

#include "org_example_NativeHelpers.h"

#if __APPLE__
#include "metal_utils.h"
#elif _WIN32
#include "windows_utils.h"
#elif __linux__
#include "linux_utils.h"
#endif


#include <iostream>

extern "C" jlong Java_org_example_NativeHelpers_loadMTLTextureFromPNG(JNIEnv * env, jclass, jstring path) {
    return platform_utils::loadMTLTextureFromPNG(env, env->GetStringUTFChars(path, nullptr));
}

extern "C" jlong Java_org_example_NativeHelpers_loadOpenGLTextureFromPNG(JNIEnv *env, jclass, jstring path) {
    jlong result = platform_utils::loadOpenGLTextureFromPNG(env,env->GetStringUTFChars(path, nullptr));
    return result;
}

extern "C" void Java_org_example_NativeHelpers_releaseMTLTexture(JNIEnv *env, jclass, jlong ptr) {
    platform_utils::releaseMTLTexture(env, ptr);
}

extern "C" jbyteArray Java_org_example_NativeHelpers_MTLTextureToByteArray(JNIEnv *env, jclass, jlong ptr) {
    return platform_utils::MTLTextureToByteArray(env, ptr);
}

extern "C" jobject Java_org_example_NativeHelpers_getMTLTextureSize(JNIEnv *env, jclass, jlong ptr) {
    auto size = platform_utils::getMTLTextureSize(env, ptr);
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

extern "C" jlong Java_org_example_NativeHelpers_getTextureFromVolatileImage(JNIEnv *env, jclass, jobject volatileImage) {
    return platform_utils::getTextureFromVolatileImage(env, volatileImage);
}

extern "C" jboolean Java_org_example_NativeHelpers_scaleMTLTexture(JNIEnv *env, jclass, jlong pSrc, jlong pDst, jdouble scale) {
    return platform_utils::scaleMTLTexture(env, pSrc, pDst, scale);
}

extern "C" void Java_org_example_NativeHelpers_RenderQueueFlushAndInvokeNow(JNIEnv *env, jclass cls, jobject runnable) {
    // Get the MTLRenderQueue instance (assuming it has a static method)
    jclass renderQueueClass = env->FindClass("sun/java2d/metal/MTLRenderQueue");
    if (!renderQueueClass) {
        std::cerr << "Error: Unable to find MTLRenderQueue class." << std::endl;
        return;
    }

    jmethodID getInstanceMethod = env->GetStaticMethodID(renderQueueClass, "getInstance", "()Lsun/java2d/metal/MTLRenderQueue;");
    if (!getInstanceMethod) {
        std::cerr << "Error: Unable to find getInstance method in MTLRenderQueue." << std::endl;
        return;
    }

    jobject renderQueueInstance = env->CallStaticObjectMethod(renderQueueClass, getInstanceMethod);
    if (!renderQueueInstance) {
        std::cerr << "Error: Unable to get instance of MTLRenderQueue." << std::endl;
        return;
    }

    // Lock the render queue
    jmethodID lockMethod = env->GetMethodID(renderQueueClass, "lock", "()V");
    if (!lockMethod) {
        std::cerr << "Error: Unable to find lock method in MTLRenderQueue." << std::endl;
        return;
    }

    env->CallVoidMethod(renderQueueInstance, lockMethod);

    // Try block to flush and invoke runnable
    bool success = false;
    jmethodID flushAndInvokeNowMethod = env->GetMethodID(renderQueueClass, "flushAndInvokeNow", "(Ljava/lang/Runnable;)V");
    if (!flushAndInvokeNowMethod) {
        std::cerr << "Error: Unable to find flushAndInvokeNow method in MTLRenderQueue." << std::endl;
    } else {
        env->CallVoidMethod(renderQueueInstance, flushAndInvokeNowMethod, runnable);
        success = true;
    }

    // Unlock the render queue (finally block equivalent)
    jmethodID unlockMethod = env->GetMethodID(renderQueueClass, "unlock", "()V");
    if (!unlockMethod) {
        std::cerr << "Error: Unable to find unlock method in MTLRenderQueue." << std::endl;
    } else {
        env->CallVoidMethod(renderQueueInstance, unlockMethod);
    }

    // Clean up references
    if (renderQueueInstance) {
        env->DeleteLocalRef(renderQueueInstance);
    }
    env->DeleteLocalRef(renderQueueClass);

    // Handle if flushAndInvokeNow failed
    if (!success) {
        std::cerr << "Error: flushAndInvokeNow call failed." << std::endl;
    }
}

extern "C" jboolean Java_org_example_NativeHelpers_copyMTLTexture(JNIEnv *env, jclass, jlong pSrc, jlong pDst) {
    return platform_utils::copyMTLTexture(env, pSrc, pDst);
}

extern "C" jlong Java_org_example_NativeHelpers_loadIOSurfaceFromPNG(JNIEnv *env, jclass, jstring path) {
    return platform_utils::loadIOSurfaceFromPNG(env, env->GetStringUTFChars(path, nullptr));
}

extern "C" jlong Java_org_example_NativeHelpers_getMTLTextureFromIOSurface(JNIEnv *env, jclass, jlong pIOSurface) {
    return platform_utils::getMTLTextureFromIOSurface(env, pIOSurface);
}

extern "C" jlong Java_org_example_NativeHelpers_getOpenGLTextureFromIOSurface(JNIEnv *env, jclass, jlong ioSurface) {
    return platform_utils::getOpenGLTextureFromIOSurface(env, ioSurface);
}

extern "C" jboolean Java_org_example_NativeHelpers_saveOpenGLTextureToPNG(JNIEnv *env, jclass, jlong textureId, jstring path) {
    return platform_utils::saveOpenGLTextureToPNG(env, textureId, env->GetStringUTFChars(path, nullptr));
}

extern "C" void Java_org_example_NativeHelpers_createOpenGLContext(JNIEnv *env, jclass, jlong sharedContext, jlong pixelFormat) {
    platform_utils::createOpenGLContext(env, sharedContext, pixelFormat);
}

extern "C" void Java_org_example_NativeHelpers_releaseOpenGLTexture(JNIEnv *env, jclass, jlong) {

}

extern "C" jlong Java_org_example_NativeHelpers_loadD3D12TextureFromPNG(JNIEnv *env, jclass, jstring path) {
    return platform_utils::loadD3D12TextureFromPNG(env, env->GetStringUTFChars(path, nullptr) );
}

extern "C" void Java_org_example_NativeHelpers_releaseD3D12Texture(JNIEnv *env, jclass, jlong handle) {
    platform_utils::releaseD3D12Texture(env, handle);
}

extern "C" jboolean Java_org_example_NativeHelpers_saveD3D12TextureToPNG(JNIEnv * env, jclass, jstring path, jlong handle) {
    return platform_utils::saveD3D12TextureToPNG(env, env->GetStringUTFChars(path, nullptr), handle);
}

extern "C" jlong Java_org_example_NativeHelpers_getD3D9TextureFromSharedHandle(JNIEnv *env, jclass, jlong sharedHandle) {
    return platform_utils::getD3D9TextureFromSharedHandle(env, sharedHandle);
}

extern "C" void Java_org_example_NativeHelpers_releaseD3D9Texture(JNIEnv *env, jclass, jlong texture) {
    platform_utils::releaseD3D9Texture(env, texture);
}

extern "C" jboolean Java_org_example_NativeHelpers_saveD3D9TextureToPNG(JNIEnv *env, jclass, jstring path, jlong texture) {
    return platform_utils::saveD3D9TextureToPNG(env, env->GetStringUTFChars(path, nullptr), texture);
}
