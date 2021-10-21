#include <string>
#include <vector>
#include <fstream>
#include <sstream>

#include "Application.h"
#include "Math3D.h"
#include "Util.h"

using namespace Math3D;

//#define PROFILE_OUTPUT

bool Application::Init(HINSTANCE hInstance)
{
	WNDCLASS wc = { 0 };
	wc.cbWndExtra = sizeof(this);
	wc.hCursor = LoadCursor(0, IDC_ARROW);
	wc.hInstance = hInstance;
	wc.lpszClassName = "Mainwnd";
	wc.lpfnWndProc = sWndProc;

	RegisterClass(&wc);

	bool fullscreen = false;
	std::string title = "SDF Playground";

	if (fullscreen)
	{
		unsigned width = GetSystemMetrics(SM_CXSCREEN);
		unsigned height = GetSystemMetrics(SM_CYSCREEN);
		hWnd = CreateWindow(wc.lpszClassName, title.c_str(), WS_POPUP, 0, 0, width, height, 0, 0, hInstance, this);
	}
	else
	{
		unsigned windowstyle = WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;
		int xpos = CW_USEDEFAULT;
		int ypos = CW_USEDEFAULT;
		unsigned width = 1200;
		unsigned height = 800;

		RECT r;
		SetRect(&r, 0, 0, width, height);
		AdjustWindowRect(&r, windowstyle, 0);
		hWnd = CreateWindow(wc.lpszClassName, title.c_str(), windowstyle, xpos, ypos, r.right - r.left, r.bottom - r.top, 0, 0, hInstance, this);
	}

	if (!hWnd)
	{
		return false;
	}

	if (!initGraphics())
	{
		return false;
	}

	show_debug_plane = false;

	paused = false;
	single_frame_mode = false;
	do_single_renderer = false;

	return true;
}

void Application::Run()
{
	ShowWindow(hWnd, SW_SHOWNORMAL);

	// the overflow warning can be ignored. since we are taking the difference only
	// and a frame wont last more than 49 days (hopefully), we cant overflow
	auto lasttime = GetTickCount64();

	MSG Msg;
	for (;;)
	{
		while (PeekMessage(&Msg, 0, 0, 0, PM_REMOVE))
		{
			TranslateMessage(&Msg);
			DispatchMessage(&Msg);

			if (Msg.message == WM_QUIT)
				return;
		}

		auto newtime = GetTickCount64();
		unsigned diff = static_cast<unsigned>(newtime - lasttime);
		lasttime = newtime;

		updateSimulation(static_cast<float>(diff) / 1000.f);
		if (!single_frame_mode || do_single_renderer)
		{
			do_single_renderer = false;
			render();
		}
	}
}

LRESULT CALLBACK Application::sWndProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam)
{
	if (Msg == WM_NCCREATE)
	{
		SetWindowLongPtr(hWnd, 0, reinterpret_cast<LONG_PTR>(reinterpret_cast<CREATESTRUCT *>(lParam)->lpCreateParams));
	}
	Application *app = reinterpret_cast<Application *>(GetWindowLongPtr(hWnd, 0));
	if (app)
	{
		return app->WndProc(hWnd, Msg, wParam, lParam);
	}
	return DefWindowProc(hWnd, Msg, wParam, lParam);
}

LRESULT CALLBACK Application::WndProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam)
{
	input_manager.processMessage(Msg, wParam, lParam);

	switch (Msg)
	{
	case WM_MOUSEMOVE:
		{
			if (auto motion = input_manager.getMotion(); motion)
			{
				if (input_manager.getMouseState(InputManager::MouseButton::Left))
				{
					camera.RotateY(motion->x / -500.f);
					camera.RotateX(motion->y / -500.f);
				}
				if (input_manager.getMouseState(InputManager::MouseButton::Middle))
				{
					scroll_pos1 += motion->x / 1000.f;
					scroll_pos1 = std::min(std::max(scroll_pos1, -1.f), +1.f);

					scroll_pos2 += motion->y / 1000.f;
					scroll_pos2 = std::min(std::max(scroll_pos2, -10.f), +10.f);
				}
				if (input_manager.getMouseState(InputManager::MouseButton::Right))
				{
					scroll_pos3 += motion->x / 1000.f;
					scroll_pos3 = std::min(std::max(scroll_pos3, 0.f), 1.f);
				}
			}
		}
		break;
	case WM_KEYDOWN:
		if (GetKeyState(VK_CONTROL) < 0) // ctrl events
		{
			switch (LOWORD(wParam))
			{
			case 'R': // reload shader
				initShader();
				break;
			case 'S': // scene manager
				scene_manager.Open();
				break;
			case 'V': // variable manager
				variable_manager.Open();
				break;
			}
		}
		else
		{
			// for normal events
			switch (LOWORD(wParam))
			{
			case VK_ESCAPE: // quit
				PostQuitMessage(0);
				break;
			case 'P': // pause
				paused ^= true;
				break;
			case 'O': // single frame mode
				single_frame_mode ^= true;
				break;
			case 'I': // render single frame
				do_single_renderer = true;
				break;
			}
		}
		break;
	case WM_MBUTTONDOWN:
		show_debug_plane ^= true;
		break;
	case WM_DESTROY:
		PostQuitMessage(0);
		break;
	}
	return DefWindowProc(hWnd, Msg, wParam, lParam);
}

bool Application::initGraphics()
{
	if (!graphics.init(hWnd, false))
		return false;

	profiler.setGPU(graphics.GetDevice(), graphics.GetContext());

	RECT rect;
	GetClientRect(hWnd, &rect);
	float width = static_cast<float>(rect.right - rect.left);
	float height = static_cast<float>(rect.bottom - rect.top);

	includer.setFolder("shader");

	scene_manager.setClient(this);
	scene_manager.InitClass(hInstance);
	scene_manager.setShaderFolder("shader");
	scene_manager.setSceneFolder("scenes");
	scene_manager.Open();

	variable_manager.InitClass(hInstance);
	variable_manager.Open();

	if (!sdf_renderer.init(graphics))
	{
		return false;
	}

	if (!hdr.init(graphics, static_cast<unsigned>(width), static_cast<unsigned>(height)))
	{
		return false;
	}

	if (!fullscreen_quad.init(graphics))
	{
		return false;
	}

	camera.SetCameraMode(Camera::CameraModeFPS);
	camera.SetAspect(width / height);
	camera.SetFOVY(ToRadian(60));
	camera.SetNearPlane(1.f);
	camera.SetFarPlane(300.f);
	camera.SetMinXAngle(ToRadian(80.f));
	camera.SetMaxXAngle(ToRadian(80.f));
	camera.SetRoll(0.f);

	camera.SetEye(Vector3(0.f, 2.f, -3.f));
	camera.SetLookat(Vector3(0.f, 1.f, 0.f));

	stime = 0.f;
	scroll_pos1 = 1.f;
	scroll_pos2 = 0.f;
	scroll_pos3 = 0.f;

	// default scene
	includer.setSubstitutions({ {"sdf_scene.hlsl", "scenes/sdf_scene_cube3.hlsl"} });
	initShader();

	return true;
}

void Application::initShader()
{
	variable_manager.resetVariables();

	fullscreen_quad.initShader(includer);
	if (sdf_renderer.initShader(includer))
	{
		variable_manager.setVariables("scene", &sdf_renderer.getVariableMap());
	}
	hdr.initShader(includer);

	variable_manager.createControls();

	do_single_renderer = true; // after a shader refresh, render one frame as preview
}

void Application::render()
{
	if (profiler.fetchResults())
	{
		auto results = profiler.getResults();
#ifdef PROFILE_OUTPUT
		OutputDebugString("======================\n");
		for (auto &elem : results)
		{
			std::string name = elem.first.empty() ? "Total" : elem.first;
			std::string msg = Format() << name << ": " << elem.second * 1000.f << "ms\n";
			OutputDebugString(msg.c_str());
		}
#endif
	}

	SDFRenderer::DebugPlane debug_plane;
	debug_plane.show = show_debug_plane;
	debug_plane.ruler_scale = 0.05f;
	if (show_debug_plane)
	{
		if (scroll_pos1 > 0.f)
		{
			debug_plane.normal = Math3D::Matrix4x4::RotationXMatrix(scroll_pos1 * Math3D::PI * +0.5f) * Math3D::Vector3(0.f, 1.f, 0.f);
		}
		else
		{
			debug_plane.normal = Math3D::Matrix4x4::RotationZMatrix(scroll_pos1 * Math3D::PI * -0.5f) * Math3D::Vector3(0.f, 1.f, 0.f);
		}
	}
	else
	{
		debug_plane.normal = Math3D::Vector3::NullVector();
	}
	debug_plane.point = debug_plane.normal * scroll_pos2;

	sdf_renderer.setParameters(debug_plane, stime);

	float clear_color[4] = {0.25f, 0.f, 0.f, 0.f};
	auto ctx = graphics.GetContext();

	profiler.beginFrame();

	auto main_rendertarget = graphics.GetMainRendertargetView();
	auto hdr_rendertarget = hdr.getRenderTarget();

	ctx->OMSetRenderTargets(1, &hdr_rendertarget, nullptr);

	ctx->ClearRenderTargetView(hdr_rendertarget, clear_color);
	profiler.profile("clear");

	if (sdf_renderer.render(fullscreen_quad, profiler, camera))
	{
		hdr.process(fullscreen_quad, profiler, main_rendertarget);
	}
	else
	{
		ctx->OMSetRenderTargets(1, &main_rendertarget, nullptr);
		ctx->ClearRenderTargetView(main_rendertarget, clear_color);
	}

	graphics.Present();
	profiler.profile("present");
	profiler.endFrame();

	graphics.WaitForVBlank();
}

void Application::updateSimulation(float dt)
{
	if (!paused)
	{
		stime += dt;
	}
	float speed = input_manager.getKeyState(VK_SHIFT) ? 5.f : 2.f;

	Vector3 move = Vector3::NullVector();
	move += Vector3(+1.f, 0.f, 0.f) * input_manager.getKeyStateAsFloat('D');
	move += Vector3(-1.f, 0.f, 0.f) * input_manager.getKeyStateAsFloat('A');
	move += Vector3(0.f, +1.f, 0.f) * input_manager.getKeyStateAsFloat('Q');
	move += Vector3(0.f, -1.f, 0.f) * input_manager.getKeyStateAsFloat('E');
	move += Vector3(0.f, 0.f, +1.f) * input_manager.getKeyStateAsFloat('W');
	move += Vector3(0.f, 0.f, -1.f) * input_manager.getKeyStateAsFloat('S');

	camera.MoveRel(move * speed * dt);
}

void Application::loadScene(const std::filesystem::path &filename)
{
	includer.setSubstitutions({ {"sdf_scene.hlsl", filename.string()} });
	initShader();
}