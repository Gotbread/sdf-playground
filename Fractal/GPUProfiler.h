#pragma once

#include <string>
#include <vector>
#include <map>
#include <d3d11.h>

#include "Comptr.h"

// Profiles drawcalls
//
// how to use:
// - fetchResults from the last frame
// - if okay, call getResults
// - process the results somehow
// - start a new frame, call beginFrame
// - for everything you want to profile, call profile with the name of that thing
// - when you are done with the frame, call endFrame
// - call swapSets
class GPUProfiler
{
public:
	GPUProfiler();
	void setGPU(ID3D11Device *dev, ID3D11DeviceContext *ctx);
	// must set valid GPU interfaces before calling beginFrame
	void beginFrame();
	// must call beginFrame before endFrame
	void endFrame();
	// call only between beginFrame and endFrame
	void profile(const std::string &name);
	
	// true if done
	bool fetchResults();
	std::map<std::string, float> getResults();
private:
	enum QueryState
	{
		Ready, // the queries are ready to be used
		Fetching, // GPU is still busy
		Finished, // results are ready to be collected
	};
	struct NamedQuery
	{
		std::string name;
		Comptr<ID3D11Query> query;
	};

	void ensureQueryExists(const std::string *name);
	std::vector<NamedQuery>::iterator getQueryByName(const std::string &name);
	
	struct QuerySet
	{
		// holds the disjoint query and the reference query respectively
		Comptr<ID3D11Query> query_frame, query_begin, query_end;
		std::vector<NamedQuery> queries;
		// the last query that was queried, or -1
		int last_query_index = -1;
		QueryState state = Ready;
	} sets[2]; // double buffered, one active, one polling
	QuerySet *active, *inactive; // pointers for easier access

	ID3D11Device *dev;
	ID3D11DeviceContext *ctx;
};
