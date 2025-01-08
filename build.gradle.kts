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

val nativeDir = "${projectDir}/native"
tasks.withType<JavaCompile> {
    options.compilerArgs.addAll(listOf("-h", nativeDir))
}

tasks.register("checkCmake") {
    doLast {
        println("Checking if CMake is installed...")
        exec {
            commandLine = listOf("/opt/homebrew/bin/cmake", "--version")
        }
    }
}

tasks.register("configureNative") {
    dependsOn("compileJava", "checkCmake")
    doLast {
        println("Configuring native build using CMake...")
        exec {
            commandLine = listOf("cmake", "-S", "${nativeDir}/.", "-B", "${nativeDir}/build"/*, "--config", "Release"*/)
        }
    }
}

tasks.register("buildNative") {
    dependsOn("configureNative")
    doLast {
        println("Building native...")
        exec {
            commandLine = listOf("cmake", "--build", "${nativeDir}/build"/*, "--config", "Release"*/)
        }
    }
}

tasks.build {
    dependsOn("buildNative")
}