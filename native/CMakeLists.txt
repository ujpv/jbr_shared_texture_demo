cmake_minimum_required(VERSION 3.20)

project(native)

find_package(JNI REQUIRED)
include_directories(${JNI_INCLUDE_DIRS})

set(CMAKE_CXX_STANDARD 17)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

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
    include(FetchContent)
    FetchContent_Declare(
            DirectXTex
            GIT_REPOSITORY https://github.com/microsoft/DirectXTex.git
            GIT_TAG main
    )
    FetchContent_Declare(
            DirectXHeaders
            GIT_REPOSITORY https://github.com/microsoft/DirectX-Headers.git
            GIT_TAG main
    )
    FetchContent_Declare(
            stb_image
            GIT_REPOSITORY https://github.com/nothings/stb.git
            GIT_TAG origin/master # Use the latest version
    )
    FetchContent_MakeAvailable(DirectXTex DirectXHeaders stb_image)
    set(INCLUDE_DIRS
            ${directxtex_SOURCE_DIR}/DirectXTex
            ${directxheaders_SOURCE_DIR}/include/directx
            ${stb_image_SOURCE_DIR}
    )

    message(STATUS "DirectXTex source directory: ${directxtex_SOURCE_DIR}")
    message(STATUS "DirectX-Headers source directory: ${directxheaders_SOURCE_DIR}")

    list(APPEND SOURCES
            windows_utils.h
            windows_utils.cpp
    )

    list(APPEND FRAMEWORKS
            d3d9
            d3d12
            dxgi
            dxguid
            DirectXTex
    )
else ()
    message(FATAL_ERROR "${CMAKE_SYSTEM_NAME} is not supported")
endif ()

add_library(native_helpers SHARED ${SOURCES})

target_link_libraries(native_helpers ${FRAMEWORKS})

if (INCLUDE_DIRS)
    message(STATUS "Include directories: ${INCLUDE_DIRS}")
    target_include_directories(native_helpers PRIVATE ${INCLUDE_DIRS})
endif()