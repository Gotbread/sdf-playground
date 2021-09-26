#pragma once

#include <d3d11.h>

#include "Comptr.h"


class Graphics
{
public:
	Graphics();
	~Graphics();

	bool init(HWND hWnd);
	void Present();
	void WaitForVBlank();

	ID3D11Device *GetDevice();
	ID3D11DeviceContext *GetContext();
	IDXGISwapChain *GetSwapChain();

	ID3D11RenderTargetView *GetMainRendertargetView();
	ID3D11DepthStencilView *GetMainDepthStencilView();
private:
	bool initMonitor();
	bool initDevice(HWND hWnd);
	bool initPipeline();

	Comptr<IDXGIFactory> factory;
	Comptr<IDXGIAdapter> adapter;
	Comptr<IDXGIOutput> output;
	Comptr<ID3D11Device> device;
	Comptr<ID3D11DeviceContext> context;
	Comptr<IDXGISwapChain> swapchain;

	Comptr<ID3D11RenderTargetView> rendertargetview; // primary target
	Comptr<ID3D11DepthStencilView> depthstencilview; // zbuffer

	Comptr<ID3D11DepthStencilState> stencilstate;
	Comptr<ID3D11RasterizerState> rasterstate;
};
