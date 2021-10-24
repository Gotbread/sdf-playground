#include "sdf_primitives.hlsl"
#include "sdf_materials.hlsl"
#include "sdf_ops.hlsl"
#include "noise.hlsl"

float2 get_tile_impact(float3 pos, float3 dir)
{
	float to_move = pos.y / dir.y;
	return pos.xz - dir.xz * to_move;
}

float4 tile_color_from_pos(float2 pos)
{
	float2 tile_index = floor(pos);
	float2 tile_pos = pos - tile_index;
	float tile_parity = round(frac((tile_index.x + tile_index.y) * 0.5f + 0.25f));
	float3 color = tile_parity > 0.5f ? float3(0.1f, 0.1f, 0.1f) : float3(0.8f, 0.8f, 0.8f);

	float2 dist_vec = 0.5f - abs(tile_pos - 0.5f);
	float dist = min(dist_vec.x, dist_vec.y);

	return float4(color, dist);
}

static const float3 brightness_fac = float3(0.2126f, 0.7152f, 0.0722f);

float3 HUEtoRGB(float H)
{
	float R = abs(H * 6 - 3) - 1;
	float G = 2 - abs(H * 6 - 2);
	float B = 2 - abs(H * 6 - 4);
	return saturate(float3(R, G, B));
}

float3 HSVtoRGB(float3 HSV)
{
	float3 RGB = HUEtoRGB(HSV.x);
	return ((RGB - 1) * HSV.y + 1) * HSV.z;
}

float3 color_from_index(uint index)
{
	float h = ((float)index) / 5.f;
	float3 color = HSVtoRGB(float3(h, 1.f, 1.f));
	float brightness = dot(color, brightness_fac);
	return color / brightness;
}

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
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

	// plane
	float floor1 = sdPlaneFast(geometry.pos, geometry.dir, float3(0.f, 1.f, 0.f));

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
		OBJECT(floor1);
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
		else if (MATERIAL(floor1))
		{
			float3 offset_right = geometry.right_ray_offset * geometry.camera_distance;
			float3 offset_bottom = geometry.bottom_ray_offset * geometry.camera_distance;
			// ===========
			float2 tile_pos1 = get_tile_impact(geometry.pos, geometry.dir.xyz);
			float4 color1 = tile_color_from_pos(tile_pos1);

			float2 tile_pos2 = get_tile_impact(geometry.pos + offset_right, geometry.dir.xyz);
			float4 color2 = tile_color_from_pos(tile_pos2);

			float2 tile_pos3 = get_tile_impact(geometry.pos + offset_bottom, geometry.dir.xyz);
			float4 color3 = tile_color_from_pos(tile_pos3);

			float2 tile_pos4 = get_tile_impact(geometry.pos + offset_bottom + offset_right, geometry.dir.xyz);
			float4 color4 = tile_color_from_pos(tile_pos4);

			float total_dist = color1.w + color2.w + color3.w + color4.w;
			float3 color = (color1.rgb * color1.a + color2.rgb * color2.a + color3.rgb * color3.a + color4.rgb * color4.a) / total_dist;
			// ============
			material_output.diffuse_color = float4(color, 1.f);
			material_output.specular_color.rgb = 0.325f + dot(color, color) * 0.125f;
		}
	}
}

void map_normal(GeometryInput input, inout NormalOutput output)
{
}

void map_light(GeometryInput input, inout LightOutput output[LIGHT_COUNT], inout float ambient_lighting_factor)
{
	//output[0].used = true;
	output[0].pos = float4(-1.f, -1.f, 2.f, 1.f);
	output[0].color = float3(1.f, 1.2f, 1.f);

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
	dir.xz = opRotate(dir.xz, -stime * 0.025f);
	//return iter_count / 50.f;
	float noiseval = turbulence(dir * float3(1.f, 6.f, 1.f) * 2.5f);
	float3 color1 = float3(43.f, 164.f, 247.f) / 255.f;
	float3 color2 = float3(212.f, 224.f, 238.f) / 255.f;
	float3 sky_color = lerp(color1, color2, noiseval * 0.8f + 0.2f) * 1.2f;
	float3 horizon_color = float3(0.25f, 0.25f, 0.25f);
	return lerp(horizon_color, sky_color, saturate(dir.y * 8.f + 0.125f));
}