#include "sdf_primitive.hlsl"


static const float leg_width = 0.05f;
static const float leg_height = 0.7f;
static const float leg_distance = 1.f;
static const float plate_size = 1.2f;
static const float plate_height = 0.0175f;

// return value:
// x: scene distance
// y: material ID
//
// material_property:
// extra vector, meaning depends on material
float2 map(float3 p, float3 dir, out float3 material_property)
{
	float3 abspos = abs(p);
	float legs = sdBox(abspos - float3(leg_distance, leg_height * 0.5f, leg_distance), float3(leg_width, leg_height * 0.5f, leg_width));
	float plate = sdBox(p - float3(0.f, leg_height + 0.025f, 0.f), float3(plate_size, plate_height, plate_size)) - 0.025f;
	float d = min(legs, plate);

	if (legs < plate)
	{
		material_property = p.xzy;
	}
	else
	{
		float step = floor((p.x + 1.25f) * 4.f) / 8.f;
		material_property = p + float3(p.z * 0.2f, step, 0.f);
	}
	return float2(d, 4.f);
}