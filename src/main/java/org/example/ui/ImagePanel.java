package org.example.ui;

import java.awt.*;

public class ImagePanel extends BasePanel {
    private final Image myImage;

    public ImagePanel(Image image, String name) {
        super(name);
        this.myImage = image;
        setSize(myImage.getWidth(null), myImage.getHeight(null));
    }

    @Override
    protected void paintContent(Graphics g) {
        g.drawImage(myImage, 0, 0, null);
    }
}
