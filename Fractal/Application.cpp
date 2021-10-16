#include <string>
#include <vector>
#include <fstream>
#include <sstream>

#include "Application.h"
#include "Math3D.h"
#include "Util.h"

#pragma comment(lib, "d3dcompiler.lib")

using namespace Math3D;

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
		unsigned width = 800;
		unsigned height = 600;

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

	set_array(keystate, false);
	set_array(mouse_state, false);
	show_debug_plane = false;

	return true;
}

void Application::Run()
{
	ShowWindow(hWnd, SW_SHOWNORMAL);

	// the overflow warning can be ignored. since we are taking the difference only
	// and a frame wont last more than 49 days (hopefully), we cant overflow
	auto lasttime = GetTickCount64();

	MSG Msg;
	do
	{
		while (PeekMessage(&Msg, 0, 0, 0, PM_REMOVE))
		{
			TranslateMessage(&Msg);
			DispatchMessage(&Msg);
		}

		auto newtime = GetTickCount64();
		unsigned diff = static_cast<unsigned>(newtime - lasttime);
		lasttime = newtime;

		updateSimulation(static_cast<float>(diff) / 1000.f);
		render();
	}
	while (Msg.message != WM_QUIT);
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
	switch (Msg)
	{
	case WM_MOUSEMOVE:
		{
			int xdiff = LOWORD(lParam) - lastmouse.x;
			int ydiff = HIWORD(lParam) - lastmouse.y;
			if (mouse_state[MouseButton::Left])
			{
				if (xdiff || ydiff)
				{
					camera.RotateY(xdiff / -500.f);
					camera.RotateX(ydiff / -500.f);
				}
			}
			if (mouse_state[MouseButton::Middle])
			{
				scroll_pos1 += xdiff / 1000.f;
				scroll_pos1 = std::min(std::max(scroll_pos1, -1.f), +1.f);

				scroll_pos2 += ydiff / 1000.f;
				scroll_pos2 = std::min(std::max(scroll_pos2, -10.f), +10.f);
			}
			if (mouse_state[MouseButton::Right])
			{
				scroll_pos3 += xdiff / 1000.f;
				scroll_pos3 = std::min(std::max(scroll_pos3, 0.f), 1.f);
			}
			lastmouse.x = LOWORD(lParam);
			lastmouse.y = HIWORD(lParam);
		}
		break;
	case WM_KEYDOWN:
		// for movement
		keystate[static_cast<char>(LOWORD(wParam))] = true;

		if (keystate[VK_CONTROL]) // ctrl events
		{
			switch (LOWORD(wParam))
			{
			case 'R': // reload shader
				initShader();
				break;
			case 'S': // scene manager
				scene_manager.Open(hInstance);
				break;
			case 'V': // variable manager
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
			}
		}
		break;
	case WM_KEYUP:
		keystate[static_cast<char>(LOWORD(wParam))] = false;
		break;
	case WM_LBUTTONDOWN:
		mouse_state[MouseButton::Left] = true;
		break;
	case WM_LBUTTONUP:
		mouse_state[MouseButton::Left] = false;
		break;
	case WM_MBUTTONDOWN:
		mouse_state[MouseButton::Middle] = true;
		show_debug_plane ^= true;
		break;
	case WM_MBUTTONUP:
		mouse_state[MouseButton::Middle] = false;
		break;
	case WM_RBUTTONDOWN:
		mouse_state[MouseButton::Right] = true;
		break;
	case WM_RBUTTONUP:
		mouse_state[MouseButton::Right] = false;
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
	scene_manager.Open(hInstance);

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
	includer.setSubstitutions({ {"sdf_scene.hlsl", "scenes/sdf_scene_cube.hlsl"} });
	initShader();

	return true;
}

void Application::initShader()
{
	fullscreen_quad.initShader(includer);
	sdf_renderer.initShader(includer);
	hdr.initShader(includer);
}

void Application::render()
{
	if (profiler.fetchResults())
	{
		auto results = profiler.getResults();
		OutputDebugString("======================\n");
		for (auto &elem : results)
		{
			std::string name = elem.first.empty() ? "Total" : elem.first;
			std::string msg = Format() << name << ": " << elem.second * 1000.f << "ms\n";
			OutputDebugString(msg.c_str());
		}
	}

	SDFRenderer::DebugPlane debug_plane;
	debug_plane.show = show_debug_plane;
	debug_plane.ruler_scale = 1.f;
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
	stime += dt;
	float speed = 2.f;

	Vector3 move = Vector3::NullVector();
	if (keystate['W'])
	{
		move += Vector3(0.f, 0.f, +1.f);
	}
	if (keystate['S'])
	{
		move += Vector3(0.f, 0.f, -1.f);
	}
	if (keystate['A'])
	{
		move += Vector3(-1.f, 0.f, 0.f);
	}
	if (keystate['D'])
	{
		move += Vector3(+1.f, 0.f, 0.f);
	}
	if (keystate['Q'])
	{
		move += Vector3(0.f, +1.f, 0.f);
	}
	if (keystate['E'])
	{
		move += Vector3(0.f, -1.f, 0.f);
	}
	if (keystate[VK_SHIFT])
	{
		speed = 5.f;
	}

	camera.MoveRel(move * speed * dt);
}

void Application::loadScene(const std::filesystem::path &filename)
{
	includer.setSubstitutions({ {"sdf_scene.hlsl", filename.string()} });
	initShader();
}