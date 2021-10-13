#include "WinUtil.h"

std::string getStringFromListbox(HWND hWnd, int index)
{
	int len = SendMessage(hWnd, LB_GETTEXTLEN, index, 0);
	std::string text(len, 0);
	SendMessage(hWnd, LB_GETTEXT, index, reinterpret_cast<LPARAM>(text.data()));
	return text;
}