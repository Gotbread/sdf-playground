#include "ShaderUtil.h"
#include "Util.h"

#include <fstream>
#include <d3dcompiler.h>
#include <string_view>
#include <algorithm>

#pragma comment(lib, "d3dcompiler.lib")

void ShaderIncluder::setFolder(std::string_view folder)
{
	this->folder = folder;
}

void ShaderIncluder::setSubstitutions(std::vector<ShaderIncluder::Substitution> substitutions)
{
	this->substitutions.swap(substitutions);
}

void ShaderIncluder::setExtraHeaders(std::vector<MemoryHeader> headers)
{
	this->headers.swap(headers);
}

void ShaderIncluder::setShaderVariableManager(ShaderVariableManager *var_manager)
{
	this->var_manager = var_manager;
}

void ShaderIncluder::setPass(ShaderPass pass)
{
	if (var_manager)
	{
		var_manager->setPass(pass);
	}
}

bool ShaderIncluder::hasVarManager() const
{
	return var_manager;
}

HRESULT STDMETHODCALLTYPE ShaderIncluder::Open(D3D_INCLUDE_TYPE IncludeType, LPCSTR pFileName, LPCVOID pParentData, LPCVOID *ppData, UINT *pBytes)
{
	std::string code;
	if (!loadFromFile(pFileName, code))
	{
		return D3D11_ERROR_FILE_NOT_FOUND; // let D3D deal with the error
	}

	UINT size = static_cast<UINT>(code.size());
	char *data = new char[size];
	memcpy(data, code.c_str(), size);
	*ppData = data;
	*pBytes = size;

	return S_OK;
}

HRESULT STDMETHODCALLTYPE ShaderIncluder::Close(LPCVOID pData)
{
	delete[] static_cast<const char *>(pData);
	return S_OK;
}

bool ShaderIncluder::loadFromFile(const std::string &filename, std::string &code)
{
	// do we have this header preloaded?
	for (const auto &[header_filename, header_code] : headers)
	{
		if (header_filename == filename)
		{
			code = header_code;
			return true;
		}
	}

	// else load it from file. but which file?
	// a subtituted one?
	const std::string *final_filename = &filename;
	for (const auto &[old_filename, new_filename] : substitutions)
	{
		if (old_filename == filename)
		{
			final_filename = &new_filename;
			break;
		}
	}

	std::ifstream file(folder / *final_filename);
	if (!file)
	{
		return false;
	}

	code = readFromFile(file);

	if (var_manager)
	{
		std::string new_code;
		var_manager->parseFile(code, new_code);
		code.swap(new_code);

		std::string header = var_manager->generateHeader();
		setExtraHeaders({ { "user_variables.hlsl", header } });
	}

	return true;
}

void ShaderVariableManager::setSlot(unsigned slot)
{
	this->slot = slot;
}

void ShaderVariableManager::setPass(ShaderPass pass)
{
	this->pass = pass;
}

bool ShaderVariableManager::parseFile(const std::string &input, std::string &output)
{
	auto var_tag = getVarTag();
	auto [code_blocks, variable_blocks] = splitString(input, var_tag, ")");

	output.clear();
	output.reserve(input.size());
	for (auto code_iter = code_blocks.begin(), variable_iter = variable_blocks.begin(); variable_iter != variable_blocks.end(); ++code_iter, ++variable_iter)
	{
		// extract the name
		auto bracket_begin = variable_iter->find("(");
		auto bracket_end = variable_iter->find(")");

		auto var_name = variable_iter->substr(0, bracket_begin);
		auto var_name_short = variable_iter->substr(var_tag.size(), bracket_begin - var_tag.size());
		auto param_string = variable_iter->substr(bracket_begin + 1, bracket_end - bracket_begin - 1);

		if (pass == ShaderPass::CombinedPass || pass == ShaderPass::GeneratePass)
		{
			output += *code_iter;
			output += var_name;
		}
		else
		{
			// just create a dummy variable
			output += *code_iter;
			output += "0.f";
		}

		if (pass == ShaderPass::CombinedPass || pass == ShaderPass::CollectPass)
		{

			// build the param map
			auto [params, _] = splitString(param_string, ",");
			std::map<std::string, float> param_map;
			for (const auto &param : params)
			{
				auto [parts, separators] = splitString(param, "=");
				if (parts.size() != 2)
				{
					if (separators.size() == 1)
					{
						return false;
					}
					break;
				}

				auto name_str = removeSpaces(parts[0]);
				auto val_str = removeSpaces(parts[1]);
				param_map[std::string(name_str)] = std::stof(std::string(val_str));
			}

			// add the variable
			Variable var;
			auto iter = param_map.find("min");
			var.minval = iter != param_map.end() ? iter->second : 0.f;
			iter = param_map.find("max");
			var.maxval = iter != param_map.end() ? iter->second : 2.f;
			iter = param_map.find("start");
			var.start = iter != param_map.end() ? iter->second : (var.maxval + var.minval) * 0.5f;
			iter = param_map.find("step");
			var.step = iter != param_map.end() ? iter->second : (var.maxval - var.minval) * 0.05f;
			var.value = var.start;

			variables[std::string(var_name_short)] = var;
		}
	}
	output += code_blocks.back();
	return true;
}

std::string ShaderVariableManager::generateHeader() const
{
	if (variables.empty() || pass == ShaderPass::CollectPass)
	{
		return {};
	}

	Format formatter;
	formatter <<
		"#ifndef USER_VARIABLES_HLSL\n"
		"#define USER_VARIABLES_HLSL\n"
		"cbuffer user_variables : register(b" << slot << ")\n"
		"{\n"
		"	float ";
	for (bool comma = false; auto &[name, var] : variables)
	{
		if (comma)
		{
			formatter << ", ";
		}
		formatter << getVarTag() << name;
		comma = true;
	}
	formatter << ";\n";
	formatter <<
		"};\n"
		"#endif\n";

	return formatter;
}

bool ShaderVariableManager::hasVariables() const
{
	return !variables.empty();
}

VariableMap &ShaderVariableManager::getVariables()
{
	return variables;
}

void ShaderVariableManager::setValue(std::string_view name, float val)
{
	if (auto iter = variables.find(name); iter != variables.end())
	{
		iter->second.value = val;
	}	
}

bool ShaderVariableManager::createConstantBuffer(ID3D11Device *dev)
{
	size_t byte_size = sizeof(float) * static_cast<unsigned>(variables.size());
	D3D11_BUFFER_DESC cbuffer_desc = { 0 };
	cbuffer_desc.ByteWidth = (byte_size + 15) & ~15;
	cbuffer_desc.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
	cbuffer_desc.Usage = D3D11_USAGE_DYNAMIC;
	cbuffer_desc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
	HRESULT hr = dev->CreateBuffer(&cbuffer_desc, nullptr, &cbuffer);
	if (FAILED(hr))
		return false;

	return true;
}

void ShaderVariableManager::updateBuffer(ID3D11DeviceContext *ctx)
{
	D3D11_MAPPED_SUBRESOURCE res;
	ctx->Map(cbuffer, 0, D3D11_MAP_WRITE_DISCARD, 0, &res);
	float *ptr = static_cast<float *>(res.pData);
	for (const auto &[name, var] : variables)
	{
		*ptr++ = var.value;
	}
	ctx->Unmap(cbuffer, 0);
}

ID3D11Buffer *ShaderVariableManager::getBuffer()
{
	return cbuffer;
}

std::string_view ShaderVariableManager::getVarTag()
{
	return "VAR_";
}

Comptr<ID3DBlob> compileShader(ShaderIncluder &includer, const std::string &filename, const std::string &profile, const std::string &entry, bool display_warnings, bool disassemble)
{
	Comptr<ID3DBlob> compiled, error;
	if (includer.hasVarManager()) // go for 2 pass mode
	{
		includer.setPass(ShaderPass::CollectPass);
		bool file_ok = compileShaderPass(includer, filename, profile, entry, D3DCOMPILE_OPTIMIZATION_LEVEL0, compiled, error);
		if (!file_ok)
		{
			return {}; // if the initial file loading fails, nothing else to do
		}

		if (!compiled) // we need code to proceed here, so this is an error and we abort
		{
			if (error)
			{
				ErrorBox(static_cast<const char *>(error->GetBufferPointer()));
			}
			return {};
		}

		// reset the buffer
		compiled = nullptr;
		error = nullptr;

		// setup the next pass
		includer.setPass(ShaderPass::GeneratePass);
	}
	else // single pass
	{
		includer.setPass(ShaderPass::CombinedPass);
	}

	bool file_ok = compileShaderPass(includer, filename, profile, entry, D3DCOMPILE_OPTIMIZATION_LEVEL3, compiled, error);
	if (!file_ok)
	{
		return {}; // if the initial file loading fails, nothing else to do
	}

	if (error)
	{
		if (!compiled) // no code, thus an error
		{
			ErrorBox(static_cast<const char *>(error->GetBufferPointer()));
		}
		else if (display_warnings) // its a warning, since we got the code
		{
			WarningBox(static_cast<const char *>(error->GetBufferPointer()));
		}
	}

	// remove headers again
	includer.setExtraHeaders({});

	if (disassemble && compiled)
	{
		UINT disasm_flags = 0;
		Comptr<ID3DBlob> disassembled;
		D3DDisassemble(compiled->GetBufferPointer(), compiled->GetBufferSize(), disasm_flags, nullptr, &disassembled);
		if (disassembled)
		{
			std::string output_filename = changeFileExtension(filename, "asm");
			std::ofstream out_file(output_filename, std::ios::out);
			out_file.write(static_cast<const char *>(disassembled->GetBufferPointer()), disassembled->GetBufferSize() - 1);
		}
	}

	return compiled;
}

bool compileShaderPass(ShaderIncluder &includer, const std::string &filename, const std::string &profile, const std::string &entry, unsigned extra_flags, Comptr<ID3DBlob> &compiled, Comptr<ID3DBlob> &error)
{
	std::string code;
	// first load the file
	if (!includer.loadFromFile(filename, code))
	{
		ErrorBox(Format() << "Could not load file \"" << filename << "\"");
		return false;
	}

	// then try to compile it
	UINT flags =
#ifdef _DEBUG
		D3DCOMPILE_DEBUG |
#endif
		extra_flags;

	D3DCompile(code.c_str(), code.length(), filename.c_str(), nullptr, &includer, entry.c_str(), profile.c_str(), flags, 0, &compiled, &error);
	return true;
}
