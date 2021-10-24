#include "sdf_primitives.hlsl"
#include "sdf_ops.hlsl"
#include "sdf_common.hlsl"

float3 color_from_index(uint index)
{
	float h = ((float)index) / 5.f;
	float3 color = HSVtoRGB(float3(h, 1.f, 1.f));
	float brightness = RGBtoBrightness(color);
	return color / brightness;
}

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
	map_groundplane(geometry, material_output, geometry_step, output_scene_distance);

	// cubes
	float3 cube_pos = geometry.pos;
	cube_pos.xz = opRepLim(cube_pos.xz, float2(2.f, 2.f), float2(3.f, 3.f));
	float cubes = sdBox(cube_pos - float3(0.f, 1.f, 0.f), 0.4f) - 0.1f;

	float time = stime * 0.25f;

	float spheres[5];
	for (uint i = 0; i < 5; ++i)
	{
		time += pi * 2.f / 5.f;
		float sphere_x = cos(time * 1.f) * -5.f;
		float sphere_y = (cos(time * 2.f) * -0.5f + 0.5f) * 2.f + 1.f;
		float sphere_z = sin(time * 2.f) * 2.f;

		spheres[i] = sdSphere(geometry.pos - float3(sphere_x, sphere_y, sphere_z), 0.2f);
	}

	if (geometry_step)
	{
		if (!march.is_shadow_pass)
		{
			OBJECT(spheres[0]);
			OBJECT(spheres[1]);
			OBJECT(spheres[2]);
			OBJECT(spheres[3]);
			OBJECT(spheres[4]);
		}
		OBJECT(cubes);
	}
	else
	{
		for (uint i = 0; i < 5; ++i)
		{
			if (MATERIAL(spheres[i]))
			{
				material_output.emissive_color = color_from_index(i);
			}
		}
		if (MATERIAL(cubes))
		{
			material_output.diffuse_color.rgb = 0.65f;
			material_output.specular_color.rgb = 0.75f;
		}
	}
}

void map_normal(GeometryInput geometry, inout NormalOutput output)
{
}

void map_light(GeometryInput input, inout LightOutput output[LIGHT_COUNT], inout float ambient_lighting_factor)
{
	float time = stime * 0.25f;

	float spheres[5];
	for (uint i = 0; i < 5; ++i)
	{
		time += pi * 2.f / 5.f;
		float sphere_x = cos(time * 1.f) * -5.f;
		float sphere_y = (cos(time * 2.f) * -0.5f + 0.5f) * 2.f + 0.5f;
		float sphere_z = sin(time * 2.f) * 2.f;

		output[i + 1].used = true;
		output[i + 1].pos.xyz = float3(sphere_x, sphere_y, sphere_z);
		output[i + 1].extend = 0.25f;
		output[i + 1].falloff = 0.25f;
		output[i + 1].color = color_from_index(i) * 0.5f;
	}
}

float3 map_background(float3 dir, uint iter_count)
{
	return sky_color(dir, stime);
}