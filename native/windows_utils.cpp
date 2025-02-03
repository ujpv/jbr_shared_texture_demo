#include "windows_utils.h"

#include <d3d12.h>
#include <d3dx12.h>
#include <DirectXTex.h>
#include <stdexcept>
#include <wrl/client.h>
#include <wincodec.h>
#include <sstream>

#include <dxgidebug.h>
#include <iostream>

#define STB_IMAGE_IMPLEMENTATION

#include <stb_image.h>

#define STB_IMAGE_WRITE_IMPLEMENTATION

#include <stb_image_write.h>

namespace {
    void notImplemented(JNIEnv *env) {
        env->ThrowNew(env->FindClass("java/lang/UnsupportedOperationException"), "Not implemented");
    }
}

namespace platform_utils {
    jlong loadIOSurfaceFromPNG(JNIEnv *env, const std::string &path) {
        notImplemented(env);
        return 0;
    }

    jlong getMTLTextureFromIOSurface(JNIEnv *env, jlong pIOSurface) {
        notImplemented(env);
        return 0;
    }

    jlong getOpenGLTextureFromIOSurface(JNIEnv *env, jlong pIOSurface) {
        notImplemented(env);
        return 0;
    }

    bool createOpenGLContext(JNIEnv *env, jlong sharedContex, jlong pixelFormat) {
        notImplemented(env);
        return false;
    }

    jlong loadOpenGLTextureFromPNG(JNIEnv *env, const std::string &path) {
        notImplemented(env);
        return 0;
    }

    bool saveOpenGLTextureToPNG(JNIEnv *env, jlong textureId, const std::string &path) {
        notImplemented(env);
        return false;
    }

    jlong loadMTLTextureFromPNG(JNIEnv *env, const std::string &path) {
        notImplemented(env);
        return 0;
    }

    void releaseMTLTexture(JNIEnv *env, jlong) {
        notImplemented(env);
    }

    jboolean scaleMTLTexture(JNIEnv *env, jlong pSrc, jlong dDst, jdouble scale) {
        notImplemented(env);
        return 0;
    }

    jboolean copyMTLTexture(JNIEnv *env, jlong pSrc, jlong pDst) {
        notImplemented(env);
        return 0;
    }

    jbyteArray MTLTextureToByteArray(JNIEnv *env, jlong ptr) {
        notImplemented(env);
        return nullptr;
    }

    std::pair<int, int> getMTLTextureSize(JNIEnv *env, jlong ptr) {
        notImplemented(env);
        return std::pair<int, int>();
    }

    jlong getTextureFromVolatileImage(JNIEnv *env, jobject vi) {
        notImplemented(env);
        return 0;
    }

    void releaseOpenGLTexture(JNIEnv *env, jlong texture) {
        notImplemented(env);
    }

    jlong loadD3D12TextureFromPNG(JNIEnv *env, const std::string &filename) {
        // Load the PNG file using stb_image
        int width, height, channels;
        unsigned char *data = stbi_load(filename.c_str(), &width, &height, &channels, 4); // Force 4 channels (RGBA)
        if (!data) {
            std::cerr << "Failed to load PNG image: " << stbi_failure_reason() << std::endl;
            return 0; // Return 0 on failure
        }

        // Print image details for debugging
        std::cout << "Image loaded: " << filename << std::endl;
        std::cout << "Width: " << width << ", Height: " << height << ", Channels: " << channels << std::endl;

        Microsoft::WRL::ComPtr<ID3D12Device> device;

        // Create D3D12 device
        HRESULT hr = D3D12CreateDevice(nullptr, D3D_FEATURE_LEVEL_12_0, IID_PPV_ARGS(&device));
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create D3D12 device. HRESULT: " << std::hex << hr << std::endl;
            stbi_image_free(data);
            return 0;
        }

        // Describe the texture
        D3D12_RESOURCE_DESC textureDesc = {};
        textureDesc.Width = static_cast<UINT>(width);
        textureDesc.Height = static_cast<UINT>(height);
        textureDesc.DepthOrArraySize = 1; // Single image, no array
        textureDesc.MipLevels = 1; // One MIP level
        textureDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM; // Assuming 4-channel RGBA (stb_image forces this)
        textureDesc.SampleDesc.Count = 1; // No multisampling
        textureDesc.SampleDesc.Quality = 0;
        textureDesc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
        textureDesc.Layout = D3D12_TEXTURE_LAYOUT_UNKNOWN;
        textureDesc.Flags = D3D12_RESOURCE_FLAG_NONE;

        const CD3DX12_HEAP_PROPERTIES defaultHeapProps(D3D12_HEAP_TYPE_DEFAULT);

        // Create the texture resource
        Microsoft::WRL::ComPtr<ID3D12Resource> texture;
        hr = device->CreateCommittedResource(
                &defaultHeapProps,
                D3D12_HEAP_FLAG_SHARED,
                &textureDesc,
                D3D12_RESOURCE_STATE_COPY_DEST, // Start in copy-destination state for upload
                nullptr,
                IID_PPV_ARGS(&texture)
        );
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create D3D12 texture resource. HRESULT: " << std::hex << hr << std::endl;
            stbi_image_free(data);
            return 0;
        }

        // Create an intermediate upload heap
        const UINT64 uploadBufferSize = GetRequiredIntermediateSize(texture.Get(), 0, 1);
        const CD3DX12_HEAP_PROPERTIES uploadHeapProps(D3D12_HEAP_TYPE_UPLOAD);
        const CD3DX12_RESOURCE_DESC bufferDesc = CD3DX12_RESOURCE_DESC::Buffer(uploadBufferSize);

        Microsoft::WRL::ComPtr<ID3D12Resource> uploadHeap;
        hr = device->CreateCommittedResource(
                &uploadHeapProps,
                D3D12_HEAP_FLAG_NONE,
                &bufferDesc,
                D3D12_RESOURCE_STATE_GENERIC_READ,
                nullptr,
                IID_PPV_ARGS(&uploadHeap)
        );
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create D3D12 upload heap. HRESULT: " << std::hex << hr << std::endl;
            stbi_image_free(data);
            return 0;
        }

        // Map the upload heap and copy the texture data
        D3D12_SUBRESOURCE_DATA textureData = {};
        textureData.pData = data; // Pointer to the RGBA texture data
        textureData.RowPitch = static_cast<LONG_PTR>(width * 4); // 4 bytes per pixel (RGBA)
        textureData.SlicePitch = textureData.RowPitch * height;

        Microsoft::WRL::ComPtr<ID3D12CommandAllocator> commandAllocator;
        Microsoft::WRL::ComPtr<ID3D12GraphicsCommandList> commandList;
        Microsoft::WRL::ComPtr<ID3D12CommandQueue> commandQueue;

        // Create command components
        hr = device->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, IID_PPV_ARGS(&commandAllocator));
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create command allocator. HRESULT: " << std::hex << hr << std::endl;
            stbi_image_free(data);
            return 0;
        }

        hr = device->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT, commandAllocator.Get(), nullptr,
                                       IID_PPV_ARGS(&commandList));
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create command list. HRESULT: " << std::hex << hr << std::endl;
            stbi_image_free(data);
            return 0;
        }

        // Copy texture data to GPU
        UpdateSubresources(commandList.Get(), texture.Get(), uploadHeap.Get(), 0, 0, 1, &textureData);

        // Transition texture to GENERIC_READ state
        const CD3DX12_RESOURCE_BARRIER barrier = CD3DX12_RESOURCE_BARRIER::Transition(
                texture.Get(),
                D3D12_RESOURCE_STATE_COPY_DEST,
                D3D12_RESOURCE_STATE_GENERIC_READ
        );
        commandList->ResourceBarrier(1, &barrier);

        // Execute copy commands
        hr = commandList->Close();
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to close command list. HRESULT: " << std::hex << hr << std::endl;
            stbi_image_free(data);
            return 0;
        }

        // Get a command queue
        D3D12_COMMAND_QUEUE_DESC queueDesc = {};
        queueDesc.Flags = D3D12_COMMAND_QUEUE_FLAG_NONE;
        queueDesc.Type = D3D12_COMMAND_LIST_TYPE_DIRECT;

        hr = device->CreateCommandQueue(&queueDesc, IID_PPV_ARGS(&commandQueue));
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create command queue. HRESULT: " << std::hex << hr << std::endl;
            stbi_image_free(data);
            return 0;
        }

        ID3D12CommandList *commandLists[] = {commandList.Get()};
        commandQueue->ExecuteCommandLists(1, commandLists);

        // Create a shared handle
        HANDLE sharedHandle = nullptr;
        hr = device->CreateSharedHandle(
                texture.Get(),
                nullptr,
                GENERIC_ALL,
                nullptr,
                &sharedHandle
        );
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create shared handle. HRESULT: " << std::hex << hr << std::endl;
            stbi_image_free(data);
            return 0;
        }

        // Free the CPU texture data
        stbi_image_free(data);

        // Return the shared handle as a jlong
        return reinterpret_cast<jlong>(sharedHandle);
    }

    bool saveD3D12TextureToPNG(JNIEnv *env, const std::string &filename, jlong handle) {
        auto sharedHandle = reinterpret_cast<HANDLE>(handle);

        // Create D3D12 device
        Microsoft::WRL::ComPtr<ID3D12Device> device;
        HRESULT hr = D3D12CreateDevice(nullptr, D3D_FEATURE_LEVEL_12_0, IID_PPV_ARGS(&device));
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create D3D12 device (HRESULT: " << std::hex << hr << ")\n";
            return false;
        }

        // Open the shared handle to get the texture resource
        Microsoft::WRL::ComPtr<ID3D12Resource> texture;
        hr = device->OpenSharedHandle(sharedHandle, IID_PPV_ARGS(&texture));
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to open shared handle (HRESULT: " << std::hex << hr << ")\n";
            return false;
        }

        // Get texture descriptor
        const D3D12_RESOURCE_DESC textureDesc = texture->GetDesc();
        if (textureDesc.Dimension != D3D12_RESOURCE_DIMENSION_TEXTURE2D) {
            std::cerr << "Error: The resource is not a 2D texture\n";
            return false;
        }

        if (textureDesc.SampleDesc.Count > 1) {
            std::cerr << "Error: Multi-sampled textures are not supported\n";
            return false;
        }

        // Log texture format and dimensions
        std::cerr << "Texture width: " << textureDesc.Width
                  << ", height: " << textureDesc.Height
                  << ", format: " << textureDesc.Format << "\n";

        // Get the texture layout and size
        UINT64 footprintSize = 0;
        D3D12_PLACED_SUBRESOURCE_FOOTPRINT layout = {};
        UINT rowCount = 0;
        UINT64 rowSizeInBytes = 0;
        device->GetCopyableFootprints(&textureDesc, 0, 1, 0, &layout, &rowCount, &rowSizeInBytes, &footprintSize);

        std::cerr << "Footprint size: " << footprintSize << ", Row pitch: " << layout.Footprint.RowPitch << "\n";
        std::cerr << "Validating footprint and buffer configuration...\n";
        std::cerr << "  Footprint size: " << footprintSize << "\n";
        std::cerr << "  Row pitch: " << layout.Footprint.RowPitch << "\n";
        std::cerr << "  Texture Width: " << textureDesc.Width << ", Texture Height: " << textureDesc.Height << "\n";


        // Define heap properties for reading back
        D3D12_HEAP_PROPERTIES heapProperties = {};
        heapProperties.Type = D3D12_HEAP_TYPE_READBACK;
        heapProperties.CPUPageProperty = D3D12_CPU_PAGE_PROPERTY_UNKNOWN;
        heapProperties.MemoryPoolPreference = D3D12_MEMORY_POOL_UNKNOWN;
        heapProperties.CreationNodeMask = 1;
        heapProperties.VisibleNodeMask = 1;

        // Define resource description for the buffer
        D3D12_RESOURCE_DESC bufferDesc = {};
        bufferDesc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
        bufferDesc.Alignment = 0; // Alignment for buffers is 0 by default
        bufferDesc.Width = footprintSize; // Size of the memory required (validated above)
        bufferDesc.Height = 1; // Buffers always have height = 1
        bufferDesc.DepthOrArraySize = 1; // Buffers use 1 for depth/array size
        bufferDesc.MipLevels = 1; // Buffers have only one level
        bufferDesc.Format = DXGI_FORMAT_UNKNOWN; // Format must be unknown for buffers
        bufferDesc.SampleDesc.Count = 1; // Not multi-sampled
        bufferDesc.SampleDesc.Quality = 0;
        bufferDesc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR; // Buffers are laid out row by row
        bufferDesc.Flags = D3D12_RESOURCE_FLAG_NONE; // No special flags

        // Log configuration for debugging
        std::cerr << "Readback Buffer Configuration:\n";
        std::cerr << "  Width (footprint size): " << bufferDesc.Width << "\n";
        std::cerr << "  Layout: Row Major\n";

        // Create the committed resource (readback buffer)
        Microsoft::WRL::ComPtr<ID3D12Resource> readbackBuffer;
        hr = device->CreateCommittedResource(
                &heapProperties,               // Heap properties (readback type)
                D3D12_HEAP_FLAG_NONE,          // No special heap flags
                &bufferDesc,                   // Buffer resource description
                D3D12_RESOURCE_STATE_COPY_DEST, // Resource state: copy destination
                nullptr,                       // No optimized clear value for buffers
                IID_PPV_ARGS(&readbackBuffer)  // Output: readback buffer
        );

        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create readback buffer (HRESULT: " << std::hex << hr << ")\n";
            if (hr == E_INVALIDARG) {
                std::cerr << "  Reason: Invalid arguments were passed to CreateCommittedResource.\n";
            }
            return false;
        }

        // Create a command queue and list
        Microsoft::WRL::ComPtr<ID3D12CommandQueue> commandQueue;
        D3D12_COMMAND_QUEUE_DESC queueDesc = {};
        queueDesc.Type = D3D12_COMMAND_LIST_TYPE_DIRECT;
        hr = device->CreateCommandQueue(&queueDesc, IID_PPV_ARGS(&commandQueue));
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create command queue (HRESULT: " << std::hex << hr << ")\n";
            return false;
        }

        Microsoft::WRL::ComPtr<ID3D12CommandAllocator> commandAllocator;
        hr = device->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, IID_PPV_ARGS(&commandAllocator));
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create command allocator (HRESULT: " << std::hex << hr << ")\n";
            return false;
        }

        Microsoft::WRL::ComPtr<ID3D12GraphicsCommandList> commandList;
        hr = device->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT, commandAllocator.Get(), nullptr,
                                       IID_PPV_ARGS(&commandList));
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create command list (HRESULT: " << std::hex << hr << ")\n";
            return false;
        }

        // Transition the texture to COPY_SOURCE
        D3D12_RESOURCE_BARRIER barrier = {};
        barrier.Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
        barrier.Transition.pResource = texture.Get();
        barrier.Transition.StateBefore = D3D12_RESOURCE_STATE_COMMON; // Adjust according to upstream usage
        barrier.Transition.StateAfter = D3D12_RESOURCE_STATE_COPY_SOURCE;
        barrier.Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;

        commandList->ResourceBarrier(1, &barrier);

        // Copy texture to readback buffer
        D3D12_TEXTURE_COPY_LOCATION srcLocation = {};
        srcLocation.pResource = texture.Get();
        srcLocation.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
        srcLocation.SubresourceIndex = 0;

        D3D12_TEXTURE_COPY_LOCATION destLocation = {};
        destLocation.pResource = readbackBuffer.Get();
        destLocation.Type = D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
        destLocation.PlacedFootprint = layout;

        commandList->CopyTextureRegion(&destLocation, 0, 0, 0, &srcLocation, nullptr);

        // Execute the command list
        commandList->Close();
        ID3D12CommandList *commandLists[] = {commandList.Get()};
        commandQueue->ExecuteCommandLists(1, commandLists);

        // Synchronize operations
        Microsoft::WRL::ComPtr<ID3D12Fence> fence;
        hr = device->CreateFence(0, D3D12_FENCE_FLAG_NONE, IID_PPV_ARGS(&fence));
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create fence (HRESULT: " << std::hex << hr << ")\n";
            return false;
        }

        HANDLE fenceEvent = CreateEvent(nullptr, FALSE, FALSE, nullptr);
        if (!fenceEvent) {
            std::cerr << "Error: Failed to create fence event\n";
            return false;
        }

        commandQueue->Signal(fence.Get(), 1);
        fence->SetEventOnCompletion(1, fenceEvent);
        WaitForSingleObject(fenceEvent, INFINITE);
        CloseHandle(fenceEvent);

        // Map the readback buffer
        void *mappedData = nullptr;
        D3D12_RANGE readRange = {0, static_cast<SIZE_T>(footprintSize)};
        hr = readbackBuffer->Map(0, &readRange, &mappedData);
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to map the readback buffer (HRESULT: " << std::hex << hr << ")\n";
            return false;
        }

        // Correct row pitch and save the image
        std::vector<uint8_t> alignedPixels(textureDesc.Width * textureDesc.Height * 4);
        auto *sourceRow = static_cast<uint8_t *>(mappedData);

        for (UINT y = 0; y < textureDesc.Height; ++y) {
            memcpy(&alignedPixels[y * textureDesc.Width * 4],
                   sourceRow + y * layout.Footprint.RowPitch,
                   textureDesc.Width * 4);
        }

        readbackBuffer->Unmap(0, nullptr);

        // Save PNG
        if (!stbi_write_png(filename.c_str(), textureDesc.Width, textureDesc.Height, 4, alignedPixels.data(),
                            textureDesc.Width * 4)) {
            std::cerr << "Error: Failed to write PNG file\n";
            return false;
        }

        std::cerr << "Success: Image saved to " << filename << "\n";
        return true;
    }

    void releaseD3D12Texture(JNIEnv *env, jlong handle) {
        try {
            auto sharedHandle = reinterpret_cast<HANDLE>(handle);

            Microsoft::WRL::ComPtr<ID3D12Device> device;
            HRESULT hr = D3D12CreateDevice(nullptr, D3D_FEATURE_LEVEL_12_0, IID_PPV_ARGS(&device));
            if (FAILED(hr)) {
                throw std::runtime_error("Failed to create D3D12 device");
            }

            Microsoft::WRL::ComPtr<ID3D12Resource> textureResource;
            hr = device->OpenSharedHandle(sharedHandle, IID_PPV_ARGS(&textureResource));
            if (FAILED(hr)) {
                throw std::runtime_error("Failed to open shared handle");
            }

            textureResource.Reset();

            if (sharedHandle) {
                CloseHandle(sharedHandle);
            }
        } catch (const std::exception &e) {
            OutputDebugStringA(e.what());
        }
    }
}