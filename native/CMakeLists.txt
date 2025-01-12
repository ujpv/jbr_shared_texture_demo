cmake_minimum_required(VERSION 3.20)

project(native)

# Define the JNI include paths
find_package(JNI REQUIRED)
include_directories(${JNI_INCLUDE_DIRS})

set(CMAKE_CXX_STANDARD 17)

# Add the native source file
add_library(native_helpers SHARED
        org_example_NativeHelpers.cpp
        org_example_NativeHelpers.h
        metal_utils.h
        metal_utils.mm
)

# Macos
find_library(FOUNDATION_FRAMEWORK Foundation REQUIRED)
find_library(APPKIT_FRAMEWORK AppKit REQUIRED)
find_library(METAL_FRAMEWORK Metal REQUIRED)
find_library(METALKIT_FRAMEWORK MetalKit REQUIRED)
find_library(MPS_LIBRARY MetalPerformanceShaders)

# end Macos
# Link JNI to the library
target_link_libraries(native_helpers
        ${JNI_LIBRARIES}
        ${FOUNDATION_FRAMEWORK}
        ${APPKIT_FRAMEWORK}
        ${METAL_FRAMEWORK}
        ${METALKIT_FRAMEWORK}
        ${MPS_LIBRARY}
)
