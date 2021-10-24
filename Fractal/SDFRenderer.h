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
	bool init(Graphics &graphics);
	bool initShader(ShaderIncluder &includer);

	void setParameters(float stime);
	VariableMap &getVariableMap();

	// true if it did render something, false otherwise
	bool render(FullscreenQuad &quad, GPUProfiler &profiler, Camera &camera);
private:
	struct camera_cbuffer
	{
		alignas(16) Math3D::Vector3 eye;
		alignas(16) Math3D::Vector3 front_vec, right_vec, top_vec;
		float stime;
	};

	Graphics *graphics = nullptr;

	Comptr<ID3D11Buffer> camera_buffer;
	Comptr<ID3D11PixelShader> p_shader;

	ShaderVariableManager var_manager;

	float stime = 0.f;
};
