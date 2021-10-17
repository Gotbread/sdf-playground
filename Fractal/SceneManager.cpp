#include "SceneManager.h"
#include "WinUtil.h"

#include <filesystem>
#include <chrono>

const char *SceneManager::classname = "Scenemanager";

void SceneManager::InitClass(HINSTANCE hInstance)
{
	this->hInstance = hInstance;

	WNDCLASS wc = { 0 };
	wc.cbWndExtra = sizeof(this);
	wc.hCursor = LoadCursor(0, IDC_ARROW);
	wc.hbrBackground = GetSysColorBrush(COLOR_WINDOW);
	wc.hInstance = hInstance;
	wc.lpszClassName = classname;
	wc.lpfnWndProc = sWndProc;

	RegisterClass(&wc);
}

bool SceneManager::Open()
{
	if (hWnd) // already open
	{
		return false;
	}

	unsigned width = 430;
	unsigned height = 350;
	DWORD windowstyle = WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;

	RECT r;
	SetRect(&r, 0, 0, width, height);
	AdjustWindowRect(&r, windowstyle, 0);
	hWnd = CreateWindow(classname, "Scene Manager", windowstyle, CW_USEDEFAULT, CW_USEDEFAULT, r.right - r.left, r.bottom - r.top, 0, 0, hInstance, this);

	if (!hWnd)
	{
		return false;
	}

	// create all controls
	DWORD child_style = WS_CHILD | WS_VISIBLE;
	hSceneSelect = CreateWindow("LISTBOX", "", child_style | WS_BORDER | WS_VSCROLL, 10, 10, 300, 300, hWnd, 0, hInstance, 0);
	hSceneRefresh = CreateWindow("BUTTON", "Refresh", child_style, 320, 10, 100, 25, hWnd, 0, hInstance, 0);
	hSceneLoad = CreateWindow("BUTTON", "Load Scene", child_style, 320, 45, 100, 25, hWnd, 0, hInstance, 0);
	hReloadOnSave = CreateWindow("BUTTON", "Reload on save", child_style | BS_AUTOCHECKBOX, 10, 320, 200, 20, hWnd, 0, hInstance, 0);

	updateSceneList();

	ShowWindow(hWnd, SW_SHOWNORMAL);
	return true;
}

void SceneManager::setShaderFolder(const std::string &folder)
{
	shader_folder = folder;
}

void SceneManager::setSceneFolder(const std::string &folder)
{
	scene_folder = folder;
}

LRESULT CALLBACK SceneManager::sWndProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam)
{
	if (Msg == WM_NCCREATE)
	{
		SetWindowLongPtr(hWnd, 0, reinterpret_cast<LONG_PTR>(reinterpret_cast<CREATESTRUCT *>(lParam)->lpCreateParams));
	}
	SceneManager *mng = reinterpret_cast<SceneManager *>(GetWindowLongPtr(hWnd, 0));
	if (mng)
	{
		return mng->WndProc(hWnd, Msg, wParam, lParam);
	}
	return DefWindowProc(hWnd, Msg, wParam, lParam);
}

LRESULT CALLBACK SceneManager::WndProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam)
{
	switch (Msg)
	{
	case WM_COMMAND:
		{
			HWND hControl = reinterpret_cast<HWND>(lParam);
			if (hControl == hSceneRefresh)
			{
				updateSceneList();
			}
			else if (hControl == hSceneLoad)
			{
				LRESULT index = SendMessage(hSceneSelect, LB_GETCURSEL, 0, 0);
				if (index != LB_ERR)
				{
					auto filename = getStringFromListbox(hSceneSelect, static_cast<int>(index));
					loadScene(getFullFilename(filename));
				}
			}
			else if (hControl == hReloadOnSave)
			{
				reload_on_save = SendMessage(hReloadOnSave, BM_GETCHECK, 0, 0) == BST_CHECKED;
				if (reload_on_save)
				{
					SetTimer(hWnd, 0, 500, 0);
				}
				else
				{
					KillTimer(hWnd, 0);
					last_time = std::chrono::file_clock::now();
				}
			}
		}
		break;
	case WM_TIMER:
		if (reload_on_save)
		{
			LRESULT index = SendMessage(hSceneSelect, LB_GETCURSEL, 0, 0);
			if (index != LB_ERR)
			{
				auto filename = getStringFromListbox(hSceneSelect, static_cast<int>(index));
				auto full_filename = getFullFilename(filename);

				auto write_time = std::filesystem::last_write_time(shader_folder / full_filename);
				if (write_time > last_time)
				{
					last_time = write_time;
					loadScene(full_filename);
				}
			}
		}
		break;
	case WM_DESTROY:
		this->hWnd = 0;
		break;
	}
	return DefWindowProc(hWnd, Msg, wParam, lParam);
}

void SceneManager::updateSceneList()
{
	SendMessage(hSceneSelect, LB_RESETCONTENT, 0, 0);

	for (auto &dir_entry : std::filesystem::directory_iterator(shader_folder / scene_folder))
	{
		if (dir_entry.is_regular_file())
		{
			auto path = dir_entry.path();
			if (path.extension() == ".hlsl")
			{
				std::string name = path.stem().string();
				SendMessage(hSceneSelect, LB_ADDSTRING, 0, reinterpret_cast<LPARAM>(name.c_str()));
			}
		}
	}
}

void SceneManager::loadScene(const std::filesystem::path &filename)
{
	if (client)
	{
		client->loadScene(filename);
	}
	//MessageBox(0, filename.string().c_str(), "now loading:", MB_ICONINFORMATION);
}

std::filesystem::path SceneManager::getFullFilename(const std::filesystem::path &filename)
{
	return scene_folder / std::filesystem::path(filename).concat(".hlsl");
}

void SceneManager::setClient(SceneManagerClient *client)
{
	this->client = client;
}
