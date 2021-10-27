#include "sdf_primitives.hlsl"
#include "sdf_materials.hlsl"
#include "sdf_ops.hlsl"
#include "sdf_common.hlsl"

float3 cartesian2spherical(float3 pos)
{
	float r = length(pos);
	float theta = atan2(pos.y, length(pos.xz));
	float phi = atan2(pos.z, pos.x);
	return float3(r, theta, phi);
}

void cartesian2spherical(float3 pos, float3 norm, out float3 out_pos, out float3 out_norm)
{
	out_pos = cartesian2spherical(pos);
	float3 offset = cartesian2spherical(pos + norm * 0.01f);
	out_norm = normalize(offset - out_pos);
}

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
	map_groundplane(geometry, material_output, geometry_step, output_scene_distance);

	float box_offset = VAR_boxoffset(min = 0, max = 2, step = 0.1, start = 2);
	float sphere = sdSphere(geometry.pos - float3(0.f, 2.f, 0.f), 2.f);
	float box = sdBox(geometry.pos - float3(-1.f, 3.f + box_offset, -1.f), 1.f);
	sphere = max(sphere, -box);

	if (geometry_step)
	{
		OBJECT(sphere);
	}
	else
	{
		if (MATERIAL(sphere))
		{
			float3 pos = (geometry.pos - float3(0.f, 2.f, 0.f)) * 2.f;
			float3 norm = material_input.obj_normal;

			float use_spherical = VAR_spherical(min = 0, max = 1, step = 1, start = 0);
			if (use_spherical > 0.5f)
			{
				cartesian2spherical(pos, norm, pos, norm);
				pos *= float3(1.f, 8.f / pi, 8.f / pi);
			}
			float sel = coordinate_material(pos, norm, 0.02f);
			float3 color = sel > VAR_thres(min=0,max=1,step=0.05, start=0.4) ? float3(1.f, 0.f, 0.f) : float3(0.8f, 0.8f, 0.8f);

			material_output.diffuse_color.rgb = color;
			material_output.specular_color.rgb = 0.25f;
			material_output.specular_color.a = 100.f;
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