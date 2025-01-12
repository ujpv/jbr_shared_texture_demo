package org.example;

import javax.imageio.ImageIO;
import javax.swing.*;
import java.awt.*;
import java.awt.image.*;
import java.io.File;
import java.io.IOException;

public class Main {
    public static void main(String[] args) {
        String filename = "data/simple_shapes_example.png";
        long ptr = NativeHelpers.loadTextureFromPng(filename);
        BufferedImage nativeImage = fromTexture(ptr);
        VolatileImage volatileImage = createVolatileImageFromTexture(ptr);

        BufferedImage javaImage = null;
        try {
            javaImage = ImageIO.read(new File(filename));
        } catch (IOException e) {
            e.printStackTrace();
            System.out.println("Failed to load image using standard Java tools.");
        }

        if (nativeImage != null && javaImage != null && volatileImage != null) {
            displayImages(nativeImage, javaImage, volatileImage);
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

    private static VolatileImage createVolatileImageFromTexture(long texture) {
        GraphicsConfiguration gc = GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice().getDefaultConfiguration();
        Dimension size = NativeHelpers.getTextureSize(texture);
        VolatileImage image = gc.createCompatibleVolatileImage(size.width, size.height);
        image.getGraphics().drawLine(0, 0, size.width, size.height);
        image.getGraphics().drawLine(size.width, 0, 0, size.height);
        long textureFromVolatileImage = NativeHelpers.getTextureFromVolatileImage(image);

        if (image.loadTexture(texture)) {
            return image;
        }
        return image;
    }

    private static void displayImages(BufferedImage nativeImage, BufferedImage javaImage, VolatileImage volatileImage) {
        JFrame frame = new JFrame("Rendered Texture");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setLayout(new BorderLayout());

        JPanel panel = new JPanel() {
            @Override
            protected void paintComponent(Graphics g) {
                super.paintComponent(g);

                int spacing = 20; // Spacing between images and labels

                g.drawImage(javaImage, spacing, spacing, null);
                g.setColor(Color.BLACK);
                g.drawString("Source Image", spacing, javaImage.getHeight() + spacing + 15);

                g.drawImage(nativeImage, javaImage.getWidth() + 2 * spacing, spacing, null);
                g.drawString("BufferedImage from the texture", javaImage.getWidth() + 2 * spacing, nativeImage.getHeight() + spacing + 15);

                g.drawImage(volatileImage, 2 * javaImage.getWidth() + 3 * spacing, spacing, null);
                g.drawString("VolatileImage from the texture", 2 * javaImage.getWidth() + 3 * spacing, volatileImage.getHeight() + spacing + 15);
            }

            @Override
            public Dimension getPreferredSize() {
                int spacing = 20;
                int width = nativeImage.getWidth() + javaImage.getWidth() + 3 * spacing;
                int height = Math.max(nativeImage.getHeight(), javaImage.getHeight()) + 2 * spacing + 15;
                return new Dimension(width, height);
            }
        };

        frame.add(panel, BorderLayout.CENTER);
        frame.pack();
        frame.setVisible(true);
    }
}