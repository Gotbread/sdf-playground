#include "sdf_primitive.hlsl"


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
	float3 sphere_pos = abs(pos.xyz);
	float obj = sdSphere(sphere_pos - float3(0.65f, 1.f, 0.65f), 0.5f);

	// floor
	float floor1 = sdPlaneFast(pos.xyz, dir, float3(0.f, 1.f, 0.f));

	// select
	if (obj < floor1)
	{
		material_property = float3(0.9f, 0.7f, 0.2f);
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