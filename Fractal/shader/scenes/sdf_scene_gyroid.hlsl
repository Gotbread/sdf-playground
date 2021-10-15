#include "sdf_primitives.hlsl"


float sdGyroid(float3 p)
{
	return dot(sin(p.xyz), cos(p.zxy));
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
	float gyroid = sdGyroid(pos.xyz * 7.f) / 14.f;
	gyroid = abs(gyroid) - 0.01f;
	float box = sdBox(pos.xyz, float3(1.f, 1.f, 1.f));
	float obj = max(gyroid, box);

	material_property = float3(0.9f, 0.7f, 0.2f);
	return float2(obj, 3.f);
}