#pragma once

#include <string>
#include <string_view>
#include <fstream>
#include <sstream>
#include <vector>

class Format
{
public:
	template<class T>
	Format &operator << (const T &t)
	{
		invalidate_cache();
		stream << t;
		return *this;
	}

	operator const std::string &()
	{
		update_cache();
		return str_cache;
	}

	operator const char *()
	{
		update_cache();
		return str_cache.c_str();
	}
	std::stringstream &get_stream()
	{
		return stream;
	}
private:
	void invalidate_cache()
	{
		str_cache.clear();
	}

	void update_cache()
	{
		if (str_cache.empty())
		{
			str_cache = stream.str();
		}
	}
	
	std::stringstream stream;
	std::string str_cache;
};

template<class T, size_t N>
void set_array(T (&arr)[N], const T &setval)
{
	for (auto elem : arr)
	{
		elem = setval;
	}
}

std::string_view removeSpaces(std::string_view input);
std::pair<std::vector<std::string_view>, std::vector<std::string_view>> splitString(std::string_view input, std::string_view pattern_start, std::string_view pattern_end = {});

std::string readFromFile(std::ifstream &file);
void ErrorBox(const std::string &msg);
void WarningBox(const std::string &msg);
std::string changeFileExtension(std::string_view filename, std::string_view new_extension);