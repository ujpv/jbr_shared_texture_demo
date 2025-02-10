package org.example;

import java.awt.*;
import java.awt.image.MemoryImageSource;

public class RasterWrapper {
    public static Image wrap(long pRaster, int width, int height) {
        return Toolkit.getDefaultToolkit().createImage(new MemoryImageSource(width, height, pRaster, 0, width));
    }
}
