#include "VariableManager.h"
#include "WinUtil.h"
#include "Util.h"

#include <CommCtrl.h>
#include <cmath>

const char *VariableManager::classname = "Variablemanager";

void VariableManager::InitClass(HINSTANCE hInstance)
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

	window_style = WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;
	window_width = 540;
	window_height = 0;
}

bool VariableManager::Open()
{
	if (hWnd) // already open
	{
		return false;
	}

	RECT r;
	SetRect(&r, 0, 0, window_width, window_height);
	AdjustWindowRect(&r, window_style, 0);
	hWnd = CreateWindow(classname, "Variable Manager", window_style, CW_USEDEFAULT, CW_USEDEFAULT, r.right - r.left, r.bottom - r.top, 0, 0, hInstance, this);

	if (!hWnd)
	{
		return false;
	}

	ShowWindow(hWnd, SW_SHOWNORMAL);
	return true;
}

void VariableManager::resetVariables()
{
	var_maps.clear();
}

void VariableManager::setVariables(std::string_view name, VariableMap *var_map)
{
	var_maps[std::string(name)] = var_map;
}

void VariableManager::createControls()
{
	// remove old windows
	for (auto &slider : controls)
	{
		DestroyWindow(slider.hLabel);
		DestroyWindow(slider.hSlider);
		DestroyWindow(slider.hValue);
	}
	controls.clear();

	size_t count = 0;
	for (auto &[name, map] : var_maps)
	{
		count += map->size();
	}

	unsigned height_per_element = 40;

	// resize the window
	RECT r;
	SetRect(&r, 0, 0, window_width, static_cast<int>(count * height_per_element));
	AdjustWindowRect(&r, window_style, 0);
	SetWindowPos(hWnd, 0, 0, 0, r.right - r.left, r.bottom - r.top, SWP_NOMOVE | SWP_NOOWNERZORDER);

	auto CW = [this](const char *classname, const char *name, DWORD style, int x, int y, int w, int h)
	{
		return CreateWindow(classname, name, style | WS_CHILD | WS_VISIBLE, x, y, w, h, hWnd, 0, hInstance, 0);
	};

	unsigned y = 0;
	// create new controls
	for (auto &[scene_name, var_map] : var_maps)
	{
		for (auto &[var_name, var] : *var_map)
		{
			std::string name = std::string(scene_name) + "." + var_name;

			Slider slider;
			slider.scale = var.maxval > var.minval ? var.step : -var.step;
			slider.offset = var.minval;

			slider.hLabel = CW("STATIC", name.c_str(), 0, 10, y + 10, 200, 25);
			slider.hSlider = CW(TRACKBAR_CLASS, "", TBS_HORZ, 220, y + 10, 200, 25);
			slider.hValue = CW("EDIT", "", WS_BORDER, 430, y + 10, 100, 25);
			slider.var = &var;

			int steps = slider.valueToSlider(var.maxval);
			SendMessage(slider.hSlider, TBM_SETRANGE, FALSE, MAKELONG(0, steps));
			
			slider.setSliderToValue();
			slider.setEditBoxToValue();

			controls.push_back(slider);
			y += height_per_element;
		}
	}
}

LRESULT CALLBACK VariableManager::sWndProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam)
{
	if (Msg == WM_NCCREATE)
	{
		SetWindowLongPtr(hWnd, 0, reinterpret_cast<LONG_PTR>(reinterpret_cast<CREATESTRUCT *>(lParam)->lpCreateParams));
	}
	VariableManager *mng = reinterpret_cast<VariableManager *>(GetWindowLongPtr(hWnd, 0));
	if (mng)
	{
		return mng->WndProc(hWnd, Msg, wParam, lParam);
	}
	return DefWindowProc(hWnd, Msg, wParam, lParam);
}

LRESULT CALLBACK VariableManager::WndProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam)
{
	switch (Msg)
	{
	case WM_HSCROLL:
		{
			HWND hControl = reinterpret_cast<HWND>(lParam);
			if (hControl)
			{
				for (auto &control : controls)
				{
					if (control.hSlider == hControl)
					{
						WORD code = LOWORD(wParam);
						int pos = -1;
						if (code == SB_THUMBPOSITION || code == SB_THUMBTRACK)
						{
							pos = HIWORD(wParam);
						}
						else
						{
							pos = SendMessage(control.hSlider, TBM_GETPOS, 0, 0);
						}

						control.var->value = control.sliderToValue(pos);
						control.setEditBoxToValue();
						break;
					}
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

int VariableManager::Slider::valueToSlider(float value) const
{
	return static_cast<int>(round((value - offset) / scale));
}

float VariableManager::Slider::sliderToValue(int slider) const
{
	return slider * scale + offset;
}

void VariableManager::Slider::setSliderToValue()
{
	int pos = valueToSlider(var->value);
	SendMessage(hSlider, TBM_SETPOS, TRUE, pos);
}

void VariableManager::Slider::setEditBoxToValue()
{
	std::string value_string = std::to_string(var->value);
	SetWindowText(hValue, value_string.c_str());
}