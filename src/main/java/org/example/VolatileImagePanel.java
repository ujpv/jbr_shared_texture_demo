package org.example;

import javax.swing.*;
import java.awt.*;
import java.awt.image.VolatileImage;
import java.util.concurrent.atomic.AtomicBoolean;

public class VolatileImagePanel extends JPanel {

    private VolatileImage myVolatileImage; // Holds our off-screen hardware-accelerated image
    private Dimension mySize;
    private long myTexture;

    private VolatileImage createVolatileImage() {
        return getGraphicsConfiguration().createCompatibleVolatileImage(mySize.width, mySize.height, Transparency.TRANSLUCENT);
    }

    public void setTexture(long myTexture) {
        this.mySize = NativeHelpers.getMTLTextureSize(myTexture);
        this.myTexture = myTexture;
        setSize(mySize);
        this.repaint();
    }

    @Override
    public boolean imageUpdate(Image img, int infoflags, int x, int y, int w, int h) {
        System.out.println("Image updated: " + infoflags + "(" + new Rectangle(x, y, w, h) + ")");
        return super.imageUpdate(img, infoflags, x, y, w, h);
    }

    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);
        if (mySize != null) {
            int squareSize = Math.min(mySize.width, mySize.height) / 8;
            for (int row = 0; row < 8; row++) {
                for (int col = 0; col < 8; col++) {
                    g.setColor((row + col) % 2 == 0 ? new Color(0, 0, 0, 0) : Color.BLACK);
                    g.fillRect(col * squareSize, row * squareSize, squareSize, squareSize);
                }
            }
        }
        if (mySize == null) {
            g.setColor(Color.RED);
            g.fillRect(0, 0, getWidth(), getHeight());
            g.setColor(Color.WHITE);
            g.drawString("No image", 10, 20);
            return;
        }

        if (myVolatileImage == null ||
                myVolatileImage.getWidth() != mySize.width || myVolatileImage.getHeight() != mySize.height) {
            myVolatileImage = createVolatileImage();
            renderToVolatileImage();
        }

        do {
            int validationCode = myVolatileImage.validate(getGraphicsConfiguration());
            switch (validationCode) {
                case VolatileImage.IMAGE_RESTORED -> {
                    renderToVolatileImage();
                }
                case VolatileImage.IMAGE_INCOMPATIBLE -> {
                    myVolatileImage = createVolatileImage();
                    renderToVolatileImage();
                }
            }
            g.drawImage(myVolatileImage, 0, 0, this);
        } while (myVolatileImage.contentsLost());
    }

    @Override
    public Dimension getPreferredSize() {
        return mySize;
    }

    private void renderToVolatileImage() {
        if (myTexture != 0) {
            long viTexture = NativeHelpers.getTextureFromVolatileImage(myVolatileImage);
            Dimension viSize = NativeHelpers.getMTLTextureSize(NativeHelpers.getTextureFromVolatileImage(myVolatileImage));
            AtomicBoolean result = new AtomicBoolean(false);
            NativeHelpers.RenderQueueFlushAndInvokeNow(() -> {
                result.set(NativeHelpers.scaleMTLTexture(myTexture, viTexture, (double) viSize.width / mySize.height));
            });
            assert result.get();
        }
    }
}