#include <jni.h>

jstring Java_org_example_NativeHelpers_sayHallo(JNIEnv * env, jobject self) {
    return env->NewStringUTF("Hallo");
}
