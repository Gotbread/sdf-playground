#pragma once

#include <Windows.h>
#include <memory>
#include <string>
#include <map>

#include "Graphics.h"
#include "Camera.h"
#include "Math3D.h"
#include "GPUProfiler.h"
#include "SceneManager.h"
#include "VariableManager.h"
#include "ShaderUtil.h"
#include "SDFRenderer.h"
#include "Postprocessing.h"
#include "FullscreenQuad.h"
#include "InputManager.h"

class Application : public SceneManagerClient
{
public:
	bool Init(HINSTANCE hInstance);
	void Run();
private:
	LRESULT CALLBACK WndProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
	static LRESULT CALLBACK sWndProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);

	bool initGraphics();
	void initShader();
	void render();
	void updateSimulation(float dt);

	// callbacks
	void loadScene(const std::filesystem::path &filename);

	HINSTANCE hInstance;
	HWND hWnd;

	Graphics graphics;
	SceneManager scene_manager;
	VariableManager variable_manager;
	ShaderIncluder includer;
	FullscreenQuad fullscreen_quad;
	SDFRenderer sdf_renderer;
	HDR hdr;
	GPUProfiler profiler;
	InputManager input_manager;

	Camera camera;
	float stime;
	bool paused;
	bool single_frame_mode;
	bool do_single_renderer;
};
