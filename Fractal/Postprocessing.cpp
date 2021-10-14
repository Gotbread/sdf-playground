#include "Postprocessing.h"
#include "Graphics.h"
#include "ShaderUtil.h"
#include "GPUProfiler.h"


bool HDR::init(Graphics *graphics, unsigned width, unsigned height)
{
	this->graphics = graphics;
	this->width = width;
	this->height = height;

	auto dev = graphics->GetDevice();

	D3D11_TEXTURE2D_DESC texture_desc;

	texture_desc.Width = width;
	texture_desc.Height = height;
	texture_desc.SampleDesc.Count = 1;
	texture_desc.SampleDesc.Quality = 0;
	texture_desc.MipLevels = 1;
	texture_desc.ArraySize = 1;
	texture_desc.Format = DXGI_FORMAT_R16G16B16A16_FLOAT;
	texture_desc.Usage = D3D11_USAGE_DEFAULT;
	texture_desc.BindFlags = D3D11_BIND_RENDER_TARGET | D3D11_BIND_SHADER_RESOURCE;
	texture_desc.CPUAccessFlags = 0;
	texture_desc.MiscFlags = 0;
	// create rendertarget
	HRESULT result = dev->CreateTexture2D(&texture_desc, 0, &rendertarget);
	if (FAILED(result))
		return false;

	result = dev->CreateRenderTargetView(rendertarget, 0, &rendertarget_view);
	if (FAILED(result))
		return false;

	result = dev->CreateShaderResourceView(rendertarget, 0, &shader_view);
	if (FAILED(result))
		return false;

	// create bloom texture 1
	texture_desc.BindFlags = D3D11_BIND_SHADER_RESOURCE | D3D11_BIND_UNORDERED_ACCESS;
	result = dev->CreateTexture2D(&texture_desc, 0, &bloom1);
	if (FAILED(result))
		return false;

	result = dev->CreateShaderResourceView(bloom1, 0, &bloom1_sv);
	if (FAILED(result))
		return false;

	D3D11_UNORDERED_ACCESS_VIEW_DESC uav_desc;
	uav_desc.Format = texture_desc.Format;
	uav_desc.ViewDimension = D3D11_UAV_DIMENSION_TEXTURE2D;
	uav_desc.Texture2D.MipSlice = 0;
	result = dev->CreateUnorderedAccessView(bloom1, &uav_desc, &bloom1_uav);
	if (FAILED(result))
		return false;

	// create bloom texture 2
	result = dev->CreateTexture2D(&texture_desc, 0, &bloom2);
	if (FAILED(result))
		return false;

	result = dev->CreateShaderResourceView(bloom2, 0, &bloom2_sv);
	if (FAILED(result))
		return false;

	result = dev->CreateUnorderedAccessView(bloom2, &uav_desc, &bloom2_uav);
	if (FAILED(result))
		return false;

	D3D11_SAMPLER_DESC sampler_desc;
	sampler_desc.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR;
	sampler_desc.ComparisonFunc = D3D11_COMPARISON_ALWAYS;
	sampler_desc.AddressU = D3D11_TEXTURE_ADDRESS_CLAMP;
	sampler_desc.AddressV = D3D11_TEXTURE_ADDRESS_CLAMP;
	sampler_desc.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP;
	sampler_desc.MinLOD = 0.f;
	sampler_desc.MaxLOD = D3D11_FLOAT32_MAX;
	sampler_desc.MipLODBias = 0.f;
	sampler_desc.MaxAnisotropy = 1;
	result = dev->CreateSamplerState(&sampler_desc, &sampler);
	if (FAILED(result))
		return false;

	ShaderIncluder includer;
	includer.setFolder("shader");
	Comptr<ID3DBlob> p_compiled = compileShader(includer, "pshader_hdr.hlsl", "ps_5_0", "ps_main");
	if (!p_compiled)
		return false;

	result = dev->CreatePixelShader(p_compiled->GetBufferPointer(), p_compiled->GetBufferSize(), 0, &hdr_shader);
	if (FAILED(result))
		return false;

	p_compiled = compileShader(includer, "bloom.hlsl", "cs_5_0", "cs_main1");
	if (!p_compiled)
		return false;

	result = dev->CreateComputeShader(p_compiled->GetBufferPointer(), p_compiled->GetBufferSize(), 0, &bloom1_shader);
	if (FAILED(result))
		return false;

	p_compiled = compileShader(includer, "bloom.hlsl", "cs_5_0", "cs_main2");
	if (!p_compiled)
		return false;

	result = dev->CreateComputeShader(p_compiled->GetBufferPointer(), p_compiled->GetBufferSize(), 0, &bloom2_shader);
	if (FAILED(result))
		return false;

	return true;
}

ID3D11RenderTargetView *HDR::getRenderTarget()
{
	return rendertarget_view;
}

ID3D11ShaderResourceView *HDR::getShaderView()
{
	return shader_view;
}

void HDR::process(GPUProfiler &profiler, ID3D11RenderTargetView *ldr_view)
{
	auto ctx = graphics->GetContext();

	ID3D11UnorderedAccessView *null_uav = nullptr;
	ID3D11ShaderResourceView *null_view = nullptr;

	unsigned cs_group_size = 128;
	// set the render target first so our own render target is not bound
	ctx->OMSetRenderTargets(1, &ldr_view, nullptr);

	// first bloom pass
	ctx->CSSetShaderResources(0, 1, &shader_view);
	ctx->CSSetUnorderedAccessViews(0, 1, &bloom1_uav, nullptr);
	ctx->CSSetShader(bloom1_shader, nullptr, 0);

	ctx->Dispatch((width + cs_group_size - 1) / cs_group_size, height, 1);
	profiler.profile("Bloom 1");

	ctx->CSSetShaderResources(0, 1, &null_view);
	ctx->CSSetUnorderedAccessViews(0, 1, &null_uav, nullptr);

	// second bloom pass
	ctx->CSSetShaderResources(0, 1, &bloom1_sv);
	ctx->CSSetUnorderedAccessViews(0, 1, &bloom2_uav, nullptr);
	ctx->CSSetShader(bloom2_shader, nullptr, 0);

	ctx->Dispatch(width, (height + cs_group_size - 1) / cs_group_size, 1);
	profiler.profile("Bloom 2");

	ctx->CSSetShaderResources(0, 1, &null_view);
	ctx->CSSetUnorderedAccessViews(0, 1, &null_uav, nullptr);

	// hdr pass
	ID3D11ShaderResourceView *views[] = { shader_view, bloom2_sv };
	ctx->PSSetShaderResources(0, 2, views);

	ctx->PSSetShader(hdr_shader, 0, 0);
	ctx->PSSetSamplers(0, 1, &sampler);

	ctx->DrawIndexed(6, 0, 0);
	profiler.profile("HDR");

	ctx->PSSetShaderResources(0, 1, &null_view);
}