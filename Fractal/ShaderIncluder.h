#pragma once

#include <d3dcommon.h>
#include <string>
#include <vector>
#include <filesystem>

class ShaderIncluder : public ID3DInclude
{
public:
	using Substitution = std::pair<std::string, std::string>;

	void setFolder(const std::string &folder);
	void setSubstitutions(std::vector<Substitution> substitutions);

	HRESULT STDMETHODCALLTYPE Open(D3D_INCLUDE_TYPE IncludeType, LPCSTR pFileName, LPCVOID pParentData, LPCVOID *ppData, UINT *pBytes);
	HRESULT STDMETHODCALLTYPE Close(LPCVOID pData);

	// in this class so we bundle all the file handling at one place
	bool loadFromFile(const std::string &filename, std::string &code);
private:
	std::filesystem::path folder;
	std::vector<Substitution> substitutions;
};
