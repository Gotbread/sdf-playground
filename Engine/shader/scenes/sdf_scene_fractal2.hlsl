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

// maps the input modulo the range from lower to upper
float mod(float input, float lower, float upper)
{
	float range = upper - lower;
	float reduced = (input - lower) / range;
	float fract = reduced - floor(reduced);
	return fract * range + lower;
}

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
	map_groundplane(geometry, material_output, geometry_step, output_scene_distance);

	float size = 1.f;
	float3 fractal_pos = geometry.pos - float3(0.f, 1.f, 0.f);
	float3 fractal_base_pos = fractal_pos;
	float fractal_slice = dot(fractal_base_pos, 1.f);
	float slider = VAR_slider(min = -5, max = 5, step = 0.01, start = 0);

	float fractal = 1e30;
	float scale = 1.f;

	uint iter = 0;

	for (uint i = 0; i < 6; ++i)
	{
		float new_d = sdBox(fractal_pos, size * 0.5f) / scale;
		fractal = min(fractal, new_d);
		if (new_d < dist_eps * 2.f)
		{
			iter = i;
		}

		// all 6 sides
		fractal_pos = abs(fractal_pos);
		fractal_pos.yxz = sort_components(fractal_pos.yxz);

		// move up
		fractal_pos.y -= size * 2.f / 3.f;

		// offset blocks
		fractal_pos.z -= step(size * 0.5f / 3.f, fractal_pos.z) * size / 3.f * (1.001f);

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
			float slice_size = 0.01f;
			float diff = fractal_slice - stime * 0.5f -snoise(fractal_base_pos) * 0.5f;
			diff = mod(diff, -0.5f, +0.5f);
			float colorize = saturate(slice_size - abs(diff)) / slice_size;

			float len = length(fractal_base_pos);
			float3 color1 = float3(1.f, 0.8f, 0.1f);
			float3 color2 = float3(0.8f, 0.3f, 0.1f) * colorize * 1.5f;
			float3 glow_color = float3(0.1f, 0.5f, 0.1f) * saturate((0.6f - len) * 10.f);
			material_output.diffuse_color.rgb = color1;
			material_output.emissive_color.rgb = color2 + glow_color;
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
	output[0].pos = float4(-1.f, -4.f, 2.f, 1.f);
	output[0].color = float3(1.f, 1.f, 1.f);

	ambient_lighting_factor = 0.1f;
}

float3 map_background(float3 dir, uint iter_count)
{
	return sky_color(dir, stime);
}