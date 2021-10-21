#include "sdf_primitives.hlsl"
#include "sdf_ops.hlsl"
#include "user_variables.hlsl"

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

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
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

	// plane
	float floor1 = sdPlaneFast(geometry.pos, geometry.dir, float3(0.f, 1.f, 0.f));

	if (geometry_step)
	{
		OBJECT(cube);
		OBJECT(guard);
		OBJECT(floor1);
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
		else if (MATERIAL(floor1))
		{
			float3 offset_right = geometry.right_ray_offset * geometry.camera_distance;
			float3 offset_bottom = geometry.bottom_ray_offset * geometry.camera_distance;
			// ===========
			float2 tile_pos1 = get_tile_impact(geometry.pos, geometry.dir);
			float4 color1 = tile_color_from_pos(tile_pos1);

			float2 tile_pos2 = get_tile_impact(geometry.pos + offset_right, geometry.dir);
			float4 color2 = tile_color_from_pos(tile_pos2);

			float2 tile_pos3 = get_tile_impact(geometry.pos + offset_bottom, geometry.dir);
			float4 color3 = tile_color_from_pos(tile_pos3);

			float2 tile_pos4 = get_tile_impact(geometry.pos + offset_bottom + offset_right, geometry.dir);
			float4 color4 = tile_color_from_pos(tile_pos4);

			float total_dist = color1.w + color2.w + color3.w + color4.w;
			float3 color = (color1.rgb * color1.a + color2.rgb * color2.a + color3.rgb * color3.a + color4.rgb * color4.a) / total_dist;
			// ============
			material_output.diffuse_color = float4(color, 1.f);
			material_output.specular_color.rgb = 1.f;
		}
	}
}

void map_normal(GeometryInput input, inout NormalOutput output)
{
}

void map_light(LightInput input, inout LightOutput output)
{
}

float3 map_background(float3 dir, uint iter_count)
{
	dir.xz = opRotate(dir.xz, -stime * 0.025f);
	//return iter_count / 50.f;
	float noiseval = turbulence(dir * float3(1.f, 6.f, 1.f) * 2.5f);
	float3 color1 = float3(43.f, 164.f, 247.f) / 255.f;
	float3 color2 = float3(212.f, 224.f, 238.f) / 255.f;
	float3 sky_color = lerp(color1, color2, noiseval) * 1.2f;
	float3 horizon_color = float3(0.25f, 0.25f, 0.25f);
	return lerp(horizon_color, sky_color, saturate(dir.y * 8.f + 0.125f));
}