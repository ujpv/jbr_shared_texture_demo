plugins {
    id("java")
    id("cpp")
}

group = "org.example"
version = "1.0-SNAPSHOT"

repositories {
    mavenLocal()
    mavenCentral()
}

dependencies {
    implementation("com.jetbrains:jbr-api:SNAPSHOT")
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
            commandLine = listOf("cmake", "-DCMAKE_BUILD_TYPE=Debug", "-S", nativeDir, "-B", buildNativeDir)
        }
    }
}

tasks.register("buildNative") {
    dependsOn("configureNative")
    doLast {
        println("Building native...")
        exec {
            commandLine = listOf("cmake", "--build", buildNativeDir, "--config", "Debug")
        }
    }
}

tasks.build {
    dependsOn("buildNative")
}

tasks.named("classes") {
    dependsOn("buildNative")
}

tasks.register<JavaExec>("run") {
    group = "application"
    description = "Runs the main class of the application."

    mainClass.set("org.example.Main")

    classpath = sourceSets["main"].runtimeClasspath

    jvmArgs = (project.findProperty("org.gradle.jvmargs")?.toString()?.split(" ") ?: emptyList()) + "-Djava.library.path=${buildNativeDir}"
}
