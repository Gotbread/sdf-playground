#include "sdf_primitives.hlsl"
#include "user_variables.hlsl"

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
	float size = VAR_size(min = 0.2, max = 2, start = 1, step = 0.2);
	float x = VAR_xpos(min = -2, max = 2, start = 0, step = 0.1);
	float y = VAR_ypos(min = -2, max = 2, start = 0, step = 0.1);
	float z = VAR_zpos(min = -2, max = 2, start = 0, step = 0.1);

	float obj = sdBox(pos.xyz - float3(0.f, 1.f, 0.f) - float3(x, y, z), size);

	// floor
	float floor1 = sdPlaneFast(pos.xyz, dir, float3(0.f, 1.f, 0.f));

	// select
	if (obj < floor1)
	{
		float r = VAR_red(min = 0, max = 1, start = 0.9, step = 0.05);
		float g = VAR_green(min = 0, max = 1, start = 0.7, step = 0.05);
		float b = VAR_blue(min = 0, max = 1, start = 0.2, step = 0.05);
		material_property = float3(r, g, b);
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