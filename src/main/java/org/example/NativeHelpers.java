package org.example;

import java.awt.image.BufferedImage;

public class NativeHelpers {
    private static final String nativeHelperLibName = "native_helpers";

    static {
        try {
            System.loadLibrary(nativeHelperLibName);
        } catch (UnsatisfiedLinkError e) {
            System.err.println("Failed to load native library: " + nativeHelperLibName);
            System.err.println("Ensure that java.library.path is pointing at the directory containing 'lib" + nativeHelperLibName + "'.dylib");
            System.exit(1);
        }
    }

    public static native String sayHallo();

    public static native long loadTextureFromPng(String filename);
    public static native void releaseTexture(long texture);
    public static native BufferedImage textureToBufferedImage(long texture);
}
