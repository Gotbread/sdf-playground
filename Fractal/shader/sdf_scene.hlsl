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
	float d_table = min(legs, plate);

	float vase1 = sdSphere(p - float3(0.f, leg_height + 0.15f, 0.f), 0.2f);
	float vase2 = sdSphere(p - float3(0.f, leg_height + 0.45f, 0.f), 0.17f);
	float vase3 = sdSphere(p - float3(0.f, leg_height + 0.72f, 0.f), 0.15f);
	float vase_cut1 = sdPlane(p - float3(0.f, leg_height + 0.615f, 0.f), float3(0.f, 1.f, 0.f));
	float vase_cut2 = sdPlane(p - float3(0.f, leg_height + 0.1f, 0.f), float3(0.f, -1.f, 0.f));
	float vase_body = max(smin(smin(vase1, vase2, 0.05f), vase3, 0.025f), vase_cut2);
	float d_vase = max(max(vase_body, vase_cut1), -vase_body - 0.01f);

	if (d_table < d_vase)
	{
		if (legs < plate)
		{
			material_property = p.xzy;
		}
		else
		{
			float step = floor((p.x + 1.25f) * 4.f) / 8.f;
			material_property = p + float3(p.z * 0.2f, step, 0.f);
		}
		return float2(d_table, 4.f);
	}
	else
	{
		material_property = p * 4.f;
		return float2(d_vase, 3.f);
	}
}