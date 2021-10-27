#pragma once

#include "Comptr.h"

#include <d3d11.h>

class Graphics;
class ShaderIncluder;

class FullscreenQuad
{
public:
	bool init(Graphics &graphics);
	bool initShader(ShaderIncluder &includer);
	bool isValid();
	void render();
private:
	struct Vertex
	{
		float x, y;
	};

	bool initGeometry();

	Graphics *graphics = nullptr;

	Comptr<ID3D11Buffer> vertex_buffer, index_buffer;
	Comptr<ID3D11VertexShader> v_shader;
	Comptr<ID3D11InputLayout> input_layout;
};
