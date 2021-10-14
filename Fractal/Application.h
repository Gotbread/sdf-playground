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
#include "ShaderUtil.h"
#include "SDFRenderer.h"

class Application : public SceneManagerClient
{
public:
	bool Init(HINSTANCE hInstance);
	void Run();
private:
	LRESULT CALLBACK WndProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
	static LRESULT CALLBACK sWndProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);

	bool initGraphics();
	void render();
	void updateSimulation(float dt);

	// callbacks
	void loadScene(const std::filesystem::path &filename);

	HINSTANCE hInstance;
	HWND hWnd;

	std::unique_ptr<Graphics> graphics;
	std::unique_ptr<SceneManager> scene_manager;
	std::unique_ptr<ShaderIncluder> includer;
	std::unique_ptr<SDFRenderer> sdf_renderer;

	GPUProfiler profiler;

	Camera camera;
	float stime;
	float scroll_pos1, scroll_pos2, scroll_pos3;
	bool show_debug_plane;

	POINT lastmouse;
	bool keystate[256];

	enum MouseButton
	{
		Left = 0,
		Middle = 1,
		Right = 2,
	};
	bool mouse_state[3];
};
