#include <jni.h>

#include "metal_utils.h"

#include <iostream>

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

extern "C" jlong Java_org_example_NativeHelpers_getTextureFromVolatileImage(JNIEnv *env, jclass, jobject volatileImage) {
    return metal_utils::getTextureFromVolatileImage(env, volatileImage);
}

extern "C" jboolean Java_org_example_NativeHelpers_scaleTexture(JNIEnv *, jclass, jlong pSrc, jlong pDst, jdouble scale) {
    return metal_utils::scaleTexture(pSrc, pDst, scale);
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

