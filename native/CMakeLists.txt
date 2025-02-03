cmake_minimum_required(VERSION 3.20)

project(native)

find_package(JNI REQUIRED)
include_directories(${JNI_INCLUDE_DIRS})

set(CMAKE_CXX_STANDARD 17)

set(SOURCES
        org_example_NativeHelpers.cpp
        org_example_NativeHelpers.h
)

set(FRAMEWORKS ${JNI_LIBRARIES})

if (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    add_definitions(-DGL_SILENCE_DEPRECATION)

    list(APPEND SOURCES
            metal_utils.h
            metal_utils.mm
    )

    find_library(FOUNDATION_FRAMEWORK Foundation REQUIRED)
    find_library(APPKIT_FRAMEWORK AppKit REQUIRED)
    find_library(METAL_FRAMEWORK Metal REQUIRED)
    find_library(METALKIT_FRAMEWORK MetalKit REQUIRED)
    find_library(MPS_LIBRARY MetalPerformanceShaders REQUIRED)
    find_library(OPEN_GL_FRAMEWORK OpenGL REQUIRED)
    find_library(IO_SURFACE_FRAMEWORK IOSurface REQUIRED)
    find_library(CORE_GRAPHICS_FRAMEWORK CoreGraphics REQUIRED)

    list(APPEND FRAMEWORKS
            ${JNI_LIBRARIES}
            ${FOUNDATION_FRAMEWORK}
            ${APPKIT_FRAMEWORK}
            ${METAL_FRAMEWORK}
            ${METALKIT_FRAMEWORK}
            ${MPS_LIBRARY}
            ${OPEN_GL_FRAMEWORK}
            ${IO_SURFACE_FRAMEWORK}
            ${CORE_GRAPHICS_FRAMEWORK}
    )
elseif (CMAKE_SYSTEM_NAME STREQUAL "Linux")
    list(APPEND SOURCES
            linux_utils.h
            linux_utils.cpp
    )
elseif (CMAKE_SYSTEM_NAME STREQUAL "Windows")
    list(APPEND SOURCES
            windows_utils.h
            windows_utils.cpp
    )
else ()
    message(FATAL_ERROR "${CMAKE_SYSTEM_NAME} is not supported")
endif ()

add_library(native_helpers SHARED ${SOURCES})

target_link_libraries(native_helpers ${FRAMEWORKS})
