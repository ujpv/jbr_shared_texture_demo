package org.example.ui;

import com.jetbrains.JBR;

import java.awt.*;
import java.awt.image.VolatileImage;

public class TextureToVolatileImage extends BasePanel {
    private final long myTexture;
    private VolatileImage myVolatileImage;

    public TextureToVolatileImage(long texture, String name) {
        super(name);
        myTexture = texture;
        GraphicsConfiguration defaultConfiguration = GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice().getDefaultConfiguration();
        myVolatileImage = createVolatileImage(defaultConfiguration, myTexture);
        drawVolatileImage(defaultConfiguration, myTexture, myVolatileImage);
        setSize(myVolatileImage.getWidth(), myVolatileImage.getHeight());
    }

    @Override
    protected void paintContent(Graphics g) {
        Graphics2D g2d = (Graphics2D) g;
        if (myVolatileImage == null) {
            myVolatileImage = createVolatileImage(g2d.getDeviceConfiguration(), myTexture);
            drawVolatileImage(g2d.getDeviceConfiguration(), myTexture, myVolatileImage);
            setSize(myVolatileImage.getWidth(), myVolatileImage.getHeight());
        }

        do {
            int status = myVolatileImage.validate(g2d.getDeviceConfiguration());
            switch (status) {
                case VolatileImage.IMAGE_INCOMPATIBLE:
                    myVolatileImage = createVolatileImage(g2d.getDeviceConfiguration(), myTexture);
                    drawVolatileImage(g2d.getDeviceConfiguration(), myTexture, myVolatileImage);
                    setSize(myVolatileImage.getWidth(), myVolatileImage.getHeight());
                    break;
                case VolatileImage.IMAGE_RESTORED:
                    drawVolatileImage(g2d.getDeviceConfiguration(), myTexture, myVolatileImage);
                    break;
                case VolatileImage.IMAGE_OK:
                    return;
            }
            g2d.drawImage(myVolatileImage, 0, 0, null);
        } while (!myVolatileImage.contentsLost());
    }

    private static VolatileImage createVolatileImage(GraphicsConfiguration gc, long texture) {
        Image texImage = JBR.getSharedTextures().wrapTexture(gc, texture);
        return gc.createCompatibleVolatileImage(texImage.getWidth(null), texImage.getHeight(null), Transparency.TRANSLUCENT);
    }

    private static void drawVolatileImage(GraphicsConfiguration gc, long texture, VolatileImage vi) {
        Graphics2D g2d = vi.createGraphics();
        try {
            Image texImage = JBR.getSharedTextures().wrapTexture(gc, texture);
            g2d.setComposite(AlphaComposite.Clear);
            g2d.fillRect(0, 0, vi.getWidth(), vi.getHeight());
            g2d.setComposite(AlphaComposite.SrcOver);
            g2d.drawImage(texImage, 0, 0, null);
        } finally {
            g2d.dispose();
        }
    }
}
