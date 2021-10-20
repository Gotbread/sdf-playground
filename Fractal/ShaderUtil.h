#pragma once

#include "Comptr.h"
#include "ShaderVariable.h"

#include <d3dcommon.h>
#include <d3d11.h>
#include <string>
#include <string_view>
#include <vector>
#include <map>
#include <filesystem>

class ShaderVariableManager;
class ShaderCodeGenerator;

class ShaderIncluder : public ID3DInclude
{
public:
	using Substitution = std::pair<std::string, std::string>;
	using MemoryHeader = std::pair<std::string, std::string>;

	void setFolder(std::string_view folder);
	void setSubstitutions(std::vector<Substitution> substitutions);
	void setExtraHeaders(std::vector<MemoryHeader> headers);
	void setShaderVariableManager(ShaderVariableManager *var_manager);
	void setShaderCodeGenerator(ShaderCodeGenerator *code_generator);

	HRESULT STDMETHODCALLTYPE Open(D3D_INCLUDE_TYPE IncludeType, LPCSTR pFileName, LPCVOID pParentData, LPCVOID *ppData, UINT *pBytes);
	HRESULT STDMETHODCALLTYPE Close(LPCVOID pData);

	// in this class so we bundle all the file handling at one place
	bool loadFromFile(const std::string &filename, std::string &code);
private:
	std::filesystem::path folder;
	std::vector<Substitution> substitutions;
	std::vector<MemoryHeader> headers;

	ShaderVariableManager *var_manager = nullptr;
	ShaderCodeGenerator *code_generator = nullptr;
};

class ShaderVariableManager
{
public:
	// sets the slot of the corresponding constant buffer
	void setSlot(unsigned slot);
	// parses the input shader, replaces all variable encounters
	// and also creates the variable entries
	bool parseFile(const std::string &input, std::string &output);
	std::string generateHeader() const;

	bool hasVariables() const;
	VariableMap &getVariables();
	void setValue(std::string_view name, float val);

	bool createConstantBuffer(ID3D11Device *dev);
	void updateBuffer(ID3D11DeviceContext *ctx);
	ID3D11Buffer *getBuffer();
private:
	static std::string_view getVarTag();

	VariableMap variables;
	unsigned slot;

	Comptr<ID3D11Buffer> cbuffer;
};

class ShaderCodeGenerator
{
public:
	bool parseFile(const std::string &input, std::string &output);
};

Comptr<ID3DBlob> compileShader(ShaderIncluder &includer, const std::string &filename, const std::string &profile, const std::string &entry, bool display_warnings = true, bool disassemble = false);