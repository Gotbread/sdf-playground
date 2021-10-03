#include "sdf_primitive.hlsl"


// use the debug plane?
static const bool use_debug_plane = false;

// return value:
// x: scene distance
// y: material ID
//
// material_property:
// extra vector, meaning depends on material
float2 map(float3 pos, float3 dir, out float3 material_property)
{
	float3 new_pos = opRepLim(pos, float3(10.f, 10.f, 10.f), float3(1.5f, 1.5f, 1.5f));
	float3 instance_id_vec = pos - new_pos;
	float instance_id = dot(instance_id_vec, float3(5.f, 2.f, 1.f));
	material_property = float3(0.1f, 0.7f, 0.2f);
	float angle = staircase(stime + instance_id, 2 * 3.1415926f, 20.f);

	float box = sdBox(new_pos, float3(0.8f, 0.8f, 0.8f));
	new_pos.xz = opRotate(new_pos.xz, angle);
	float d = sdTorusXY(new_pos, 0.35f, 0.1f);
	d = min(d, -box);
	return float2(d, 3.f);
}