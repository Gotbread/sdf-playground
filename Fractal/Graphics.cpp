#include "Graphics.h"

#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "d3d11.lib")

Graphics::Graphics()
{
}

Graphics::~Graphics()
{
}

bool Graphics::init(HWND hWnd, bool create_depth)
{
	if (!initMonitor())
		return false;

	if (!initDevice(hWnd))
		return false;

	if (!initPipeline(create_depth))
		return false;

	return true;
}

bool Graphics::initMonitor()
{
	HRESULT result = CreateDXGIFactory(__uuidof(IDXGIFactory), (void **)&factory);
	if (FAILED(result))
		return false;

	result = factory->EnumAdapters(0, &adapter); // enum grakas
	if (FAILED(result))
		return false;

	result = adapter->EnumOutputs(0, &output); // display
	if (FAILED(result))
		return false;

	return true;
}

bool Graphics::initDevice(HWND hWnd)
{
	unsigned flags = 0;
#ifdef _DEBUG
	flags |= D3D11_CREATE_DEVICE_DEBUG;
#endif

	// for now, we want the full features, including geometry shader and tesselation
	D3D_FEATURE_LEVEL level[] =
	{
		D3D_FEATURE_LEVEL_11_0,
		D3D_FEATURE_LEVEL_10_1
	};
	D3D_FEATURE_LEVEL currentlevel;
	HRESULT result = D3D11CreateDevice(adapter, D3D_DRIVER_TYPE_UNKNOWN, 0, flags, level, ARRAYSIZE(level), D3D11_SDK_VERSION, &device, &currentlevel, &context);
	if (FAILED(result))
		return false;

	DXGI_SWAP_CHAIN_DESC swapchaindesc = { 0 };
	swapchaindesc.BufferCount = 1;
	swapchaindesc.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
	swapchaindesc.BufferDesc.ScanlineOrdering = DXGI_MODE_SCANLINE_ORDER_UNSPECIFIED;
	swapchaindesc.BufferDesc.Scaling = DXGI_MODE_SCALING_UNSPECIFIED;
	swapchaindesc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
	swapchaindesc.Flags = 0;
	swapchaindesc.OutputWindow = hWnd;
	swapchaindesc.SampleDesc.Count = 1;
	swapchaindesc.SampleDesc.Quality = 0;
	swapchaindesc.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;
	swapchaindesc.Windowed = true;

	result = factory->CreateSwapChain(device, &swapchaindesc, &swapchain);
	if (FAILED(result))
		return false;

	swapchain->GetDesc(&swapchaindesc);

	{
		Comptr<ID3D11Resource> backbuffer;
		result = swapchain->GetBuffer(0, __uuidof(backbuffer), reinterpret_cast<void **>(&backbuffer));
		if (FAILED(result))
			return false;

		result = device->CreateRenderTargetView(backbuffer, 0, &rendertargetview);
		if (FAILED(result))
			return false;
	}

	return true;
}

bool Graphics::initPipeline(bool create_depth)
{
	DXGI_SWAP_CHAIN_DESC swapchaindesc = { 0 };
	swapchain->GetDesc(&swapchaindesc);
	HRESULT result;

	if (create_depth)
	{
		D3D11_TEXTURE2D_DESC depthbufferdesc;
		Comptr<ID3D11Texture2D> depthstencil;

		depthbufferdesc.Width = swapchaindesc.BufferDesc.Width;
		depthbufferdesc.Height = swapchaindesc.BufferDesc.Height;
		depthbufferdesc.SampleDesc = swapchaindesc.SampleDesc;
		depthbufferdesc.MipLevels = 1;
		depthbufferdesc.ArraySize = 1;
		depthbufferdesc.Format = DXGI_FORMAT_D24_UNORM_S8_UINT;
		depthbufferdesc.Usage = D3D11_USAGE_DEFAULT;
		depthbufferdesc.BindFlags = D3D11_BIND_DEPTH_STENCIL;
		depthbufferdesc.CPUAccessFlags = 0;
		depthbufferdesc.MiscFlags = 0;
		result = device->CreateTexture2D(&depthbufferdesc, 0, &depthstencil);
		if (FAILED(result))
			return false;

		D3D11_DEPTH_STENCIL_VIEW_DESC depthstencilviewdesc = {};
		depthstencilviewdesc.Format = DXGI_FORMAT_D24_UNORM_S8_UINT;
		depthstencilviewdesc.ViewDimension = D3D11_DSV_DIMENSION_TEXTURE2D;
		depthstencilviewdesc.Texture2D.MipSlice = 0;
		result = device->CreateDepthStencilView(depthstencil, &depthstencilviewdesc, &depthstencilview);
		if (FAILED(result))
			return false;
	}

	context->OMSetRenderTargets(1, &rendertargetview, depthstencilview);

	if (create_depth)
	{
		D3D11_DEPTH_STENCIL_DESC depthstencilstate = {};
		depthstencilstate.DepthEnable = 1;
		depthstencilstate.DepthFunc = D3D11_COMPARISON_LESS;
		depthstencilstate.DepthWriteMask = D3D11_DEPTH_WRITE_MASK_ALL;
		result = device->CreateDepthStencilState(&depthstencilstate, &stencilstate);
		if (FAILED(result))
			return false;

		context->OMSetDepthStencilState(stencilstate, 0);
	}

	D3D11_RASTERIZER_DESC rasterdesc;
	rasterdesc.AntialiasedLineEnable = false;
	rasterdesc.CullMode = D3D11_CULL_BACK;
	rasterdesc.DepthBias = 0;
	rasterdesc.DepthBiasClamp = 0.0f;
	rasterdesc.DepthClipEnable = true;
	rasterdesc.FillMode = D3D11_FILL_SOLID;
	rasterdesc.FrontCounterClockwise = false;
	rasterdesc.MultisampleEnable = false;
	rasterdesc.ScissorEnable = false;
	rasterdesc.SlopeScaledDepthBias = 0.0f;

	result = device->CreateRasterizerState(&rasterdesc, &rasterstate);
	if (FAILED(result))
		return false;

	context->RSSetState(rasterstate);

	D3D11_VIEWPORT viewport;
	viewport.Width = static_cast<float>(swapchaindesc.BufferDesc.Width);
	viewport.Height = static_cast<float>(swapchaindesc.BufferDesc.Height);
	viewport.MinDepth = 0.0f;
	viewport.MaxDepth = 1.0f;
	viewport.TopLeftX = 0.0f;
	viewport.TopLeftY = 0.0f;

	// Create the viewport.
	context->RSSetViewports(1, &viewport);

	return true;
}

void Graphics::Present()
{
	swapchain->Present(0, 0);
}

void Graphics::WaitForVBlank()
{
	output->WaitForVBlank();
}

ID3D11Device *Graphics::GetDevice()
{
	return device;
}

ID3D11DeviceContext *Graphics::GetContext()
{
	return context;
}

IDXGISwapChain *Graphics::GetSwapChain()
{
	return swapchain;
}

ID3D11RenderTargetView *Graphics::GetMainRendertargetView()
{
	return rendertargetview;
}

ID3D11DepthStencilView *Graphics::GetMainDepthStencilView()
{
	return depthstencilview;
}
