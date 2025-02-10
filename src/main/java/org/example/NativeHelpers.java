package org.example;

import java.awt.*;
import java.awt.image.*;

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

    public static native boolean renderTriangleToMTLTexture(long pTexture);

    public static native long loadBitmapFromPNG(String path);
    public static native void releaseBitmapFromJPG(long pBitmap);
}
