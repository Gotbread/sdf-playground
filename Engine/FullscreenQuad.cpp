#include "FullscreenQuad.h"
#include "Graphics.h"
#include "ShaderUtil.h"

bool FullscreenQuad::init(Graphics &graphics)
{
	this->graphics = &graphics;

	return initGeometry();
}

bool FullscreenQuad::isValid()
{
	return v_shader && input_layout;
}

bool FullscreenQuad::initShader(ShaderIncluder &includer)
{
	// remove old objects. since d3d keeps a reference internally
	// the object is not freed yet. setting it to zero ensures
	// we dont overwrite it later and loose the pointer.
	// once we set the new objects in the pipeline, the old ones will get released anyway
	v_shader = nullptr;
	input_layout = nullptr;

	Comptr<ID3DBlob> v_compiled = compileShader(includer, "vshader.hlsl", "vs_5_0", "vs_main");
	if (!v_compiled)
		return false;

	auto device = graphics->GetDevice();
	HRESULT hr = device->CreateVertexShader(v_compiled->GetBufferPointer(), v_compiled->GetBufferSize(), 0, &v_shader);
	if (FAILED(hr))
		return false;

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

bool FullscreenQuad::initGeometry()
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
	
	return true;
}

void FullscreenQuad::render()
{
	auto ctx = graphics->GetContext();

	ctx->VSSetShader(v_shader, nullptr, 0);

	UINT v_strides[] = { sizeof(Vertex) };
	UINT v_offsets[] = { 0 };
	ID3D11Buffer *vertex_buffers[] = { vertex_buffer };
	ctx->IASetInputLayout(input_layout);
	ctx->IASetVertexBuffers(0, 1, vertex_buffers, v_strides, v_offsets);
	ctx->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
	ctx->IASetIndexBuffer(index_buffer, DXGI_FORMAT_R16_UINT, 0);

	ctx->DrawIndexed(6, 0, 0);
}