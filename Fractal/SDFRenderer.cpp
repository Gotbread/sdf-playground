#include "SDFRenderer.h"

#include "Graphics.h"
#include "GPUProfiler.h"
#include "Camera.h"
#include "ShaderUtil.h"
#include "FullscreenQuad.h"

bool SDFRenderer::init(Graphics &graphics)
{
	this->graphics = &graphics;

	auto device = graphics.GetDevice();

	D3D11_BUFFER_DESC cbuffer_desc = { 0 };
	cbuffer_desc.ByteWidth = sizeof(camera_cbuffer);
	cbuffer_desc.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
	cbuffer_desc.Usage = D3D11_USAGE_DYNAMIC;
	cbuffer_desc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
	HRESULT hr = device->CreateBuffer(&cbuffer_desc, nullptr, &camera_buffer);
	if (FAILED(hr))
		return false;

	return true;
}

bool SDFRenderer::initShader(ShaderIncluder &includer)
{
	// remove old objects. since d3d keeps a reference internally
	// the object is not freed yet. setting it to zero ensures
	// we dont overwrite it later and loose the pointer.
	// once we set the new objects in the pipeline, the old ones will get released anyway
	p_shader = nullptr;

	var_manager.setSlot(1);
	var_manager.getVariables().clear();
	includer.setShaderVariableManager(&var_manager);
	Comptr<ID3DBlob> p_compiled = compileShader(includer, "pshader_sdf.hlsl", "ps_5_0", "ps_main");
	if (!p_compiled)
		return false;

	includer.setShaderVariableManager(nullptr);

	auto device = graphics->GetDevice();
	if (var_manager.hasVariables() && !var_manager.createConstantBuffer(device))
		return false;

	HRESULT hr = device->CreatePixelShader(p_compiled->GetBufferPointer(), p_compiled->GetBufferSize(), 0, &p_shader);
	if (FAILED(hr))
		return false;

	return true;
}

void SDFRenderer::setParameters(const DebugPlane &debug_plane, float stime)
{
	this->debug_plane = debug_plane;
	this->stime = stime;
}

VariableMap &SDFRenderer::getVariableMap()
{
	return var_manager.getVariables();
}

bool SDFRenderer::render(FullscreenQuad &quad, GPUProfiler &profiler, Camera &camera)
{
	auto ctx = graphics->GetContext();

	// only render something if we have a valid shader
	if (!(quad.isValid() && p_shader))
	{
		return false;
	}

	if (var_manager.hasVariables())
	{
		var_manager.updateBuffer(ctx);
	}

	ID3D11Buffer *constant_buffers[2] =
	{
		camera_buffer, var_manager.getBuffer()
	};

	D3D11_MAPPED_SUBRESOURCE sub;
	ctx->Map(camera_buffer, 0, D3D11_MAP_WRITE_DISCARD, 0, &sub);
	camera_cbuffer *cam_buf = static_cast<camera_cbuffer *>(sub.pData);
	cam_buf->eye = camera.GetEye();
	cam_buf->front_vec = camera.GetDirection();
	cam_buf->right_vec = (camera.GetFrustrumEdge(0) - camera.GetFrustrumEdge(3)) * 0.5f;
	cam_buf->top_vec = (camera.GetFrustrumEdge(0) - camera.GetFrustrumEdge(1)) * 0.5f;

	cam_buf->debug_plane_normal = debug_plane.show ? debug_plane.normal.Normalized() : Math3D::Vector3::NullVector();
	cam_buf->debug_plane_point = debug_plane.point;
	
	cam_buf->params.debug_plane_scale = debug_plane.ruler_scale;
	cam_buf->params.stime = stime;

	ctx->Unmap(camera_buffer, 0);
	ctx->PSSetConstantBuffers(0, 2, constant_buffers);

	ctx->PSSetShader(p_shader, nullptr, 0);

	profiler.profile("setup");

	quad.render();

	profiler.profile("draw");

	return true;
}
