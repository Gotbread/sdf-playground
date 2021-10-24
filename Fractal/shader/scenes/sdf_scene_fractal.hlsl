#include "sdf_primitives.hlsl"
#include "sdf_ops.hlsl"
#include "sdf_common.hlsl"

// changes the entries around so x is biggest, then y, then z
float3 sort_components(float3 vec)
{
	if (vec.z > vec.y)
		vec.yz = vec.zy;
	if (vec.y > vec.x)
		vec.xy = vec.yx;
	if (vec.z > vec.y)
		vec.yz = vec.zy;
	return vec;
}

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
	map_groundplane(geometry, material_output, geometry_step, output_scene_distance);

	float size = 1.f;
	float3 fractal_pos = geometry.pos - float3(0.f, 1.f, 0.f);
	float g = 0.7f;

	float fractal = 1e30;
	float scale = 1.f;
	float iters_needed = 0.f;

	for (int i = 0; i < 8; ++i)
	{
		float new_d = sdBox(fractal_pos, size * 0.5f) / scale;
		if (new_d < 0.0001f && fractal > 0.0001f)
		{
			iters_needed = (float)i;
		}
		fractal = min(fractal, new_d);

		// all 6 sides
		fractal_pos = abs(fractal_pos);
		fractal_pos.yxz = sort_components(fractal_pos.yxz);

		// move up
		fractal_pos.y -= size * 2.f / 3.f;

		// face block 1
		fractal_pos.y += size / 3.f;
		fractal_pos.yxz = sort_components(fractal_pos.yxz);
		fractal_pos.y -= size / 3.f;

		// recursion
		fractal_pos *= 3.f;
		scale *= 3.f;
	}

	if (geometry_step)
	{
		OBJECT(fractal);
	}
	else
	{
		if (MATERIAL(fractal))
		{
			material_output.diffuse_color.xyz = float3(0.9f, g, iters_needed * 0.125f);
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