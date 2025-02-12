package org.example;

import com.jetbrains.JBR;
import com.jetbrains.SharedTextures;
import org.example.ui.ImagePanel;
import org.example.ui.TexturePanel;
import org.example.ui.TextureToBufferedImagePanel;
import org.example.ui.TextureToVolatileImage;

import javax.imageio.ImageIO;
import javax.swing.*;
import java.awt.event.*;
import java.awt.image.*;
import java.io.File;
import java.io.IOException;

public class Main {
    private static long loadTexture(String filename) {
        int textureType = JBR.getSharedTextures().getTextureType();
        switch (textureType) {
            case SharedTextures.MetalTextureType -> {
                return NativeHelpers.loadMTLTextureFromPNG(filename);
            }
            default -> throw new UnsupportedOperationException("Unexpected value: " + textureType);
        }
    }

    private static void releaseTexture(long texture) {
        int textureType = JBR.getSharedTextures().getTextureType();
        switch (textureType) {
            case SharedTextures.MetalTextureType -> NativeHelpers.releaseMTLTexture(texture);
            default -> throw new UnsupportedOperationException("Unexpected value: " + textureType);
        }
    }

    public static void main(String[] args) throws IOException {
        String filename = "data/simple_shapes_example.png";

        BufferedImage originalImage = ImageIO.read(new File(filename));
        long nativeTexture = loadTexture(filename);

        SwingUtilities.invokeLater(() -> {
            JFrame frame = new JFrame("Texture Renderer");
            frame.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
            frame.addWindowListener(new WindowAdapter() {
                @Override
                public void windowClosed(WindowEvent e) {
                    releaseTexture(nativeTexture);
                }
            });
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

            ImagePanel originalImagePanel = new ImagePanel(originalImage, "Original Image");
            originalImagePanel.addComponentListener(onResize);
            panel.add(originalImagePanel);

            TexturePanel texturePanel = new TexturePanel(nativeTexture, "Texture");
            texturePanel.addComponentListener(onResize);
            panel.add(texturePanel);

            TextureToBufferedImagePanel textureToBufferedImagePanel = new TextureToBufferedImagePanel(nativeTexture, "Texture->BufImage");
            textureToBufferedImagePanel.addComponentListener(onResize);
            panel.add(textureToBufferedImagePanel);

            TextureToVolatileImage textureToVolatileImagePanel = new TextureToVolatileImage(nativeTexture, "Texture->VolImage");
            textureToVolatileImagePanel.addComponentListener(onResize);
            panel.add(textureToVolatileImagePanel);

            frame.add(panel);
            frame.pack();
        });
    }
}