#include "sdf_primitives.hlsl"
#include "sdf_ops.hlsl"
#include "user_variables.hlsl"

#define OBJECT(distance) output_scene_distance = min(output_scene_distance, distance)

float map_geometry(GeometryInput input)
{
	float output_scene_distance = 3e38;

	// lower background
	float3 background1_pos = input.pos - float3(0.f, -5.f, 0.f);
	background1_pos.xz = opRepInf(background1_pos.xz, 3.f);
	float background1_sphere = sdSphere(background1_pos, 1.f);
	float background1_box = sdBox(background1_pos, 1.f);
	float background1 = lerp(background1_sphere, background1_box, 0.65) - 0.1;
	OBJECT(background1);

	// upper background
	float3 background2_pos = input.pos - float3(0.f, +5.f, 0.f);
	background2_pos.xz = opRepInf(background2_pos.xz, 10.f);
	float background2_sphere = sdSphere(background2_pos, 1.f);
	float background2_box = sdBox(background2_pos, 1.f);
	float background2 = lerp(background2_sphere, background2_box, 0.65) - 0.1;
	OBJECT(background2);

	// lense
	float3 lance_pos = abs(input.pos);
	lance_pos.z -= 5.1f;
	float lance1 = sdSphere(lance_pos, 5.f);
	float lance2 = sdSphere(input.pos, 2.f);
	float lance = max(-lance1, lance2);
	OBJECT(lance);

	// sphere
	float x = VAR_xpos(min = -4, max = 4, step = 0.1);
	float y = VAR_ypos(min = -4, max = 4, step = 0.1);
	float z = VAR_zpos(min = 0, max = 25, step = 0.1);
	float3 sphere_pos = input.pos - float3(x, y, z);
	float sphere = sdSphere(sphere_pos, 2.f);
	OBJECT(sphere);

	// mirror
	float3 mirror_position = input.pos - float3(0.f, 0.f, -5.f);
	mirror_position.xz = opRotate(mirror_position.xz, stime * 0.3f);
	float mirror = sdBox(mirror_position, float3(1.f, 2.f, 0.1f));
	OBJECT(mirror);

	float mirror_frame = sdBox(mirror_position, float3(1.1f, 2.1f, 0.08f));
	OBJECT(mirror_frame);

	return output_scene_distance;
}

void map_normal(GeometryInput input, inout NormalOutput output)
{
}

void map_material(MaterialInput input, inout MaterialOutput output)
{
	// lower background
	float3 background1_pos = input.pos - float3(0.f, -5.f, 0.f);
	background1_pos.xz = opRepInf(background1_pos.xz, 3.f);
	float2 cell_index = (input.pos.xz - background1_pos.xz) / 3.f;
	float background1_sphere = sdSphere(background1_pos, 1.f);
	float background1_box = sdBox(background1_pos, 1.f);
	float background1 = lerp(background1_sphere, background1_box, 0.65) - 0.1;

	// upper background
	float3 background2_pos = input.pos - float3(0.f, +5.f, 0.f);
	background2_pos.xz = opRepInf(background2_pos.xz, 10.f);
	float background2_sphere = sdSphere(background2_pos, 1.f);
	float background2_box = sdBox(background2_pos, 1.f);
	float background2 = lerp(background2_sphere, background2_box, 0.65) - 0.1;

	// lense
	float3 lance_pos = abs(input.pos);
	lance_pos.z -= 5.1f;
	float lance1 = sdSphere(lance_pos, 5.f);
	float lance2 = sdSphere(input.pos, 2.f);
	float lance = max(-lance1, lance2);

	// sphere
	float x = VAR_xpos(min = -4, max = 4, step = 0.1);
	float y = VAR_ypos(min = -4, max = 4, step = 0.1);
	float z = VAR_zpos(min = 0, max = 25, step = 0.1);
	float3 sphere_pos = input.pos - float3(x, y, z);
	float sphere = sdSphere(sphere_pos, 2.f);

	// mirror
	float3 mirror_position = input.pos - float3(0.f, 0.f, -5.f);
	mirror_position.xz = opRotate(mirror_position.xz, stime * 0.3f);
	float mirror = sdBox(mirror_position, float3(1.f, 2.f, 0.1f));

	// mirror frame
	float mirror_frame = sdBox(mirror_position, float3(1.1f, 2.1f, 0.08f));


	if (abs(background1) < dist_eps)
	{
		float3 cell_color1 = float3(sin(cell_index * 0.3f) * 0.5f + 0.5f, 1.f);
		float3 cell_color2 = cell_index.x < 0.01f ? float3(0.f, 1.f, 0.f) : float3(0.f, 0.f, 1.f);
		float3 cell_color = lerp(cell_color1, cell_color2, 0.25f);
		output.diffuse_color = float4(cell_color, 1.f);
		output.specular_color.rgb = 1.f;
		output.reflection_color = 0.5f;
	}
	else if (abs(background2) < dist_eps)
	{
		output.diffuse_color = float4(1.f, 0.5f, 0.f, 1.f);
		output.specular_color.rgb = 1.f;
		output.reflection_color = 0.5f;
	}
	else if (abs(lance) < dist_eps)
	{
		output.diffuse_color = float4(0.3f, 0.3f, 0.3f, 1.f);
		output.refraction_color = float3(0.9f, 0.9f, 0.9f);
	}
	else if (abs(sphere) < dist_eps)
	{
		output.diffuse_color = float4(0.8f, 0.2f, 0.2f, 1.f);
		output.emissive_color = float3(8.f, 0.f, 0.f);
		output.specular_color.rgb = 1.f;
		output.reflection_color = 0.25f;
		output.normal.xyz = input.obj_normal + snoise(input.pos * 60.f) * 0.1f;
		output.normal.a = 0.f;
	}
	else if (abs(mirror) < dist_eps)
	{
		output.diffuse_color = float4(0.1f, 0.1f, 0.1f, 1.f);
		float mix_ratio = VAR_mixing(min = 0, max = 1, step = 0.05);
		output.refraction_color = mix_ratio;
		output.reflection_color = 1.f - mix_ratio;
	}
	else if (abs(mirror_frame) < dist_eps)
	{
		output.material_position.xyz = mirror_position;
		output.material_id = MATERIAL_WOOD;
	}
}

void map_light(LightInput input, inout LightOutput output)
{
	output.used = true;
	output.pos = float3(0.f, 5.f, 0.f);
	output.color = float3(0.f, 0.f, 1.f);
	output.falloff = 0.f; // still not decided
}