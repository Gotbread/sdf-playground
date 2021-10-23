#ifndef SDF_MATERIALS_HLSL
#define SDF_MATERIALS_HLSL

#include "noise.hlsl"

float3 marble(float3 pos, float3 marble_color)
{
	float3 marble_dir = float3(3.f, 2.f, 1.f);
	float wave_pos = dot(marble_dir, pos) * 2.f + turbulence(pos) * 5.f;
	float sine_val = (1.f + sin(wave_pos)) * 0.5f;
	sine_val = pow(sine_val, 0.5f);
	return marble_color * sine_val;
}

float3 wood(float3 pos)
{
	static const float turbulence_scale = 0.125f;
	static const float rings = 12.f;

	float dist = sqrt(pos.x * pos.x + pos.y * pos.y) + turbulence_scale * turbulence(pos);
	float sine_val = 0.5f * abs(sin(2 * rings * dist * 3.14159));

	return float3(0.3125f + sine_val, 0.117f + sine_val, 0.117f);
}

float3 fire(float3 pos, float threshold)
{
	float turb = turbulence(pos) + 0.35f;
	turb = turb > threshold ? turb : 0.f;
	return float3(5.f, 2.f, 1.f) * turb;
}

float2 voronoi_cell_offset(float2 cell_index)
{
	float x = hashf((int)(cell_index.x + cell_index.y * 217.743f));
	float y = hashf((int)(cell_index.x + cell_index.y * 217.743f + 2475.235f));
	return float2(x, y) * 2.f - 1.f;
}

// max_offset: from 0 to 1, how far to move from the center
// return:
// xy: the cell id as integer
// z: distance to the center
// w: distance to the closest edge
float4 voronoi(float2 uv, float max_offset)
{
	float2 cell_index = floor(uv);
	float2 cell_pos = (uv - cell_index) - 0.5f;

	float2 local_point = voronoi_cell_offset(cell_index);
	float l_center_min = 10.f;
	float l_edge_min = 10.f;
	float2 closest_cell_id;
	float2 closest_cell;
	for (int x = -1; x < 2; ++x)
	{
		for (int y = -1; y < 2; ++y)
		{
			float2 offset = float2(x, y);
			float2 cell_id = cell_index + offset;
			float2 point_pos = offset + voronoi_cell_offset(cell_id) * max_offset;
			float2 center_vec = point_pos - cell_pos;

			float l_center = length(center_vec);
			if (l_center < l_center_min)
			{
				l_center_min = l_center;
				closest_cell_id = cell_id;
				closest_cell = point_pos;
			}
		}
	}
	{
		for (int x = -1; x < 2; ++x)
		{
			for (int y = -1; y < 2; ++y)
			{
				float2 offset = float2(x, y);
				float2 cell_id = cell_index + offset;
				float2 point_pos = offset + voronoi_cell_offset(cell_id) * max_offset;
				float2 center_vec = point_pos - cell_pos;

				float2 border_vec = (point_pos + closest_cell) * 0.5f;
				float edge_dist = abs(dot(normalize(closest_cell - border_vec), cell_pos - border_vec));
				l_edge_min = min(edge_dist, l_edge_min);

			}
		}
	}

	return float4(closest_cell_id, l_center_min, l_edge_min);
}

// chance: how often a tile flips, from 0 to 1
// width: how thick the line should be, measured from the center of a cell. 0 to 0.2 are reasonable
// miss_uv: what to return when we are not on the line
float4 truchet_band(float2 uv, float chance, float width, float2 miss_uv)
{
	float2 cell_index = floor(uv);
	float2 cell_pos = (uv - cell_index) - 0.5f;

	float flip3 = step(frac((cell_index.x + cell_index.y) * 0.5f + 0.25f), 0.5f) * 2.f - 1.f;
	float flip2 = step(hashf((int)(cell_index.x + cell_index.y * 217.743f)), chance) * 2.f - 1.f;
	cell_pos.y *= flip2;
	float flip1 = step(cell_pos.y, cell_pos.x) * 2.f - 1.f;
	cell_pos *= flip1;
	cell_pos += float2(-0.5f, 0.5f);
	float len = length(cell_pos);

	if (abs(len - 0.5) < width)
	{
		float a = (len - 0.5f + width) / (2.f * width);
		float b = atan2(cell_pos.y, -cell_pos.x) / (3.1415926 * 0.5f);
		a = lerp(1.f - a, a, flip2 * flip3 * 0.5f + 0.5f);
		b = lerp(1.f - b, b, flip3 * 0.5f + 0.5f);
		return float4(cell_index, a, b);
	}
	return float4(cell_index, miss_uv);
}

// width: how wide a braid is, from 0 to 0.5
// run_length: how long the band period is
// run_flip: how many of these are flipped
// miss_uv: what to return when we are not on the braid
float4 braid(float2 uv, float width, float run_length, float run_flip, float2 miss_uv)
{
	float2 cell_index = floor(uv);
	float2 cell_pos = (uv - cell_index) - 0.5f;

	float t = frac((cell_index.x + cell_index.y) / run_length) * run_length + 0.5f;
	float flip = step(t, run_flip);

	cell_pos.xy = lerp(cell_pos.xy, cell_pos.yx, flip);
	float2 rel_pos = abs(cell_pos) / width;
	float2 overflow = step(1.f, rel_pos);
	cell_pos.xy = lerp(cell_pos.xy, cell_pos.yx, overflow.x);
	cell_pos.xy = lerp(cell_pos.xy, miss_uv, overflow.x * overflow.y);

	return float4(cell_index, cell_pos);
}

float3 debug_plane_color(float scene_distance)
{
	float int_steps;
	float frac_steps = abs(modf(scene_distance, int_steps)) * 1.2f;
	float band_steps = modf(int_steps / 5.f, int_steps);

	float3 band_color = band_steps > 0.7f ? float3(1.f, 0.25f, 0.25f) : float3(0.75f, 0.75f, 1.f);
	frac_steps = scene_distance < 5.f ? frac_steps : 0.5f;
	float3 col = frac_steps < 1.f ? frac_steps * frac_steps * float3(1.f, 1.f, 1.f) : band_color;
	col.g = scene_distance < 0.f ? (scene_distance > -0.01f ? 1.f : 0.f) : col.g;
	return col;
}

float3 iter_count_to_color(uint iter_count, uint max_iter_count)
{
	float rel_iter_count = ((float)iter_count) / max_iter_count;
	float3 col1 = float3(0.f, 0.f, 0.f);
	float3 col2 = float3(0.f, 0.f, 1.f);
	float3 col3 = float3(0.f, 1.f, 0.f);
	float3 col4 = float3(1.f, 1.f, 0.f);
	float3 col5 = float3(1.f, 0.f, 0.f);

	if (rel_iter_count < 0.1f)
	{
		return lerp(col1, col2, rel_iter_count / 0.1f);
	}
	else if (rel_iter_count < 0.5f)
	{
		return lerp(col2, col3, (rel_iter_count - 0.1f) / 0.4f);
	}
	else if (rel_iter_count < 0.9f)
	{
		return lerp(col3, col4, (rel_iter_count - 0.5f) / 0.4f);
	}
	else
	{
		return lerp(col4, col5, (rel_iter_count - 0.9f) / 0.1f);
	}
}

#endif
