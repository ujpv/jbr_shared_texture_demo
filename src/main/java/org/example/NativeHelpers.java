package org.example;

import java.awt.*;
import java.awt.image.VolatileImage;

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
    public static native byte[] textureToByteArray(long texture);
    public static native Dimension getTextureSize(long texture);
    public static native boolean wrapToVolatileImage(VolatileImage image, long texture);
}
