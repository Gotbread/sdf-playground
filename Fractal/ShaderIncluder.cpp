#include "ShaderIncluder.h"
#include "Util.h"

#include <fstream>


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
