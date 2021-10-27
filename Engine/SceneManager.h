#pragma once

#include <Windows.h>
#include <string>
#include <filesystem>

class SceneManagerClient
{
public:
	virtual ~SceneManagerClient() = default;
	virtual void loadScene(const std::filesystem::path &filename) = 0;
};

class SceneManager
{
public:
	void InitClass(HINSTANCE hInstance);
	bool Open();

	void setShaderFolder(const std::string &folder);
	void setSceneFolder(const std::string &folder);

	void setClient(SceneManagerClient *client);
private:
	LRESULT CALLBACK WndProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
	static LRESULT CALLBACK sWndProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);

	void updateSceneList();
	std::filesystem::path getFullFilename(const std::filesystem::path &filename);
	void loadScene(const std::filesystem::path &filename);

	HINSTANCE hInstance;
	HWND hWnd = 0;

	HWND hSceneSelect, hSceneRefresh, hSceneLoad;
	HWND hReloadOnSave;

	bool reload_on_save = false;
	std::filesystem::file_time_type last_time;

	std::filesystem::path shader_folder, scene_folder;

	SceneManagerClient *client = nullptr;

	static const char *classname;
};
