package org.example;

import javax.imageio.ImageIO;
import javax.swing.*;
import java.awt.*;
import java.awt.image.*;
import java.io.File;
import java.io.IOException;

public class Main {
    public static void main(String[] args) throws IOException {
        String filename = "data/simple_shapes_example.png";

        JComponent originalImage =new ImagePanel(ImageIO.read(new File(filename)));

        long ptr = NativeHelpers.loadTextureFromPng(filename);
        JComponent bufferedImage = new ImagePanel(fromTexture(ptr));

        VolatileImagePanel volatileImage = new VolatileImagePanel();
        volatileImage.setTexture(ptr);

        JPanel panel = new JPanel();
        panel.setLayout(new BoxLayout(panel, BoxLayout.X_AXIS));
        panel.add(originalImage);
        panel.add(Box.createHorizontalStrut(10));
        panel.add(bufferedImage);
        panel.add(Box.createHorizontalStrut(10));
        panel.add(volatileImage);

        JFrame frame = new JFrame("Texture Renderer");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.add(panel);
        frame.pack();
        frame.setVisible(true);
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

    private static class ImagePanel extends JPanel {
        private final Image myImage;
        ImagePanel(Image image) {
            if (image == null) {
                throw new IllegalArgumentException("Image must not be null");
            }
            myImage = image;
            setSize(image.getWidth(null), image.getHeight(null));
        }

        @Override
        public Dimension getSize() {
            return new Dimension(myImage.getWidth(null), myImage.getHeight(null));
        }

        @Override
        public Dimension getPreferredSize() {
            return new Dimension(myImage.getWidth(null), myImage.getHeight(null));
        }

        @Override
        protected void paintComponent(Graphics g) {
            super.paintComponent(g);
            g.drawImage(myImage, 0, 0, this);
        }
    }
}