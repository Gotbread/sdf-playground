#pragma once

#include "Comptr.h"

#include <d3dcommon.h>
#include <string>
#include <vector>
#include <filesystem>


class ShaderIncluder : public ID3DInclude
{
public:
	using Substitution = std::pair<std::string, std::string>;
	using MemoryHeader = std::pair<std::string, std::string>;

	void setFolder(const std::string &folder);
	void setSubstitutions(std::vector<Substitution> substitutions);
	void setExtraHeaders(std::vector<MemoryHeader> headers);

	HRESULT STDMETHODCALLTYPE Open(D3D_INCLUDE_TYPE IncludeType, LPCSTR pFileName, LPCVOID pParentData, LPCVOID *ppData, UINT *pBytes);
	HRESULT STDMETHODCALLTYPE Close(LPCVOID pData);

	// in this class so we bundle all the file handling at one place
	bool loadFromFile(const std::string &filename, std::string &code);
private:
	std::filesystem::path folder;
	std::vector<Substitution> substitutions;
	std::vector<MemoryHeader> headers;
};

class ShaderVariableManager
{
public:
	struct Variable
	{
		float minval, maxval, defaultval, steps;
	};
	// parses the input shader, replaces all variable encounters
	// and also creates the variable entries
	void parseFile(const std::string &input, std::string &output);
	std::string generateHeader() const;
private:
	std::vector<std::pair<std::string, Variable>> variables;
};

Comptr<ID3DBlob> compileShader(ShaderIncluder &includer, const std::string &filename, const std::string &profile, const std::string &entry, bool display_warnings = true, bool disassemble = false);