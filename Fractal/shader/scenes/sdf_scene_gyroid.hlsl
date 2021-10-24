#include "sdf_primitives.hlsl"
#include "sdf_ops.hlsl"
#include "sdf_common.hlsl"

float sdGyroid(float3 p)
{
	return dot(sin(p.xyz), cos(p.zxy));
}

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
	float gyroid = sdGyroid(geometry.pos.xyz * 7.f) / 14.f;
	gyroid = abs(gyroid) - 0.01f;
	float box = sdBox(geometry.pos.xyz, float3(1.f, 1.f, 1.f));
	float obj = max(gyroid, box);

	if (geometry_step)
	{
		OBJECT(obj);
	}
	else
	{
		if (MATERIAL(obj))
		{
			material_output.diffuse_color.rgb = float3(0.9f, 0.7f, 0.2f);
			material_output.specular_color.rgb = 0.5f;
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