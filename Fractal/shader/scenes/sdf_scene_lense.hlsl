#include "sdf_primitives.hlsl"
#include "sdf_ops.hlsl"
#include "user_variables.hlsl"

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
	// lower background
	float3 background1_pos = geometry.pos - float3(0.f, -5.f, 0.f);
	background1_pos.xz = opRepInf(background1_pos.xz, 3.f);
	float background1_sphere = sdSphere(background1_pos, 1.f);
	float background1_box = sdBox(background1_pos, 1.f);
	float background1 = lerp(background1_sphere, background1_box, 0.65) - 0.1;

	// upper background
	float3 background2_pos = geometry.pos - float3(0.f, +5.f, 0.f);
	background2_pos.xz = opRepInf(background2_pos.xz, 10.f);
	float background2_sphere = sdSphere(background2_pos, 1.f);
	float background2_box = sdBox(background2_pos, 1.f);
	float background2 = lerp(background2_sphere, background2_box, 0.65) - 0.1;

	// lense
	float3 lense_pos = abs(geometry.pos);
	lense_pos.z -= 5.1f;
	float lense1 = sdSphere(lense_pos, 5.f);
	float lense2 = sdSphere(geometry.pos, 2.f);
	float lense = max(-lense1, lense2);

	// sphere
	float x = VAR_xpos(min = -4, max = 4, step = 0.1);
	float y = VAR_ypos(min = -4, max = 4, step = 0.1);
	float z = VAR_zpos(min = 0, max = 25, step = 0.1);
	float3 sphere_pos = geometry.pos - float3(x, y, z);
	float sphere = sdSphere(sphere_pos, 2.f);

	// mirror
	float3 mirror_position = geometry.pos - float3(0.f, 0.f, -5.f);
	mirror_position.xz = opRotate(mirror_position.xz, stime * 0.3f);
	float mirror = sdBox(mirror_position, float3(1.f, 2.f, 0.1f));

	float mirror_frame = sdBox(mirror_position, float3(1.1f, 2.1f, 0.08f));

	if (geometry_step)
	{
		OBJECT(background1);
		OBJECT(background2);
		OBJECT(lense);
		OBJECT(sphere);
		OBJECT(mirror);
		OBJECT(mirror_frame);
	}
	else
	{
		float2 cell_index = (geometry.pos.xz - background1_pos.xz) / 3.f;

		if (MATERIAL(background1))
		{
			float3 cell_color1 = float3(sin(cell_index * 0.3f) * 0.5f + 0.5f, 1.f);
			float3 cell_color2 = cell_index.x < 0.01f ? float3(0.f, 1.f, 0.f) : float3(0.f, 0.f, 1.f);
			float3 cell_color = lerp(cell_color1, cell_color2, 0.25f);
			material_output.diffuse_color = float4(cell_color, 1.f);
			material_output.specular_color.rgb = 1.f;
			material_output.reflection_color = 0.5f;
		}
		else if (MATERIAL(background2))
		{
			material_output.diffuse_color = float4(1.f, 0.5f, 0.f, 1.f);
			material_output.specular_color.rgb = 1.f;
			material_output.reflection_color = 0.5f;
		}
		else if (MATERIAL(lense))
		{
			material_output.diffuse_color = float4(0.3f, 0.3f, 0.3f, 1.f);
			material_output.refraction_color = float3(0.9f, 0.9f, 0.9f);
		}
		else if (MATERIAL(sphere))
		{
			material_output.diffuse_color = float4(1.f, 0.2f, 0.2f, 1.f);
			material_output.emissive_color = float3(8.f, 0.f, 0.f);
			material_output.specular_color.rgb = 1.f;
			material_output.reflection_color = 0.25f;
		}
		else if (MATERIAL(mirror))
		{
			material_output.diffuse_color = float4(0.1f, 0.1f, 0.1f, 1.f);
			float mix_ratio = VAR_mixing(min = 0, max = 1, step = 0.05);
			material_output.refraction_color = mix_ratio;
			material_output.reflection_color = 1.f - mix_ratio;
		}
		else if (MATERIAL(mirror_frame))
		{
			material_output.material_position.xyz = mirror_position;
			material_output.material_id = MATERIAL_WOOD;
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
	dir.xz = opRotate(dir.xz, -stime * 0.025f);
	float noiseval = turbulence(dir * float3(1.f, 6.f, 1.f) * 2.5f);
	float3 color1 = float3(43.f, 164.f, 247.f) / 255.f;
	float3 color2 = float3(212.f, 224.f, 238.f) / 255.f;
	float3 sky_color = lerp(color1, color2, noiseval) * 1.2f;
	float3 horizon_color = float3(0.25f, 0.25f, 0.25f);
	return lerp(horizon_color, sky_color, saturate(dir.y * 8.f + 0.125f));
}