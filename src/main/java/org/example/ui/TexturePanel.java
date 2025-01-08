package org.example.ui;

import com.jetbrains.JBR;
import org.example.ui.BasePanel;

import java.awt.*;

public class TexturePanel extends BasePanel {
    long myTexture;
    Image myImage;
    GraphicsConfiguration myGc =
            GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice().getDefaultConfiguration();

    public TexturePanel(long texture, String name) {
        super(name);
        myTexture = texture;
        myImage = JBR.getSharedTextures().wrapTexture(myGc, texture);
        setSize(myImage.getWidth(null), myImage.getHeight(null));
    }

    @Override
    protected void paintContent(Graphics g) {
        Graphics2D g2d = (Graphics2D) g;
        GraphicsConfiguration config = g2d.getDeviceConfiguration();
        if (config != myGc) {
            myGc = config;
            myImage = JBR.getSharedTextures().wrapTexture(myGc, myTexture);
            setSize(myImage.getWidth(null), myImage.getHeight(null));
        }
        g2d.drawImage(myImage, 0, 0, null);
    }
}
