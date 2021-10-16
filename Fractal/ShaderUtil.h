#pragma once

#include "Comptr.h"

#include <d3dcommon.h>
#include <d3d11.h>
#include <string>
#include <vector>
#include <map>
#include <filesystem>

class ShaderVariableManager;

class ShaderIncluder : public ID3DInclude
{
public:
	using Substitution = std::pair<std::string, std::string>;
	using MemoryHeader = std::pair<std::string, std::string>;

	void setFolder(const std::string &folder);
	void setSubstitutions(std::vector<Substitution> substitutions);
	void setExtraHeaders(std::vector<MemoryHeader> headers);
	void setShaderVariableManager(ShaderVariableManager *var_manager);

	HRESULT STDMETHODCALLTYPE Open(D3D_INCLUDE_TYPE IncludeType, LPCSTR pFileName, LPCVOID pParentData, LPCVOID *ppData, UINT *pBytes);
	HRESULT STDMETHODCALLTYPE Close(LPCVOID pData);

	// in this class so we bundle all the file handling at one place
	bool loadFromFile(const std::string &filename, std::string &code);
private:
	std::filesystem::path folder;
	std::vector<Substitution> substitutions;
	std::vector<MemoryHeader> headers;
	ShaderVariableManager *var_manager;
};

class ShaderVariableManager
{
public:
	struct Variable
	{
		float minval, maxval, start, step;
		float value; // the current value
	};

	// sets the slot of the corresponding constant buffer
	void setSlot(unsigned slot);
	// parses the input shader, replaces all variable encounters
	// and also creates the variable entries
	bool parseFile(const std::string &input, std::string &output);
	std::string generateHeader() const;

	bool hasVariables() const;
	std::map<std::string, Variable> &getVariables();
	void setValue(const std::string &name, float val);

	bool createConstantBuffer(ID3D11Device *dev);
	void updateBuffer(ID3D11DeviceContext *ctx);
	ID3D11Buffer *getBuffer();
private:
	std::map<std::string, Variable> variables;
	unsigned slot;

	Comptr<ID3D11Buffer> cbuffer;
};

Comptr<ID3DBlob> compileShader(ShaderIncluder &includer, const std::string &filename, const std::string &profile, const std::string &entry, bool display_warnings = true, bool disassemble = false);