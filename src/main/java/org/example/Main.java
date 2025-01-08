package org.example;

public class Main {
    public static void main(String[] args) {
        System.out.println(NativeHelpers.sayHallo());
        long l = NativeHelpers.loadTextureFromPng("/Users/Vladimir.Kharitonov/develop/jbr_shared_texture_demo/src/Example.png");
        System.out.println("Loaded texture: " + l);
        NativeHelpers.releaseTexture(l);
        System.out.println("Texture released");
    }
}