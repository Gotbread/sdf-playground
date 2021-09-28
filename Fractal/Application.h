#pragma once

#include <Windows.h>
#include <memory>
#include <string>

#include "Graphics.h"
#include "Camera.h"
#include "Math3D.h"


class Application
{
public:
	bool Init(HINSTANCE hInstance);
	void Run();
private:
	struct Vertex
	{
		float x, y;
	};

	struct camera_cbuffer
	{
		alignas(16) Math3D::Vector3 eye;
		alignas(16) Math3D::Vector3 front_vec, right_vec, top_vec;
	};

	LRESULT CALLBACK WndProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
	static LRESULT CALLBACK sWndProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);

	bool initGraphics();
	bool initShaders();
	bool initGeometry();
	void render();
	void updateSimulation(float dt);

	Comptr<ID3DBlob> compileShader(const std::string &filename, const std::string &profile, const std::string &entry, bool display_warnings = true, bool disassemble = false);

	HINSTANCE hInstance;
	HWND hWnd;

	std::unique_ptr<Graphics> graphics;

	Comptr<ID3D11Buffer> vertex_buffer, index_buffer, camera_buffer;
	Comptr<ID3D11VertexShader> v_shader;
	Comptr<ID3D11PixelShader> p_shader;
	Comptr<ID3D11InputLayout> input_layout;

	Camera camera;
	float stime;

	POINT lastmouse;
	bool mouse_tracking;
	bool keystate[256];
};
