#include <Windows.h>

#include "Application.h"


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
