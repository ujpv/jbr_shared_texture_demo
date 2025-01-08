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
    testImplementation(platform("org.junit:junit-bom:5.10.0"))
    testImplementation("org.junit.jupiter:junit-jupiter")
    implementation("com.jetbrains:jbr-api:SNAPSHOT")
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

    // Define the main class to execute
    mainClass.set("org.example.Main") // Replace `com.example.Main` with your actual main class

    // Include the runtime classpath
    classpath = sourceSets["main"].runtimeClasspath

    // Optional: Pass JVM arguments (if needed)
    jvmArgs = listOf("-Djava.library.path=${buildNativeDir}") // Example JVM options (optional)
}

tasks.register<JavaExec>("runXint") {
    group = "application"
    description = "Runs the main class of the application."

    // Define the main class to execute
    mainClass.set("org.example.Main") // Replace `com.example.Main` with your actual main class

    // Include the runtime classpath
    classpath = sourceSets["main"].runtimeClasspath

    // Optional: Pass JVM arguments (if needed)
    jvmArgs = listOf("-Djava.library.path=${buildNativeDir}", "-Xint") // Example JVM options (optional)
}
