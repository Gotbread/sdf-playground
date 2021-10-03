#include "sdf_primitive.hlsl"


// currently not in use
//float sierpinski(float3 p, uint depth)
//{
//	float3 a1 = float3(+1.f, +1.f, +1.f);
//	float3 a2 = float3(-1.f, -1.f, +1.f);
//	float3 a3 = float3(+1.f, -1.f, -1.f);
//	float3 a4 = float3(-1.f, +1.f, -1.f);
//	float scale = 2.f;
//	for (uint iter = 0; iter < depth; ++iter)
//	{
//		float3 c = a1;
//		float dist = length(p - a1);
//		float d = length(p - a2);
//		if (d < dist)
//		{
//			c = a2;
//			dist = d;
//		}
//		d = length(p - a3);
//		if (d < dist)
//		{
//			c = a3;
//			dist = d;
//		}
//		d = length(p - a4);
//		if (d < dist)
//		{
//			c = a4;
//			dist = d;
//		}
//		p = scale * p - c * (scale - 1.f);
//	}
//	return length(p) / pow(scale, depth) - 2 * dist_eps;
//}

float vase(float3 pos)
{
	float obj1 = sdSphere(pos - float3(0.f, 1.89f, 0.f), 0.5f);
	float obj2 = sdCappedCylinder(pos - float3(0.f, 0.8f, 0.f), 0.75f, 0.2f);
	float obj3 = sdBox(pos - float3(0.f, 0.075f, 0.f), float3(0.4f, 0.075f, 0.4f));
	float cut_plane1 = sdPlane(pos - float3(0.f, 1.9f, 0.f), float3(0.f, 1.f, 0.f));
	float cut_plane2 = sdPlane(pos - float3(0.f, 1.5f, 0.f), float3(0.f, -1.f, 0.f));

	float d = max(obj1, cut_plane2);
	d = opPipeMerge(d, obj2, 0.1f, 4.f);
	d = opPipeMerge(d, obj3, 0.1f, 4.f);
	d = max(d, cut_plane1);
	d = max(d, -obj1 - 0.06f);
	return d;
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
	// wall
	/*float3 wall_pos = pos;
	wall_pos.xz = opRepInf(wall_pos.xz, float2(20.f, 20.f));
	wall_pos.xz = abs(wall_pos.xz);
	if (wall_pos.z > wall_pos.x)
	{
		wall_pos.xz = wall_pos.zx;
	}

	float wall1 = sdBox(wall_pos - float3(3.5f, 2.f, 3.f), float3(1.5f, 2.f, 1.f));
	float wall2 = sdBox(wall_pos - float3(7.f, 2.f, 5.f), float3(3.f, 2.f, 1.f));
	float wall = min(wall1, wall2);

	// object
	float3 obj_pos = wall_pos;
	obj_pos.x -= 8.f;
	obj_pos.x = abs(obj_pos.x);
	float obj1 = vase(obj_pos - float3(1.f, 0.f, 3.f));

	// floor
	float floor1 = sdPlane(pos, float3(0.f, 1.f, 0.f));

	// select
	if (obj1 < wall && obj1 < floor1)
	{
		material_property = pos * 3.f;
		return float2(obj1, 4.f);
	}
	else if (wall < floor1)
	{
		material_property = pos;
		return float2(wall, 5.f);
	}
	else
	{
		float2 tile_pos = floor(pos.xz);
		float tile_parity = round(frac((tile_pos.x + tile_pos.y) * 0.5f + 0.25f));
		material_property = tile_parity > 0.5f ? float3(0.1f, 0.1f, 0.1f) : float3(0.8f, 0.8f, 0.8f);
		return float2(floor1, 3.f);
	}*/


	// testing
	float wood = sdBox(pos.xyz - float3(0.f, 0.6f, 0.f), float3(0.05f, 0.5f, 0.05f));
	float fire = sdRoundCone(pos.xyz, float3(0.f, 1.1f, 0.f), float3(0.f, 1.6f, 0.f), 0.15f, 0.1f);

	// floor
	float floor1 = sdPlaneFast(pos.xyz, dir, float3(0.f, 1.f, 0.f));

	// select
	if (pos.w > 0.5f && fire < wood && fire < floor1)
	{
		material_property = pos.xyz * 3.f - float3(0.f, stime * 3.f, 0.f);
		return float2(fire, 100.f);
	}
	else if (wood < floor1)
	{
		material_property = pos.xzy * 2.f;
		return float2(wood, 6.f);
	}
	else
	{
		float2 tile_pos = floor(pos.xz);
		float tile_parity = round(frac((tile_pos.x + tile_pos.y) * 0.5f + 0.25f));
		material_property = tile_parity > 0.5f ? float3(0.1f, 0.1f, 0.1f) : float3(0.8f, 0.8f, 0.8f);
		return float2(floor1, 3.f);
	}
}