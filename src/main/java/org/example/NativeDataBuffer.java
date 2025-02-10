package org.example;

import sun.misc.Unsafe;

import java.awt.image.DataBuffer;
import java.lang.reflect.Field;

public class NativeDataBuffer extends DataBuffer {
    private final long nativePointer; // Pointer to native memory
    private final int bufferSize;     // Total size of the buffer in bytes

    private final static Unsafe UNSAFE;

    static {
        try {
            Field unsafeField = Unsafe.class.getDeclaredField("theUnsafe");
            unsafeField.setAccessible(true);
            UNSAFE = (Unsafe) unsafeField.get(null);
        } catch (Exception e) {
            throw new RuntimeException("Unable to access Unsafe", e);
        }
    }

    public NativeDataBuffer(long nativePointer, int size) {
        super(DataBuffer.TYPE_BYTE, size);
        this.nativePointer = nativePointer;
        this.bufferSize = size;
    }

    @Override
    public int getElem(int bank, int index) {
        if (index < 0 || index >= bufferSize) {
            throw new IndexOutOfBoundsException("Index out of bounds for native buffer: " + index);
        }
        // Read a byte from native memory and convert to unsigned int
        return UNSAFE.getByte(nativePointer + index) & 0xFF;
    }

    @Override
    public void setElem(int bank, int index, int value) {
        throw new UnsupportedOperationException("This NativeDataBuffer is read-only.");
    }
}
