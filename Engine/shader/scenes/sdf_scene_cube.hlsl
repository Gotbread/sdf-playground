#include "sdf_primitives.hlsl"
#include "sdf_ops.hlsl"
#include "sdf_common.hlsl"

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
	map_groundplane(geometry, material_output, geometry_step, output_scene_distance);

	float size = VAR_size(min = 0.2, max = 2, start = 1, step = 0.2);
	float x = VAR_xpos(min = -2, max = 2, start = 0, step = 0.1);
	float y = VAR_ypos(min = -2, max = 2, start = 0, step = 0.1);
	float z = VAR_zpos(min = -2, max = 2, start = 0, step = 0.1);

	// cube
	float cube = sdBox(geometry.pos - float3(0.f, 1.f, 0.f) - float3(x, y, z), size);

	if (geometry_step)
	{
		OBJECT(cube);
	}
	else
	{
		if (MATERIAL(cube))
		{
			float r = VAR_red(min = 0, max = 1, start = 0.9, step = 0.05);
			float g = VAR_green(min = 0, max = 1, start = 0.7, step = 0.05);
			float b = VAR_blue(min = 0, max = 1, start = 0.2, step = 0.05);
			material_output.diffuse_color = float4(r, g, b, 1.f);
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