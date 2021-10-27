#include <Windows.h>

#include "Application.h"

#pragma comment(linker,"\"/manifestdependency:type='win32' \
name='Microsoft.Windows.Common-Controls' version='6.0.0.0' \
processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"")

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE, char *, int)
{
	Application app;

	if (app.Init(hInstance))
	{
		app.Run();
		return 0;
	}
	return -1;
}
