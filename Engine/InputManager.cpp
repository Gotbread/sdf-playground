#include "InputManager.h"
#include "Util.h"

InputManager::InputManager()
{
	set_array(keystate, false);
	set_array(mouse_state, false);
}

void InputManager::processMessage(UINT Msg, WPARAM wParam, LPARAM lParam)
{
	switch (Msg)
	{
	case WM_MOUSEMOVE:
		{
			int xpos = LOWORD(lParam);
			int ypos = HIWORD(lParam);

			if (lastmouse)
			{
				int xdiff = LOWORD(lParam) - lastmouse->x;
				int ydiff = HIWORD(lParam) - lastmouse->y;
				motion = { xdiff, ydiff };
			}

			lastmouse = { xpos, ypos };
		}
		break;
	case WM_KEYDOWN:
		// for movement
		keystate[static_cast<char>(LOWORD(wParam))] = true;
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
	}
}

std::optional<POINT> InputManager::getMotion(bool reset)
{
	auto res = motion;
	if (reset)
	{
		motion.reset();
	}
	return res;
}

bool InputManager::getKeyState(unsigned char key) const
{
	return keystate[key];
}

bool InputManager::getKeyStateAsFloat(unsigned char key) const
{
	return getKeyState(key) ? 1.f : 0.f;
}

bool InputManager::getMouseState(MouseButton button) const
{
	return mouse_state[button];
}