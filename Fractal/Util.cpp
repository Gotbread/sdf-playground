#include "Util.h"
#include <Windows.h>


std::string readFromFile(std::ifstream &file)
{
	std::string ret;
	char buffer[4096];
	while (file.read(buffer, sizeof(buffer)))
		ret.append(buffer, sizeof(buffer));
	ret.append(buffer, static_cast<size_t>(file.gcount()));
	return ret;
}

void ErrorBox(const std::string &msg)
{
	MessageBoxA(0, msg.c_str(), "Error", MB_ICONERROR);
}

void WarningBox(const std::string &msg)
{
	MessageBoxA(0, msg.c_str(), "Warning", MB_ICONWARNING);
}

std::string changeFileExtension(const std::string &filename, const std::string &new_extension)
{
	constexpr auto npos = std::string::npos;
	auto index_dot = filename.rfind(".");
	auto index_slash1 = filename.rfind("/");
	auto index_slash2 = filename.rfind("\\");
	auto index_slash = std::max(index_slash1 + 1, index_slash2 + 1) - 1; // use overflow to get the correct behaviour

	if (index_dot == npos) // no dot at all. just append the new extension
	{
		return filename + new_extension;
	}

	// if the dot is before the last slash, its not an extension
	if (index_slash != npos && index_dot < index_slash)
	{
		return filename + new_extension;
	}

	// in all other cases we can safely replace the part after the dot
	return filename.substr(0, index_dot + 1) + new_extension;
}