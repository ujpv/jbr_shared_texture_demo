#include <jni.h>

extern "C" jstring Java_org_example_NativeHelpers_sayHallo(JNIEnv * env, jclass) {
    return env->NewStringUTF("Hallo");
}
