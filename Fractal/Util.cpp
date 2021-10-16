#include "Util.h"
#include <Windows.h>

std::string_view removeSpaces(std::string_view input)
{
	auto iter = input.begin();
	while (iter != input.end() && isspace(static_cast<unsigned>(*iter)))
		++iter;

	auto iter2 = iter;
	while (iter2 != input.end() && !isspace(static_cast<unsigned char>(*iter2)))
		++iter2;

	return std::string_view(iter, iter2);
}

std::pair<std::vector<std::string_view>, std::vector<std::string_view>> splitString(std::string_view input, std::string_view pattern_start, std::string_view pattern_end)
{
	std::vector<std::string_view> parts, separators;

	std::string_view::size_type current = 0, npos = std::string_view::npos;
	for (;;)
	{
		auto index_start = input.find(pattern_start, current);
		if (index_start != npos)
		{
			auto index_end = input.find(pattern_end, index_start + pattern_start.size());
			if (index_end != npos)
			{
				index_end += pattern_end.size();
				parts.push_back(input.substr(current, index_start - current));
				separators.push_back(input.substr(index_start, index_end - index_start));
				current = index_end;
			}
			else
			{
				break;
			}
		}
		else
		{
			break;
		}
	}
	// append the rest
	parts.push_back(input.substr(current));

	return { parts, separators };
}

std::string readFromFile(std::ifstream &file)
{
	std::string ret;
	std::string buffer(4096, 0);
	while (file.read(buffer.data(), buffer.size()))
		ret.append(buffer, 0, buffer.size());
	ret.append(buffer, 0, static_cast<size_t>(file.gcount()));
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

std::string mergeViews(std::string_view str1, std::string_view str2)
{
	std::string res;
	res.reserve(str1.size() + str2.size());
	return res.append(str1).append(str2);
}

std::string changeFileExtension(std::string_view filename, std::string_view new_extension)
{
	constexpr auto npos = std::string::npos;
	auto index_dot = filename.rfind(".");
	auto index_slash1 = filename.rfind("/");
	auto index_slash2 = filename.rfind("\\");
	auto index_slash = std::max(index_slash1 + 1, index_slash2 + 1) - 1; // use overflow to get the correct behaviour

	if (index_dot == npos) // no dot at all. just append the new extension
	{
		return mergeViews(filename, new_extension);
	}

	// if the dot is before the last slash, its not an extension
	if (index_slash != npos && index_dot < index_slash)
	{
		return mergeViews(filename, new_extension);
	}

	// in all other cases we can safely replace the part after the dot
	return mergeViews(filename.substr(0, index_dot + 1), new_extension);
}