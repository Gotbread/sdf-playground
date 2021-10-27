#include "sdf_primitives.hlsl"
#include "sdf_ops.hlsl"
#include "sdf_common.hlsl"

static const float leg_width = 0.05f;
static const float leg_height = 0.7f;
static const float leg_distance = 1.f;
static const float plate_size = 1.2f;
static const float plate_height = 0.0175f;

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
	map_groundplane(geometry, material_output, geometry_step, output_scene_distance);

	float3 p = geometry.pos;
	p.y -= 0.4f;
	float3 abspos = abs(p);
	float legs = sdBox(abspos - float3(leg_distance, leg_height * 0.5f, leg_distance), float3(leg_width, leg_height * 0.5f, leg_width));
	float plate = sdBox(p - float3(0.f, leg_height + 0.025f, 0.f), float3(plate_size, plate_height, plate_size)) - 0.025f;

	float vase1 = sdSphere(p - float3(0.f, leg_height + 0.15f, 0.f), 0.2f);
	float vase2 = sdSphere(p - float3(0.f, leg_height + 0.45f, 0.f), 0.17f);
	float vase3 = sdSphere(p - float3(0.f, leg_height + 0.72f, 0.f), 0.15f);
	float vase_cut1 = sdPlane(p - float3(0.f, leg_height + 0.615f, 0.f), float3(0.f, 1.f, 0.f));
	float vase_cut2 = sdPlane(p - float3(0.f, leg_height + 0.1f, 0.f), float3(0.f, -1.f, 0.f));
	float vase_body = max(smin(smin(vase1, vase2, 0.05f), vase3, 0.025f), vase_cut2);
	float vase = max(max(vase_body, vase_cut1), -vase_body - 0.01f);

	if (geometry_step)
	{
		OBJECT(plate);
		OBJECT(legs);
		OBJECT(vase);
	}
	else
	{
		if (MATERIAL(plate))
		{
			float step = floor((p.x + 1.25f) * 4.f) / 8.f;
			material_output.material_position.xyz = p + float3(p.z * 0.2f, step, 0.f);
			material_output.material_id = MATERIAL_WOOD;
		}
		else if (MATERIAL(legs))
		{
			material_output.material_position.xyz = p.xzy;
			material_output.material_id = MATERIAL_WOOD;
		}
		else if (MATERIAL(vase))
		{
			material_output.material_position.xyz = p * 4.f;
			material_output.material_id = MATERIAL_MARBLE_DARK;
		}
	}
}

void map_normal(GeometryInput geometry, inout NormalOutput output)
{
}

void map_light(GeometryInput input, inout LightOutput output[LIGHT_COUNT], inout float ambient_lighting_factor)
{
	output[0].used = true;
	output[0].pos = float4(-1.f, -1.f, 2.f, 1.f);
	output[0].color = float3(1.f, 1.f, 1.f);
}

float3 map_background(float3 dir, uint iter_count)
{
	return sky_color(dir, stime);
}