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

    public static BufferedImage bufferedImageFromMTLTexture(long texture) {
        byte[] textureData = NativeHelpers.MTLTextureToByteArray(texture);
        Dimension size = NativeHelpers.getMTLTextureSize(texture);

        int bytesPerPixel = 4; // BGRA format (1 byte per channel)
        DataBufferByte dataBuffer = new DataBufferByte(textureData, textureData.length);
        WritableRaster raster = Raster.createInterleavedRaster(
                dataBuffer, size.width, size.height, bytesPerPixel * size.width, bytesPerPixel, new int[]{2, 1, 0, 3}, null
        );
        BufferedImage image = new BufferedImage(size.width, size.height, BufferedImage.TYPE_4BYTE_ABGR);
        image.setData(raster);

        return image;
    }

    public static native long loadIOSurfaceFromPNG(String filename);
    public static native long getMTLTextureFromIOSurface(long ioSurface);
    public static native long getOpenGLTextureFromIOSurface(long ioSurface);

    public static native long loadMTLTextureFromPNG(String filename);
    public static native Dimension getMTLTextureSize(long texture);
    public static native byte[] MTLTextureToByteArray(long texture);
    public static native boolean scaleMTLTexture(long src, long dst, double scale);
    public static native boolean copyMTLTexture(long pSrc, long pDst);
    public static native void releaseMTLTexture(long texture);

    public static native long loadOpenGLTextureFromPNG(String ioSurface);
    public static native void createOpenGLContext(long sharedContext, long pixelFormat);
    public static native boolean saveOpenGLTextureToPNG(long textureId, String filename);
    public static native void releaseOpenGLTexture(long textureId);

    public static native long getTextureFromVolatileImage(VolatileImage image);

    public static native long loadD3D12TextureFromPNG(String filename);
    public static native void releaseD3D12Texture(long texture);
    public static native boolean saveD3D12TextureToPNG(String path, long handle);
    public static native long getD3D9TextureFromSharedHandle(long handle);
    public static native void releaseD3D9Texture(long handle);
    public static native boolean saveD3D9TextureToPNG(String path, long texture);

    /**
     * Performs this code
     *     MTLRenderQueue rq = MTLRenderQueue.getInstance();
     *     rq.lock();
     *     try {
     *         rq.flushAndInvokeNow(r);
     *     } finally {
     *         rq.unlock();
     *     }
     */
    public static native void RenderQueueFlushAndInvokeNow(Runnable r);
}
