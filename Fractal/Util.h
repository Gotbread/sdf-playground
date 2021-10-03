#pragma once

#include <string>
#include <fstream>
#include <sstream>


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


std::string readFromFile(std::ifstream &file);
void ErrorBox(const std::string &msg);
void WarningBox(const std::string &msg);
std::string changeFileExtension(const std::string &filename, const std::string &new_extension);