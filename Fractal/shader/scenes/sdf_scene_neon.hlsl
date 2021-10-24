#include "sdf_primitives.hlsl"
#include "sdf_ops.hlsl"
#include "sdf_common.hlsl"

float sdRingsphere(float3 pos, float spacing, float r1, float r2)
{
	float3 hit_point = normalize(pos) * r1;
	float y = hit_point.y;
	float x = length(hit_point.xz);
	float angle = atan2(y, x);
	angle = round(angle / spacing) * spacing;
	hit_point.y = tan(angle) * x;
	hit_point = normalize(hit_point) * r1;

	return length(pos - hit_point) - r2;
}

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
	map_groundplane(geometry, material_output, geometry_step, output_scene_distance);

	float r1 = VAR_r1(min = 0.2, max = 2, start = 1);
	float r2 = VAR_r2(min = 0.005, max = 0.1, start = 0.01);
	float spacing = VAR_spacing(min = 0.01, max = 0.2, start = 0.1);

	float ringsphere = sdRingsphere(geometry.pos.xyz - float3(0.f, 2.f, 0.f), spacing, r1, r2);

	float3 mirror_pos = geometry.pos.xyz - float3(0.f, 2.f, 2.75f);
	mirror_pos.xz = opRotate(mirror_pos.xz, 0.3f);
	float mirror = sdBox(mirror_pos, float3(1.f, 1.7f, 0.05f));
	float mirror_border = sdBox(mirror_pos, float3(1.05f, 1.75f, 0.04f));

	if (geometry_step)
	{
		OBJECT(ringsphere);
		OBJECT(mirror);
		OBJECT(mirror_border);
	}
	else
	{
		if (MATERIAL(ringsphere))
		{
			float r = VAR_red(min = 0, max = 1, start = 0.1, step = 0.05);
			float g = VAR_green(min = 0, max = 3, start = 1.0, step = 0.05);
			float b = VAR_blue(min = 0, max = 1, start = 0.2, step = 0.05);

			material_output.emissive_color.rgb = float3(r, g, b);
			material_output.diffuse_color.rgb = float3(r, g, b) / 2;
			material_output.specular_color.rgb = 0.5f;
		}
		else if (MATERIAL(mirror))
		{
			material_output.reflection_color.rgb = 0.8f;
			material_output.specular_color.rgb = 0.1f;
		}
		else if (MATERIAL(mirror_border))
		{
			material_output.diffuse_color.rgb = float3(0.5f, 0.5f, 0.5f);
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