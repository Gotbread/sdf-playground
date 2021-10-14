#pragma once

#include "Comptr.h"
#include "Math3D.h"

#include <d3d11.h>

class Graphics;
class Camera;
class GPUProfiler;
class ShaderIncluder;

class SDFRenderer
{
public:
	bool init(Graphics *graphics);
	bool initShader(ShaderIncluder &includer);

	void render(GPUProfiler &profiler, Camera &camera);
private:
	struct Vertex
	{
		float x, y;
	};

	struct camera_cbuffer
	{
		alignas(16) Math3D::Vector3 eye;
		alignas(16) Math3D::Vector3 front_vec, right_vec, top_vec;
		alignas(16) Math3D::Vector3 debug_plane_point, debug_plane_normal;
		alignas(16) struct
		{
			float stime, free_param;
		} params;
	};

	bool initGeometry();

	Graphics *graphics = nullptr;

	Comptr<ID3D11Buffer> vertex_buffer, index_buffer, camera_buffer;
	Comptr<ID3D11VertexShader> v_shader;
	Comptr<ID3D11PixelShader> p_shader;
	Comptr<ID3D11InputLayout> input_layout;
};
