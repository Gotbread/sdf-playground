#include "ShaderUtil.h"
#include "Util.h"

#include <fstream>
#include <d3dcompiler.h>


void ShaderIncluder::setFolder(const std::string &folder)
{
	this->folder = folder;
}

void ShaderIncluder::setSubstitutions(std::vector<ShaderIncluder::Substitution> substitutions)
{
	this->substitutions.swap(substitutions);
}

HRESULT STDMETHODCALLTYPE ShaderIncluder::Open(D3D_INCLUDE_TYPE IncludeType, LPCSTR pFileName, LPCVOID pParentData, LPCVOID *ppData, UINT *pBytes)
{
	std::string code;
	if (!loadFromFile(pFileName, code))
	{
		return D3D11_ERROR_FILE_NOT_FOUND; // let D3D deal with the error
	}

	UINT size = code.size();
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
	const std::string *final_filename = &filename;
	for (auto &sub : substitutions)
	{
		if (sub.first == filename)
		{
			final_filename = &sub.second;
			break;
		}
	}

	std::ifstream file(folder / *final_filename);
	if (!file)
	{
		return false;
	}

	code = readFromFile(file);
	return true;
}


Comptr<ID3DBlob> compileShader(ShaderIncluder &includer, const std::string &filename, const std::string &profile, const std::string &entry, bool display_warnings, bool disassemble)
{
	std::string code;
	// first load the file
	if (!includer.loadFromFile(filename, code))
	{
		ErrorBox(Format() << "Could not load file \"" << filename << "\"");
	}

	// then try to compile it
	UINT flags =
#ifdef _DEBUG
		D3DCOMPILE_DEBUG |
#endif
		0;

	Comptr<ID3DBlob> compiled, error;
	D3DCompile(code.c_str(), code.length(), filename.c_str(), nullptr, &includer, entry.c_str(), profile.c_str(), flags, 0, &compiled, &error);
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