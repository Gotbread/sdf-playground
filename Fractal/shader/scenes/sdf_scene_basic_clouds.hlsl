#include "sdf_primitives.hlsl"
#include "sdf_materials.hlsl"
#include "sdf_ops.hlsl"
#include "sdf_common.hlsl"

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
	map_groundplane(geometry, material_output, geometry_step, output_scene_distance);

	float3 cloud_pos = geometry.pos - float3(0.f, 5.f, 0.f);
	float cloud = sdBox(cloud_pos, float3(2.f, 0.5f, 2.f));

	float transparent_cloud = sdBox(march.last_transparent_pos - float3(0.f, 5.f, 0.f), float3(2.f, 0.5f, 2.f));

	if (geometry_step)
	{
		OBJECT_TRANSPARENT(cloud, transparent_cloud);
	}
	else
	{
		if (MATERIAL(cloud))
		{
			float thickness = 0.f + VAR_offset(min = -5, max = 5, step = 0.05);
			for (uint i = 0; i < 5; ++i)
			{
				float3 sample_pos = cloud_pos + geometry.dir.xyz * 0.5f * (float)i;
				thickness += turbulence(sample_pos);
			}
			thickness = saturate(thickness);
			float3 color = 1.f - thickness * 0.2f;
			material_output.diffuse_color = float4(color, thickness);
		}
	}
}

void map_normal(GeometryInput geometry, inout NormalOutput output)
{
}

void map_light(GeometryInput input, inout LightOutput output[LIGHT_COUNT], inout float ambient_lighting_factor)
{
	output[0].used = true;
	output[0].pos = float4(-1.f, -4.f, 1.5f, 1.f);
	output[0].color = float3(1.f, 1.f, 1.f);
}

float3 map_background(float3 dir, uint iter_count)
{
	return sky_color(dir, stime);
}