#pragma once

#include <Windows.h>
#include <optional>

class InputManager
{
public:
	enum MouseButton
	{
		Left = 0,
		Middle = 1,
		Right = 2,
	};

	InputManager();

	void processMessage(UINT Msg, WPARAM wParam, LPARAM lParam);
	std::optional<POINT> getMotion(bool reset = true);
	
	bool getMouseState(MouseButton button) const;
	bool getKeyState(unsigned char key) const;
	bool getKeyStateAsFloat(unsigned char key) const;
private:
	std::optional<POINT> lastmouse;
	std::optional<POINT> motion;
	bool keystate[256];
	bool mouse_state[3];
};