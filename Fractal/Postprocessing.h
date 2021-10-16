#pragma once

#include "Comptr.h"

#include <d3d11.h>

class Graphics;
class GPUProfiler;
class FullscreenQuad;
class ShaderIncluder;

class HDR
{
public:
	bool init(Graphics &graphics, unsigned width, unsigned height);
	bool initShader(ShaderIncluder &includer);

	ID3D11RenderTargetView *getRenderTarget();
	ID3D11ShaderResourceView *getShaderView();

	void process(FullscreenQuad &quad, GPUProfiler &profiler, ID3D11RenderTargetView *ldr_view);
private:
	Graphics *graphics = nullptr;

	Comptr<ID3D11Texture2D> rendertarget;
	Comptr<ID3D11RenderTargetView> rendertarget_view;
	Comptr<ID3D11ShaderResourceView> shader_view;

	Comptr<ID3D11Texture2D> bloom1;
	Comptr<ID3D11ShaderResourceView> bloom1_sv;
	Comptr<ID3D11UnorderedAccessView> bloom1_uav;

	Comptr<ID3D11Texture2D> bloom2;
	Comptr<ID3D11ShaderResourceView> bloom2_sv;
	Comptr<ID3D11UnorderedAccessView> bloom2_uav;

	Comptr<ID3D11SamplerState> sampler;
	Comptr<ID3D11PixelShader> hdr_shader;

	Comptr<ID3D11ComputeShader> bloom1_shader, bloom2_shader;

	unsigned width = 0, height = 0;
};