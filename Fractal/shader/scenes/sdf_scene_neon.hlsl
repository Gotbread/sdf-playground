#include "sdf_primitives.hlsl"
#include "sdf_ops.hlsl"
#include "user_variables.hlsl"

float sdRingsphere(float3 pos, float spacing, float r1, float r2)
{
	float3 hit_point = normalize(pos) * r1;
	float y = hit_point.y;
	float x = length(hit_point.xz);
	float angle = atan2(y, x);
	angle = round(angle / spacing) * spacing;
	hit_point.y = tan(angle) * x;
	hit_point = normalize(hit_point) * r1;

	return length(pos - hit_point) - r2;
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
	float r1 = VAR_r1(min = 0.2, max = 2, start = 1);
	float r2 = VAR_r2(min = 0.005, max = 0.1, start = 0.01);
	float spacing = VAR_spacing(min = 0.01, max = 0.2, start = 0.1);

	float obj = sdRingsphere(pos.xyz - float3(0.f, 2.f, 0.f), spacing, r1, r2);

	float3 mirror_pos = pos.xyz - float3(0.f, 2.f, 2.75f);
	mirror_pos.xz = opRotate(mirror_pos.xz, 0.3f);
	float mirror = sdBox(mirror_pos, float3(1.f, 1.7f, 0.05f));
	float mirror_border = sdBox(mirror_pos, float3(1.05f, 1.75f, 0.04f));

	// floor
	float floor1 = sdPlaneFast(pos.xyz, dir, float3(0.f, 1.f, 0.f));

	// select
	if (mirror_border < mirror && mirror_border < obj && mirror_border < floor1)
	{
		material_property = float3(0.5f, 0.5f, 0.5f);
		return float2(mirror_border, 3.f);
	}
	else if (mirror < obj && mirror < floor1)
	{
		material_property = float3(0.8f, 0.8f, 0.8f);
		return float2(mirror, 50.f);
	}
	else if (obj < floor1)
	{
		float r = VAR_red(min = 0, max = 1, start = 0.1, step = 0.05);
		float g = VAR_green(min = 0, max = 3, start = 1.0, step = 0.05);
		float b = VAR_blue(min = 0, max = 1, start = 0.2, step = 0.05);
		material_property = float3(r, g, b);
		return float2(obj, 3.f);
	}
	else
	{
		float2 tile_pos = floor(pos.xz);
		float2 tile_local_pos = 0.5f - abs(pos.xz - tile_pos - 0.5f);
		float tile_parity = round(frac((tile_pos.x + tile_pos.y) * 0.5f + 0.25f));
		material_property = tile_parity > 0.5f ? float3(0.1f, 0.1f, 0.1f) : float3(0.8f, 0.8f, 0.8f);
		if (tile_local_pos.x < 0.0125f || tile_local_pos.y < 0.0125f)
			material_property = float3(0.45f, 0.45f, 0.45f);

		return float2(floor1, 3.f);
	}
}