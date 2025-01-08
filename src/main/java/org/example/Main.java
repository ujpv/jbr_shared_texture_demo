package org.example;

import javax.imageio.ImageIO;
import javax.swing.*;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.awt.image.DataBufferByte;
import java.awt.image.Raster;
import java.awt.image.WritableRaster;
import java.io.File;
import java.io.IOException;

public class Main {
    public static void main(String[] args) {
        String filename = "/Users/Vladimir.Kharitonov/develop/jbr_shared_texture_demo/src/simple_shapes_example.png";
        long ptr = NativeHelpers.loadTextureFromPng(filename);
        BufferedImage nativeImage = fromTexture(ptr);
        NativeHelpers.releaseTexture(ptr);

        BufferedImage javaImage = null;
        try {
            javaImage = ImageIO.read(new File(filename));
        } catch (IOException e) {
            e.printStackTrace();
            System.out.println("Failed to load image using standard Java tools.");
        }

        if (nativeImage != null && javaImage != null) {
            displayImages(nativeImage, javaImage);
        } else {
            System.out.println("One or both images could not be loaded.");
        }
    }

    private static BufferedImage fromTexture(long texture) {
        byte[] textureData = NativeHelpers.textureToByteArray(texture);
        Dimension size = NativeHelpers.getTextureSize(texture);

        int bytesPerPixel = 4; // BGRA format (1 byte per channel)
        DataBufferByte dataBuffer = new DataBufferByte(textureData, textureData.length);
        WritableRaster raster = Raster.createInterleavedRaster(
                dataBuffer, size.width, size.height, bytesPerPixel * size.width, bytesPerPixel, new int[]{2, 1, 0, 3}, null
        );
        BufferedImage image = new BufferedImage(size.width, size.height, BufferedImage.TYPE_4BYTE_ABGR);
        image.setData(raster);

        return image;
    }

    private static void displayImages(BufferedImage nativeImage, BufferedImage javaImage) {
        // Create a JFrame to display the images
        JFrame frame = new JFrame("Image Comparison");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setLayout(new BorderLayout());

        // Create a custom JPanel for painting the images
        JPanel panel = new JPanel() {
            @Override
            protected void paintComponent(Graphics g) {
                super.paintComponent(g);

                // Draw the two images side by side with labels
                int spacing = 20; // Spacing between images and labels

                // Draw native image
                g.drawImage(nativeImage, spacing, spacing, null);
                g.setColor(Color.BLACK);
                g.drawString("Native Image", spacing, nativeImage.getHeight() + spacing + 15);

                // Draw Java image
                g.drawImage(javaImage, nativeImage.getWidth() + 2 * spacing, spacing, null);
                g.drawString("Java Image", nativeImage.getWidth() + 2 * spacing, javaImage.getHeight() + spacing + 15);
            }

            // Set preferred size of the panel to accommodate both images
            @Override
            public Dimension getPreferredSize() {
                int spacing = 20;
                int width = nativeImage.getWidth() + javaImage.getWidth() + 3 * spacing;
                int height = Math.max(nativeImage.getHeight(), javaImage.getHeight()) + 2 * spacing + 15;
                return new Dimension(width, height);
            }
        };

        // Add the panel to the frame
        frame.add(panel, BorderLayout.CENTER);
        frame.pack();
        frame.setVisible(true);
    }
}