#include "sdf_primitives.hlsl"
#include "sdf_materials.hlsl"
#include "sdf_ops.hlsl"
#include "sdf_common.hlsl"

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
	map_groundplane(geometry, material_output, geometry_step, output_scene_distance);

	float box1 = sdBox(geometry.pos - float3(0.f, 2.f, -1.f), float3(1.f, 1.f, 0.1f));
	float box2 = sdBox(geometry.pos - float3(0.f, 2.f, +0.f), float3(1.f, 1.f, 0.1f));
	float box3 = sdBox(geometry.pos - float3(0.f, 2.f, +1.f), float3(1.f, 1.f, 0.1f));

	float transparent_box1 = sdBox(march.last_transparent_pos - float3(0.f, 2.f, -1.f), float3(1.f, 1.f, 0.1f));
	float transparent_box2 = sdBox(march.last_transparent_pos - float3(0.f, 2.f, +0.f), float3(1.f, 1.f, 0.1f));
	float transparent_box3 = sdBox(march.last_transparent_pos - float3(0.f, 2.f, +1.f), float3(1.f, 1.f, 0.1f));

	if (geometry_step)
	{
		OBJECT_TRANSPARENT(box1, transparent_box1);
		OBJECT_TRANSPARENT(box2, transparent_box2);
		OBJECT_TRANSPARENT(box3, transparent_box3);
	}
	else
	{
		if (MATERIAL(box1))
		{
			material_output.diffuse_color = float4(0.9f, 0.9f, 0.f, 0.3f);
		}
		else if (MATERIAL(box2))
		{
			material_output.diffuse_color = float4(0.f, 0.9f, 0.9f, 0.3f);
		}
		else if (MATERIAL(box3))
		{
			material_output.diffuse_color = float4(0.9f, 0.f, 0.9f, 0.3f);
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