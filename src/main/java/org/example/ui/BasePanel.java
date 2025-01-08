package org.example.ui;

import javax.swing.*;
import java.awt.*;

abstract class BasePanel extends JPanel {
    private final String myName;

    BasePanel(String name) {
        if (name == null) {
            throw new IllegalArgumentException("Arguments must not be null");
        }
        myName = name;
    }

    @Override
    public Dimension getPreferredSize() {
        return getSize();
    }

    @Override
    public Dimension getMaximumSize() {
        return getSize();
    }

    @Override
    public Dimension getMinimumSize() {
        return getSize();
    }

    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);
        paintBackground(g);
        paintContent(g);
        paintName(g);
    }

    protected void paintBackground(Graphics g) {
        int rows = 8;
        int cols = 8;
        int squareSize = Math.min(getWidth() / cols, getHeight() / rows);

        for (int row = 0; row < rows; row++) {
            for (int col = 0; col < cols; col++) {
                if ((row + col) % 2 == 0) {
                    g.setColor(new Color(220, 220, 220));
                } else {
                    g.setColor(new Color(170, 170, 170));
                }
                int x = col * squareSize;
                int y = row * squareSize;
                g.fillRect(x, y, squareSize, squareSize);
            }
        }
    }

    protected abstract void paintContent(Graphics g);

    protected void paintName(Graphics g) {
        int textHeight = g.getFontMetrics().getHeight();
        g.setFont(new Font("Arial", Font.BOLD, 12));
        g.setColor(new Color(255, 255, 255, 150));
        g.fillRect(0, 0, getSize().width, textHeight + 5);
        g.setColor(Color.BLACK);
        g.drawString(myName, 10, textHeight);
    }
}
