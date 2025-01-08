cmake_minimum_required(VERSION 3.20)

project(native)

# Define the JNI include paths
find_package(JNI REQUIRED)
include_directories(${JNI_INCLUDE_DIRS})

# Add the native source file
add_library(native_helpers SHARED
        org_example_NativeHelpers.cpp
        org_example_NativeHelpers.h
)

# Link JNI to the library
target_link_libraries(native_helpers ${JNI_LIBRARIES})
