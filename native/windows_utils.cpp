#define D3D_DEBUG_INFO
#include "windows_utils.h"

#include <d3d12.h>
#include <d3dx12.h>
#include <d3d9.h>
#include <windows.h>
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
        // Load texture data from file
        int width, height, channels;
        unsigned char *data = stbi_load(filename.c_str(), &width, &height, &channels, 4); // Force RGBA
        if (!data) {
            std::cerr << "Error: Failed to load PNG file: " << stbi_failure_reason() << std::endl;
            return 0; // Failure
        }

        std::cout << "Loaded PNG: " << filename << " (" << width << "x" << height << ")\n";

        // Create D3D12 device
        Microsoft::WRL::ComPtr<ID3D12Device> device;
        HRESULT hr = D3D12CreateDevice(nullptr, D3D_FEATURE_LEVEL_12_0, IID_PPV_ARGS(&device));
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create D3D12 device. HRESULT: " << std::hex << hr << std::endl;
            stbi_image_free(data);
            return 0;
        }

        // Describe the shared texture
        D3D12_RESOURCE_DESC textureDesc = {};
        textureDesc.Width = static_cast<UINT>(width);
        textureDesc.Height = static_cast<UINT>(height);
        textureDesc.DepthOrArraySize = 1;
        textureDesc.MipLevels = 1;
        textureDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
        textureDesc.SampleDesc.Count = 1;
        textureDesc.SampleDesc.Quality = 0;
        textureDesc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
        textureDesc.Layout = D3D12_TEXTURE_LAYOUT_UNKNOWN;
        textureDesc.Flags = D3D12_RESOURCE_FLAG_ALLOW_SIMULTANEOUS_ACCESS;

        // Create a shared heap for the texture
        const CD3DX12_HEAP_PROPERTIES heapProps(D3D12_HEAP_TYPE_DEFAULT, 0, D3D12_HEAP_FLAG_SHARED);

        Microsoft::WRL::ComPtr<ID3D12Resource> texture;
        hr = device->CreateCommittedResource(
                &heapProps,
                D3D12_HEAP_FLAG_SHARED, // Enables sharing
                &textureDesc,
                D3D12_RESOURCE_STATE_COPY_DEST, // Initially set for GPU copy
                nullptr,
                IID_PPV_ARGS(&texture)
        );
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create shared texture resource. HRESULT: " << std::hex << hr << std::endl;
            stbi_image_free(data);
            return 0;
        }

        // Upload texture data to GPU
        UINT64 uploadBufferSize = GetRequiredIntermediateSize(texture.Get(), 0, 1);
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
            std::cerr << "Error: Failed to create upload heap. HRESULT: " << std::hex << hr << std::endl;
            stbi_image_free(data);
            return 0;
        }

        // Map upload heap
        D3D12_SUBRESOURCE_DATA textureData = {};
        textureData.pData = data;
        textureData.RowPitch = width * 4; // 4 bytes per pixel
        textureData.SlicePitch = textureData.RowPitch * height;

        Microsoft::WRL::ComPtr<ID3D12CommandAllocator> commandAllocator;
        device->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, IID_PPV_ARGS(&commandAllocator));

        Microsoft::WRL::ComPtr<ID3D12GraphicsCommandList> commandList;
        device->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT, commandAllocator.Get(), nullptr, IID_PPV_ARGS(&commandList));

        UpdateSubresources(commandList.Get(), texture.Get(), uploadHeap.Get(), 0, 0, 1, &textureData);

        // Transition the texture to COMMON state for sharing
        commandList->ResourceBarrier(1, &CD3DX12_RESOURCE_BARRIER::Transition(
                texture.Get(), D3D12_RESOURCE_STATE_COPY_DEST, D3D12_RESOURCE_STATE_COMMON));
        commandList->Close();

        Microsoft::WRL::ComPtr<ID3D12CommandQueue> commandQueue;
        D3D12_COMMAND_QUEUE_DESC queueDesc = {};
        queueDesc.Type = D3D12_COMMAND_LIST_TYPE_DIRECT;
        device->CreateCommandQueue(&queueDesc, IID_PPV_ARGS(&commandQueue));

        ID3D12CommandList *cmdLists[] = {commandList.Get()};
        commandQueue->ExecuteCommandLists(1, cmdLists);

        // Create shared handle
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

        stbi_image_free(data);

        return reinterpret_cast<jlong>(sharedHandle);
    }

    bool saveD3D12TextureToPNG(JNIEnv *env, const std::string &filename, jlong handle) {
        auto sharedHandle = reinterpret_cast<HANDLE>(handle);

        // Step 1: Create a D3D12 device
        Microsoft::WRL::ComPtr<ID3D12Device> device;
        HRESULT hr = D3D12CreateDevice(nullptr, D3D_FEATURE_LEVEL_12_0, IID_PPV_ARGS(&device));
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create D3D12 device (HRESULT: 0x" << std::hex << hr << ")\n";
            return false;
        }

        // Step 2: Open the shared handle to retrieve the texture resource
        Microsoft::WRL::ComPtr<ID3D12Resource> texture;
        hr = device->OpenSharedHandle(sharedHandle, IID_PPV_ARGS(&texture));
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to open shared handle (HRESULT: 0x" << std::hex << hr << ")\n";
            return false;
        }

        // Step 3: Validate the texture description
        D3D12_RESOURCE_DESC textureDesc = texture->GetDesc();
        if (textureDesc.Dimension != D3D12_RESOURCE_DIMENSION_TEXTURE2D) {
            std::cerr << "Error: Resource is not a 2D texture\n";
            return false;
        }
        if (textureDesc.SampleDesc.Count > 1) {
            std::cerr << "Error: Multi-sampled textures are not supported\n";
            return false;
        }

        // Step 4: Retrieve texture layout and size for copying
        UINT64 requiredSize = 0;
        D3D12_PLACED_SUBRESOURCE_FOOTPRINT layout = {};
        UINT rowCount = 0;
        UINT64 rowSizeInBytes = 0;
        device->GetCopyableFootprints(&textureDesc, 0, 1, 0, &layout, &rowCount, &rowSizeInBytes, &requiredSize);

        // Step 5: Create a readback buffer for copying texture data
        D3D12_HEAP_PROPERTIES heapProps = CD3DX12_HEAP_PROPERTIES(D3D12_HEAP_TYPE_READBACK);
        D3D12_RESOURCE_DESC bufferDesc = CD3DX12_RESOURCE_DESC::Buffer(requiredSize);
        Microsoft::WRL::ComPtr<ID3D12Resource> readbackBuffer;
        hr = device->CreateCommittedResource(
                &heapProps,               // Heap properties for readback
                D3D12_HEAP_FLAG_NONE,     // No flags needed for readback buffers
                &bufferDesc,              // Buffer description
                D3D12_RESOURCE_STATE_COPY_DEST, // Initial resource state
                nullptr,                  // No clear value for buffers
                IID_PPV_ARGS(&readbackBuffer)
        );
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create readback buffer (HRESULT: 0x" << std::hex << hr << ")\n";
            return false;
        }

        // Step 6: Create command list and queue for GPU operations
        Microsoft::WRL::ComPtr<ID3D12CommandQueue> commandQueue;
        D3D12_COMMAND_QUEUE_DESC queueDesc = {};
        queueDesc.Type = D3D12_COMMAND_LIST_TYPE_DIRECT;
        hr = device->CreateCommandQueue(&queueDesc, IID_PPV_ARGS(&commandQueue));
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create command queue (HRESULT: 0x" << std::hex << hr << ")\n";
            return false;
        }

        Microsoft::WRL::ComPtr<ID3D12CommandAllocator> commandAllocator;
        hr = device->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, IID_PPV_ARGS(&commandAllocator));
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create command allocator (HRESULT: 0x" << std::hex << hr << ")\n";
            return false;
        }

        Microsoft::WRL::ComPtr<ID3D12GraphicsCommandList> commandList;
        hr = device->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT, commandAllocator.Get(), nullptr,
                                       IID_PPV_ARGS(&commandList));
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to create command list (HRESULT: 0x" << std::hex << hr << ")\n";
            return false;
        }

        // Step 7: Transition the texture resource to COPY_SOURCE
        const CD3DX12_RESOURCE_BARRIER barrier = CD3DX12_RESOURCE_BARRIER::Transition(
                texture.Get(), D3D12_RESOURCE_STATE_COMMON, D3D12_RESOURCE_STATE_COPY_SOURCE);
        commandList->ResourceBarrier(1, &barrier);

        // Step 8: Copy the texture to the readback buffer
        D3D12_TEXTURE_COPY_LOCATION srcLocation = {};
        srcLocation.pResource = texture.Get();
        srcLocation.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
        srcLocation.SubresourceIndex = 0;

        D3D12_TEXTURE_COPY_LOCATION destLocation = {};
        destLocation.pResource = readbackBuffer.Get();
        destLocation.Type = D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
        destLocation.PlacedFootprint = layout;

        commandList->CopyTextureRegion(&destLocation, 0, 0, 0, &srcLocation, nullptr);
        commandList->Close();

        // Execute and wait for GPU commands
        ID3D12CommandList *cmdLists[] = {commandList.Get()};
        commandQueue->ExecuteCommandLists(1, cmdLists);
        Microsoft::WRL::ComPtr<ID3D12Fence> fence;
        hr = device->CreateFence(0, D3D12_FENCE_FLAG_NONE, IID_PPV_ARGS(&fence));
        HANDLE fenceEvent = CreateEvent(nullptr, FALSE, FALSE, nullptr);
        commandQueue->Signal(fence.Get(), 1);
        fence->SetEventOnCompletion(1, fenceEvent);
        WaitForSingleObject(fenceEvent, INFINITE);
        CloseHandle(fenceEvent);

        // Step 9: Map the readback buffer to access pixel data
        void *mappedData = nullptr;
        D3D12_RANGE readRange = {0, static_cast<SIZE_T>(requiredSize)};
        readbackBuffer->Map(0, &readRange, &mappedData);

        std::vector<uint8_t> imageData(textureDesc.Height * textureDesc.Width * 4);
        uint8_t *sourceRow = static_cast<uint8_t *>(mappedData);
        for (UINT y = 0; y < textureDesc.Height; ++y) {
            memcpy(&imageData[y * textureDesc.Width * 4],
                   sourceRow + y * layout.Footprint.RowPitch,
                   textureDesc.Width * 4);
        }
        readbackBuffer->Unmap(0, nullptr);

        // Step 10: Save the image data as a PNG
        if (!stbi_write_png(filename.c_str(), textureDesc.Width, textureDesc.Height, 4, imageData.data(),
                            textureDesc.Width * 4)) {
            std::cerr << "Error: Failed to save PNG to " << filename << "\n";
            return false;
        }

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

    namespace {
        IDirect3D9Ex* g_d3d9Ex = nullptr;                 // D3D9Ex interface
        IDirect3DDevice9Ex* g_d3d9ExDevice = nullptr;    // D3D9Ex device

        void initD3D9() {
            if (!g_d3d9Ex) {
                // Create the D3D9Ex interface
                HRESULT hr = Direct3DCreate9Ex(D3D_SDK_VERSION, &g_d3d9Ex);
                if (FAILED(hr)) {
                    std::cerr << "Error: Failed to create Direct3D9Ex instance. HRESULT: " << std::hex << hr << std::endl;
                    return;
                }
            }

            if (!g_d3d9ExDevice) {
                // Set up the presentation parameters for the device
                D3DPRESENT_PARAMETERS d3dpp = {};
                d3dpp.Windowed = TRUE;                    // Windowed mode
                d3dpp.SwapEffect = D3DSWAPEFFECT_DISCARD; // Discard swap chain frames after presenting
                d3dpp.BackBufferCount = 1;               // Single back buffer
                d3dpp.BackBufferFormat = D3DFMT_UNKNOWN; // Use desktop display format
                d3dpp.BackBufferWidth = 300;               // Dummy width
                d3dpp.BackBufferHeight = 300;              // Dummy height
                d3dpp.Flags = 0; // Removed D3DPRESENTFLAG_DEVICECLIP since it's not needed for offscreen use.

                // Create the Direct3D9Ex device
                HRESULT hr = g_d3d9Ex->CreateDeviceEx(
                        D3DADAPTER_DEFAULT,                  // Use the default D3D adapter
                        D3DDEVTYPE_HAL,                      // Use hardware acceleration
                        GetDesktopWindow(),                  // Use desktop window as target
                        D3DCREATE_HARDWARE_VERTEXPROCESSING, // Use hardware vertex processing (important for shared textures)
                        &d3dpp,
                        nullptr,                             // No full-screen swap chain
                        &g_d3d9ExDevice                      // Pointer to the new D3D9Ex device
                );
                if (FAILED(hr)) {
                    std::cerr << "Error: Failed to create Direct3D9Ex device. HRESULT: " << std::hex << hr << std::endl;
                    return;
                }
            }

            std::cout << "D3D9Ex initialized successfully." << std::endl;
        }

        IDirect3D9Ex* getD3D9Ex() {
            if (!g_d3d9Ex) {
                initD3D9();
            }
            return g_d3d9Ex;
        }

        IDirect3DDevice9Ex* getD3D9ExDevice() {
            if (!g_d3d9ExDevice) {
                initD3D9();
            }
            return g_d3d9ExDevice;
        }

    }

    jlong getD3D9TextureFromSharedHandle(JNIEnv *env, jlong handle) {
        IDirect3D9Ex *pEx = getD3D9Ex();
        IDirect3DDevice9Ex *pDevice9Ex = getD3D9ExDevice();
        
        if (!pEx || !pDevice9Ex) {
            std::cerr << "Error: D3D9Ex is not initialized. Call initD3D9() first." << std::endl;
            return false;
        }

        HANDLE sharedHandle = reinterpret_cast<HANDLE>(handle);
        IDirect3DTexture9* texture = nullptr;

        // Create a texture from the shared handle
        HRESULT hr = pDevice9Ex->CreateTexture(
                300, 300, 1, 0, D3DFMT_A8R8G8B8, D3DPOOL_DEFAULT, &texture, &sharedHandle
        );

        if (FAILED(hr)) {
            std::cerr << "Error: Failed to open shared texture handle. HRESULT: " << std::hex << hr << std::endl;
            return false;
        }

        std::cerr << "Successfully retrieved D3D9 texture from shared handle." << std::endl;

        return reinterpret_cast<jlong>(texture);
    }

    void releaseD3D9Texture(JNIEnv *env, jlong texture) {
        IDirect3DTexture9* tex = reinterpret_cast<IDirect3DTexture9*>(texture);
        if (tex) {
            tex->Release();
            std::cout << "D3D9 texture released successfully." << std::endl;
        } else {
            std::cerr << "Error: Invalid texture handle provided for release." << std::endl;
        }
    }

    bool saveD3D9TextureToPNG(JNIEnv *env, const std::string &path, jlong textureHandle) {
        IDirect3DTexture9* texture = reinterpret_cast<IDirect3DTexture9*>(textureHandle);
        if (!texture) {
            std::cerr << "Error: Invalid texture handle provided." << std::endl;
            return false;
        }

        // Lock the texture to access raw pixel data
        D3DLOCKED_RECT lockedRect;
        HRESULT hr = texture->LockRect(0, &lockedRect, nullptr, D3DLOCK_READONLY);
        if (FAILED(hr)) {
            std::cerr << "Error: Failed to lock texture. HRESULT: " << std::hex << hr << std::endl;
            return false;
        }

        // Get texture width and height from the surface description
        D3DSURFACE_DESC desc;
        texture->GetLevelDesc(0, &desc);

        // Save raw pixel data to PNG
        int width = desc.Width;
        int height = desc.Height;
        int stride = lockedRect.Pitch; // Bytes per row
        unsigned char* data = static_cast<unsigned char*>(lockedRect.pBits);

        bool saved = stbi_write_png(path.c_str(), width, height, 4, data, stride);
        texture->UnlockRect(0);

        if (!saved) {
            std::cerr << "Error: Failed to write PNG to file." << std::endl;
            return false;
        }

        std::cout << "Texture successfully saved to file: " << path << std::endl;
        return true;
    }

}