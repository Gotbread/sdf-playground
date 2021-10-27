#include "sdf_primitives.hlsl"
#include "sdf_ops.hlsl"
#include "sdf_common.hlsl"

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
	map_groundplane(geometry, material_output, geometry_step, output_scene_distance);

	float3 cell_pos = geometry.pos;
	cell_pos.xz = opRepInf(cell_pos.xz, 2.f);
	float3 cube_pos = cell_pos;
	float2 cell_index = (geometry.pos.xz - cell_pos.xz) / 2.f;
	float2 sometimes_pos = round(frac(cell_index * 0.5f + 0.25f));
	bool is_other = sometimes_pos.x < 0.5f && sometimes_pos.y < 0.5f;
	float phase = cell_index.x + cell_index.y * 0.3f + stime;
	float h = sin(phase);
	cube_pos.xz = opRotate(cube_pos.xz, cos(phase) * 0.4f);

	// cube
	float cube = sdBox(cube_pos - float3(0.f, 2.f + h, 0.f), is_other ? 0.25f : 0.5f) - 0.15f;

	// guard object for the folding
	float guard = sdLimit2(cell_pos.xz, geometry.dir.xz, 2.01f);

	if (geometry_step)
	{
		OBJECT(cube);
		OBJECT(guard);
	}
	else
	{
		if (MATERIAL(cube))
		{
			if (is_other)
			{
				material_output.diffuse_color = float4(0.8f, 0.2f, 0.2f, 1.f);
				material_output.specular_color.rgb = 1.f;
			}
			else
			{
				material_output.diffuse_color = float4(0.6f, 0.5f, 0.2f, 1.f);
				material_output.specular_color.rgb = 1.f;
				material_output.reflection_color = 0.25f;
			}
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