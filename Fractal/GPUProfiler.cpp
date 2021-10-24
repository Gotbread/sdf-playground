#include "GPUProfiler.h"

#include <algorithm>
#include <ranges>

GPUProfiler::GPUProfiler() : dev(nullptr), ctx(nullptr)
{
	// set up both pointers
	active = &sets[0];
	inactive = &sets[1];
}

void GPUProfiler::setGPU(ID3D11Device *dev, ID3D11DeviceContext *ctx)
{
	this->dev = dev;
	this->ctx = ctx;
}

void GPUProfiler::beginFrame()
{
	ensureQueryExists(nullptr);
	
	// only if we are ready
	if (active->state == QueryState::Ready)
	{
		ctx->Begin(active->query_frame);
		ctx->End(active->query_begin);

		active->last_query_index = -1;
	}
}

void GPUProfiler::endFrame()
{
	if (active->state == QueryState::Ready)
	{
		ctx->End(active->query_end);
		ctx->End(active->query_frame);

		// set this state to busy
		active->state = QueryState::Fetching;
		// next set
		std::swap(active, inactive);
	}
}

void GPUProfiler::profile(const std::string &name)
{
	ensureQueryExists(&name);
	if (active->state == QueryState::Ready)
	{
		auto iter = getQueryByName(name);
		ctx->End(iter->query);
		// move the query to the next slot
		std::swap(*iter, active->queries[++active->last_query_index]);
	}
}

bool GPUProfiler::fetchResults()
{
	// try to read the data from the inactive set
	if (active->state == QueryState::Fetching)
	{
		ID3D11Query *fixed_queries[] =
		{
			active->query_frame,
			active->query_begin,
			active->query_end,
		};
		for (auto &query : fixed_queries)
		{
			HRESULT hr = ctx->GetData(query, nullptr, 0, 0);
			if (hr == S_FALSE)
			{
				return false;
			}
		}
		for (auto &query : active->queries)
		{
			HRESULT hr = ctx->GetData(query.query, nullptr, 0, 0);
			if (hr == S_FALSE)
			{
				return false;
			}
		}
		// everyone okay
		active->state = QueryState::Finished;
		return true;
	}
	return false;
}

std::map<std::string, float> GPUProfiler::getResults()
{
	if (active->state == QueryState::Finished)
	{
		active->state = QueryState::Ready;

		D3D11_QUERY_DATA_TIMESTAMP_DISJOINT disjoint;
		ctx->GetData(active->query_frame, &disjoint, sizeof(disjoint), 0);
		if (!disjoint.Disjoint) // cant use the frequency, no results
		{
			UINT64 frame_begin, frame_end;
			ctx->GetData(active->query_begin, &frame_begin, sizeof(frame_begin), 0);
			ctx->GetData(active->query_end, &frame_end, sizeof(frame_end), 0);

			std::map<std::string, float> results;
			// collect all user queries
			UINT64 last_time = frame_begin;
			for (auto &query : active->queries)
			{
				UINT64 time;
				ctx->GetData(query.query, &time, sizeof(time), 0);
				results[query.name] = static_cast<float>(time - last_time) / disjoint.Frequency;
				last_time = time;
			}
			// add frame query
			results[{}] = static_cast<float>(frame_end - frame_begin) / disjoint.Frequency;
			return results;
		}
	}
	return {};
}

void GPUProfiler::ensureQueryExists(const std::string *name)
{
	if (name) // a named one
	{
		if (auto iter = getQueryByName(*name); iter == active->queries.end())
		{
			// create a new one
			D3D11_QUERY_DESC desc{};
			desc.Query = D3D11_QUERY_TIMESTAMP;
			Comptr<ID3D11Query> query;
			dev->CreateQuery(&desc, &query);

			active->queries.emplace_back(*name, query);
		}
	}
	else // the mandatory ones
	{
		if (!active->query_frame)
		{
			D3D11_QUERY_DESC desc{};
			desc.Query = D3D11_QUERY_TIMESTAMP_DISJOINT; // the disjoint query
			dev->CreateQuery(&desc, &active->query_frame);
		}

		if (!active->query_begin)
		{
			D3D11_QUERY_DESC desc{};
			desc.Query = D3D11_QUERY_TIMESTAMP; // the timestamp query
			dev->CreateQuery(&desc, &active->query_begin);
		}

		if (!active->query_end)
		{
			D3D11_QUERY_DESC desc{};
			desc.Query = D3D11_QUERY_TIMESTAMP; // the timestamp query
			dev->CreateQuery(&desc, &active->query_end);
		}
	}
}

std::vector<GPUProfiler::NamedQuery>::iterator GPUProfiler::getQueryByName(const std::string &name)
{
	return std::ranges::find_if(active->queries, [&name](auto &entry)
	{
		return entry.name == name;
	});
}
