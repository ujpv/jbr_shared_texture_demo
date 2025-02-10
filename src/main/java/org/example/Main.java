package org.example;

import com.jetbrains.JBR;
import com.jetbrains.SharedTextures;
import org.example.ui.ImagePanel;
import org.example.ui.TexturePanel;
import org.example.ui.TextureToBufferedImagePanel;
import org.example.ui.TextureToVolatileImage;

import com.jetbrains.desktop.image.AcceleratedImage;

import javax.imageio.ImageIO;
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.awt.image.*;
import java.io.File;
import java.io.IOException;

public class Main {
//    private static long loadTexture(String filename) {
//        int textureType = JBR.getSharedTextures().getTextureType();
//        switch (textureType) {
//            case SharedTextures.MetalTextureType -> {
//                return NativeHelpers.loadMTLTextureFromPNG(filename);
//            }
//            case SharedTextures.OpenGLTextureType -> {
//                NativeHelpers.createOpenGLContext(
//                        JBR.getSharedTextures().getSharedOpenGLContext(),
//                        JBR.getSharedTextures().getSharedOpenGLContextPixelFormat());
//
//                return NativeHelpers.loadOpenGLTextureFromPNG(filename);
//            }
//            default -> throw new UnsupportedOperationException("Unexpected value: " + textureType);
//        }
//    }

//    private static void releaseTexture(long texture) {
//        int textureType = JBR.getSharedTextures().getTextureType();
//        switch (textureType) {
//            case SharedTextures.MetalTextureType -> NativeHelpers.releaseMTLTexture(texture);
//            case SharedTextures.OpenGLTextureType -> NativeHelpers.releaseOpenGLTexture(texture);
//            default -> throw new UnsupportedOperationException("Unexpected value: " + textureType);
//        }
//    }

    public static void main(String[] args) {
//        NativeHelpers.releaseD3D12Texture(0);
//
//        System.err.println("My PID: " + ProcessHandle.current().pid());
//        String filename = "C:\\develop\\jbr_shared_texture_demo\\data\\simple_shapes_example.png";
//        long handle = NativeHelpers.loadD3D12TextureFromPNG(filename);
////        System.err.println(NativeHelpers.saveD3D12TextureToPNG("C:\\develop\\jbr_shared_texture_demo\\data\\copy.png", handle));
//
//        long d3D9TextureFromSharedHandle = NativeHelpers.getD3D9TextureFromSharedHandle(handle);
//        NativeHelpers.saveD3D9TextureToPNG("C:\\develop\\jbr_shared_texture_demo\\data\\copy_d3d9.png", d3D9TextureFromSharedHandle);
//        NativeHelpers.releaseD3D9Texture(d3D9TextureFromSharedHandle);
//
//        NativeHelpers.releaseD3D12Texture(handle);


//        BufferedImage originalImage = ImageIO.read(new File(filename));
//        long nativeTexture = loadTexture(filename);
//
        SwingUtilities.invokeLater(() -> {
            JFrame frame = new JFrame("Texture Renderer");
            frame.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
            frame.setResizable(false);
            frame.setVisible(true);

            JPanel panel = new JPanel();
            panel.setLayout(new BoxLayout(panel, BoxLayout.X_AXIS));

            ComponentAdapter onResize = new ComponentAdapter() {
                @Override
                public void componentResized(ComponentEvent e) {
                    panel.revalidate();
                    panel.repaint();
                    frame.pack();
                }
            };

            GraphicsConfiguration gc = GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice().getDefaultConfiguration();
            AcceleratedImage i = new AcceleratedImage(gc, 100, 100, Transparency.TRANSLUCENT);
            long nativeResource = i.getNativeResource();
            boolean b = NativeHelpers.renderTriangleToMTLTexture(nativeResource);

            ImagePanel imagePanel = new ImagePanel(i, "Accelerated Image");
            imagePanel.addComponentListener(onResize);
            panel.add(imagePanel);

//            ImagePanel originalImagePanel = new ImagePanel(originalImage, "Original Image");
//            originalImagePanel.addComponentListener(onResize);
//            panel.add(originalImagePanel);
//
//            TexturePanel texturePanel = new TexturePanel(nativeTexture, "Texture");
//            texturePanel.addComponentListener(onResize);
//            panel.add(texturePanel);
//
//            TextureToBufferedImagePanel textureToBufferedImagePanel = new TextureToBufferedImagePanel(nativeTexture, "Texture->BufImage");
//            textureToBufferedImagePanel.addComponentListener(onResize);
//            panel.add(textureToBufferedImagePanel);
//
//            TextureToVolatileImage textureToVolatileImagePanel = new TextureToVolatileImage(nativeTexture, "Texture->VolImage");
//            textureToVolatileImagePanel.addComponentListener(onResize);
//            panel.add(textureToVolatileImagePanel);

            frame.add(panel);
            frame.pack();
        });
    }
}