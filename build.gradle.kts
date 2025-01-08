plugins {
    id("java")
    id("cpp")
}

group = "org.example"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    testImplementation(platform("org.junit:junit-bom:5.10.0"))
    testImplementation("org.junit.jupiter:junit-jupiter")
}

tasks.test {
    useJUnitPlatform()
}

val nativeDir: String = file("${projectDir}/native").absolutePath
val buildNativeDir: String = layout.buildDirectory.dir("native").get().asFile.absolutePath

tasks.withType<JavaCompile> {
    options.compilerArgs.addAll(listOf("-h", nativeDir))
}

tasks.register("checkNative") {
    doLast {
        println("Sources dir: $buildNativeDir")
        println("Build dir: $buildNativeDir")
        println("Checking if CMake is installed...")
        exec {
            commandLine = listOf("cmake", "--version")
        }
    }
}

tasks.register("configureNative") {
    dependsOn("compileJava", "checkNative")
    doLast {
        println("Configuring native build using CMake...")
        exec {
            commandLine = listOf("cmake", "-S", nativeDir, "-B", buildNativeDir)
        }
    }
}

tasks.register("buildNative") {
    dependsOn("configureNative")
    doLast {
        println("Building native...")
        exec {
            commandLine = listOf("cmake", "--build", buildNativeDir, "--config", "Release")
        }
    }
}

tasks.build {
    dependsOn("buildNative")
}