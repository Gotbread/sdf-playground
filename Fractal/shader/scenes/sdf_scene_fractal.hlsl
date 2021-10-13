#include "sdf_primitive.hlsl"


// changes the entries around so x is biggest, then y, then z

float3 sort_components(float3 vec)
{
	if (vec.z > vec.y)
		vec.yz = vec.zy;
	if (vec.y > vec.x)
		vec.xy = vec.yx;
	if (vec.z > vec.y)
		vec.yz = vec.zy;
	return vec;
}

// params:
// pos.xyz: 3D position in the scene
// pos.w: one when rendering with transparent objects, zero without
// 
// dir: input normal. normalized to 1 for normal passes, zero for gradient-only passes
// 
// return value:
// x: scene distance
// y: material ID
//
// material_property:
// extra vector, meaning depends on material
float2 map(float4 pos, float3 dir, out float3 material_property)
{
	float size = 1.f;
	float3 fractal_pos = pos.xyz - float3(0.f, 1.f, 0.f);
	float g = 0.7f;

	float d = 1e30;
	float scale = 1.f;
	float iters_needed = 0.f;

	for (int i = 0; i < 8; ++i)
	{
		float new_d = sdBox(fractal_pos, size * 0.5f) / scale;
		if (new_d < 0.0001f && d > 0.0001f)
		{
			iters_needed = (float)i;
		}
		d = min(d, new_d);

		// all 6 sides
		fractal_pos = abs(fractal_pos);
		fractal_pos.yxz = sort_components(fractal_pos.yxz);

		// move up
		fractal_pos.y -= size * 2.f / 3.f;

		// face block 1
		fractal_pos.y += size / 3.f;
		fractal_pos.yxz = sort_components(fractal_pos.yxz);
		fractal_pos.y -= size / 3.f;


		// recursion
		fractal_pos *= 3.f;
		scale *= 3.f;
	}

	float obj = d;

	// floor
	float floor1 = sdPlaneFast(pos.xyz, dir, float3(0.f, 1.f, 0.f));

	// select
	if (obj < floor1)
	{
		material_property = float3(0.9f, g, iters_needed * 0.125f);
		return float2(obj, 3.f);
	}
	else
	{
		float2 tile_pos = floor(pos.xz);
		float tile_parity = round(frac((tile_pos.x + tile_pos.y) * 0.5f + 0.25f));
		material_property = tile_parity > 0.5f ? float3(0.1f, 0.1f, 0.1f) : float3(0.8f, 0.8f, 0.8f);
		return float2(floor1, 3.f);
	}
}