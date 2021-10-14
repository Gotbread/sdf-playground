#include "SDFRenderer.h"

#include "Graphics.h"
#include "GPUProfiler.h"
#include "Camera.h"
#include "ShaderUtil.h"


bool SDFRenderer::init(Graphics *graphics)
{
	this->graphics = graphics;

	return initGeometry();
}

bool SDFRenderer::initShader(ShaderIncluder &includer)
{
	auto context = graphics->GetContext();

	// remove old objects. since d3d keeps a reference internally
	// the object is not freed yet. setting it to zero ensures
	// we dont overwrite it later and loose the pointer.
	// once we set the new objects in the pipeline, the old ones will get released anyway
	v_shader = nullptr;
	p_shader = nullptr;
	input_layout = nullptr;

	Comptr<ID3DBlob> v_compiled = compileShader(includer, "vshader.hlsl", "vs_5_0", "vs_main");
	if (!v_compiled)
		return false;

	Comptr<ID3DBlob> p_compiled = compileShader(includer, "pshader.hlsl", "ps_5_0", "ps_main");
	if (!p_compiled)
		return false;

	auto device = graphics->GetDevice();
	HRESULT hr = device->CreateVertexShader(v_compiled->GetBufferPointer(), v_compiled->GetBufferSize(), 0, &v_shader);
	if (FAILED(hr))
		return false;

	hr = device->CreatePixelShader(p_compiled->GetBufferPointer(), p_compiled->GetBufferSize(), 0, &p_shader);
	if (FAILED(hr))
		return false;

	context->VSSetShader(v_shader, nullptr, 0);
	context->PSSetShader(p_shader, nullptr, 0);

	// build the input assembler
	D3D11_INPUT_ELEMENT_DESC input_desc[] =
	{
		{"POSITION", 0, DXGI_FORMAT_R32G32_FLOAT, 0, D3D11_APPEND_ALIGNED_ELEMENT, D3D11_INPUT_PER_VERTEX_DATA, 0},
	};

	hr = device->CreateInputLayout(input_desc, static_cast<UINT>(std::size(input_desc)), v_compiled->GetBufferPointer(), v_compiled->GetBufferSize(), &input_layout);
	if (FAILED(hr))
		return false;

	return true;
}

bool SDFRenderer::initGeometry()
{
	auto device = graphics->GetDevice();

	Vertex vertices[4] =
	{
		{-1.f, +1.f},
		{+1.f, +1.f},
		{-1.f, -1.f},
		{+1.f, -1.f},
	};

	D3D11_BUFFER_DESC vertex_buffer_desc = { 0 };
	vertex_buffer_desc.StructureByteStride = sizeof(Vertex);
	vertex_buffer_desc.ByteWidth = static_cast<UINT>(sizeof(Vertex) * std::size(vertices));
	vertex_buffer_desc.BindFlags = D3D11_BIND_VERTEX_BUFFER;
	vertex_buffer_desc.Usage = D3D11_USAGE_DEFAULT;

	D3D11_SUBRESOURCE_DATA vertex_init_data = { 0 };
	vertex_init_data.pSysMem = vertices;
	HRESULT hr = device->CreateBuffer(&vertex_buffer_desc, &vertex_init_data, &vertex_buffer);
	if (FAILED(hr))
		return false;

	using Index = unsigned short;
	Index indices[] =
	{
		0, 1, 2, 2, 1, 3,
	};

	D3D11_BUFFER_DESC index_buffer_desc = { 0 };
	index_buffer_desc.StructureByteStride = sizeof(Index);
	index_buffer_desc.ByteWidth = static_cast<UINT>(sizeof(Index) * std::size(indices));
	index_buffer_desc.BindFlags = D3D11_BIND_INDEX_BUFFER;
	index_buffer_desc.Usage = D3D11_USAGE_DEFAULT;

	D3D11_SUBRESOURCE_DATA index_init_data = { 0 };
	index_init_data.pSysMem = indices;
	hr = device->CreateBuffer(&index_buffer_desc, &index_init_data, &index_buffer);
	if (FAILED(hr))
		return false;

	D3D11_BUFFER_DESC cbuffer_desc = { 0 };
	cbuffer_desc.ByteWidth = sizeof(camera_cbuffer);
	cbuffer_desc.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
	cbuffer_desc.Usage = D3D11_USAGE_DYNAMIC;
	cbuffer_desc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
	hr = device->CreateBuffer(&cbuffer_desc, nullptr, &camera_buffer);
	if (FAILED(hr))
		return false;

	return true;
}

void SDFRenderer::render(GPUProfiler &profiler, Camera &camera)
{
	auto ctx = graphics->GetContext();

	// only render something if we have a valid shader
	if (!(v_shader && p_shader && input_layout))
	{
		return;
	}

	ctx->IASetInputLayout(input_layout);

	D3D11_MAPPED_SUBRESOURCE sub;
	ctx->Map(camera_buffer, 0, D3D11_MAP_WRITE_DISCARD, 0, &sub);
	camera_cbuffer *cam_buf = static_cast<camera_cbuffer *>(sub.pData);
	cam_buf->eye = camera.GetEye();
	cam_buf->front_vec = camera.GetDirection();
	cam_buf->right_vec = (camera.GetFrustrumEdge(0) - camera.GetFrustrumEdge(3)) * 0.5f;
	cam_buf->top_vec = (camera.GetFrustrumEdge(0) - camera.GetFrustrumEdge(1)) * 0.5f;

	/*if (show_debug_plane)
	{
		if (scroll_pos1 > 0.f)
		{
			cam_buf->debug_plane_normal = Math3D::Matrix4x4::RotationXMatrix(scroll_pos1 * Math3D::PI * +0.5f) * Math3D::Vector3(0.f, 1.f, 0.f);
		}
		else
		{
			cam_buf->debug_plane_normal = Math3D::Matrix4x4::RotationZMatrix(scroll_pos1 * Math3D::PI * -0.5f) * Math3D::Vector3(0.f, 1.f, 0.f);
		}
	}
	else*/
	{
		cam_buf->debug_plane_normal = Math3D::Vector3::NullVector();
	}
	//cam_buf->debug_plane_point = cam_buf->debug_plane_normal * scroll_pos2;

	//cam_buf->params.stime = stime;
	//cam_buf->params.free_param = scroll_pos3;

	ctx->Unmap(camera_buffer, 0);
	ctx->PSSetConstantBuffers(0, 1, &camera_buffer);

	UINT v_strides[] =
	{
		sizeof(Vertex),
	};
	UINT v_offsets[] =
	{
		0,
	};
	ID3D11Buffer *vertex_buffers[] =
	{
		vertex_buffer,
	};
	ctx->IASetVertexBuffers(0, 1, vertex_buffers, v_strides, v_offsets);
	ctx->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);

	ctx->IASetIndexBuffer(index_buffer, DXGI_FORMAT_R16_UINT, 0);

	profiler.profile("setup");

	ctx->DrawIndexed(6, 0, 0);

	profiler.profile("draw");
}
