package org.example;

public class NativeHelpers {
    static {
        System.loadLibrary("native_helpers");
    }
    public static native String sayHallo();
}
