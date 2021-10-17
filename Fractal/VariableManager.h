#pragma once

#include "ShaderVariable.h"

#include <Windows.h>
#include <string>
#include <map>
#include <vector>

class VariableManager
{
public:
	void InitClass(HINSTANCE hInstance);
	bool Open();

	void resetVariables();
	void setVariables(std::string_view name, VariableMap *var_map);
	void createControls();
private:
	struct Slider
	{
		HWND hLabel, hSlider, hValue;
		Variable *var;

		int valueToSlider(float value) const;
		float sliderToValue(int slider) const;
		void setSliderToValue();
		void setEditBoxToValue();

		// transforms the range 0 to N from the slider control into the
		// value for the variable: slider * scale + offset = variable
		float scale, offset;
	};

	LRESULT CALLBACK WndProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
	static LRESULT CALLBACK sWndProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);

	HINSTANCE hInstance;
	HWND hWnd = 0;

	std::vector<Slider> controls;
	std::map<std::string, VariableMap *> var_maps;

	unsigned window_width, window_height;
	DWORD window_style;
	static const char *classname;
};
