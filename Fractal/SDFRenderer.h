#pragma once

#include "Comptr.h"
#include "Math3D.h"
#include "ShaderUtil.h"
#include "ShaderVariable.h"

#include <d3d11.h>

class Graphics;
class Camera;
class GPUProfiler;
class ShaderIncluder;
class FullscreenQuad;
class ShaderVariableManager;

class SDFRenderer
{
public:
	// extra plane which shows the distance field
	struct DebugPlane
	{
		bool show = false;
		float ruler_scale = 1.f;
		Math3D::Vector3 point, normal;
	};

	bool init(Graphics &graphics);
	bool initShader(ShaderIncluder &includer);

	void setParameters(const DebugPlane &debug_plane, float stime);
	VariableMap &getVariableMap();

	// true if it did render something, false otherwise
	bool render(FullscreenQuad &quad, GPUProfiler &profiler, Camera &camera);
private:
	struct camera_cbuffer
	{
		alignas(16) Math3D::Vector3 eye;
		alignas(16) Math3D::Vector3 front_vec, right_vec, top_vec;
		alignas(16) Math3D::Vector3 debug_plane_point, debug_plane_normal;
		alignas(16) struct
		{
			float stime, debug_plane_scale;
		} params;
	};

	Graphics *graphics = nullptr;

	Comptr<ID3D11Buffer> camera_buffer;
	Comptr<ID3D11PixelShader> p_shader;

	ShaderVariableManager var_manager;
	ShaderCodeGenerator code_generator;

	DebugPlane debug_plane;
	float stime = 0.f;
};
