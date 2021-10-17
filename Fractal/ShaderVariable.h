#pragma once

#include <map>
#include <string>

struct Variable
{
	float minval, maxval, start, step;
	float value; // the current value
};

using VariableMap = std::map<std::string, Variable, std::less<>>;