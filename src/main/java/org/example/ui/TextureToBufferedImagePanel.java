package org.example.ui;

import com.jetbrains.JBR;

import java.awt.*;
import java.awt.image.BufferedImage;

public class TextureToBufferedImagePanel extends BasePanel {
    long myTexture;
    BufferedImage myBufferedImage;
    GraphicsConfiguration myGc =
            GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice().getDefaultConfiguration();

    public TextureToBufferedImagePanel(long texture, String name) {
        super(name);
        myTexture = texture;
        myBufferedImage = createImage(myGc, myTexture);
        setSize(myBufferedImage.getWidth(), myBufferedImage.getHeight());
    }

    @Override
    protected void paintContent(Graphics g) {
        Graphics2D g2d = (Graphics2D) g;
        if (myGc != g2d.getDeviceConfiguration()) {
            myBufferedImage = createImage(myGc, myTexture);
            setSize(myBufferedImage.getWidth(), myBufferedImage.getHeight());
        }

        g2d.drawImage(myBufferedImage, 0, 0, null);
    }

    private static BufferedImage createImage(GraphicsConfiguration gc, long texture) {
        Image texImage = JBR.getSharedTextures().wrapTexture(gc, texture);
        BufferedImage image = gc.createCompatibleImage(texImage.getWidth(null), texImage.getHeight(null), Transparency.TRANSLUCENT);
                new BufferedImage(texImage.getWidth(null), texImage.getHeight(null), BufferedImage.TYPE_INT_ARGB);
        Graphics2D g2d = image.createGraphics();
        g2d.drawImage(texImage, 0, 0, null);
        g2d.dispose();
        return image;
    }
}
