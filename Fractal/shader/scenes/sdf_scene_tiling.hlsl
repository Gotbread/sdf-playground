#include "sdf_primitives.hlsl"
#include "sdf_materials.hlsl"
#include "sdf_ops.hlsl"
#include "user_variables.hlsl"
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

float3 random_color(float2 cell_index)
{
	float r = hashf((int)(cell_index.x + cell_index.y * 217.743f));
	float g = hashf((int)(cell_index.x + cell_index.y * 217.743f + 2475.235f));
	float b = hashf((int)(cell_index.x + cell_index.y * 217.743f + 824.213f));
	float maxval = max(max(r, g), b);
	return float3(r, g, b) / maxval;
}

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
	float3 cable_pos = geometry.pos - float3(+4.f, 4.f, 4.f);
	float cable_radius = 0.1f;

	float pane1 = sdBox(geometry.pos - float3(-4.f, 4.f, 0.f), float3(1.f, 2.f, 0.05f));
	float pane2 = sdBox(geometry.pos - float3(+0.f, 4.f, 0.f), float3(1.f, 2.f, 0.05f));
	float pane3 = sdBox(geometry.pos - float3(+4.f, 4.f, 0.f), float3(1.f, 2.f, 0.05f));
	float cable = sdCappedCylinder(cable_pos, 2.f, cable_radius);

	// plane
	float floor1 = sdPlaneFast(geometry.pos, geometry.dir, float3(0.f, 1.f, 0.f));

	if (geometry_step)
	{
		OBJECT(pane1);
		OBJECT(pane2);
		OBJECT(pane3);
		OBJECT(cable);
		OBJECT(floor1);
	}
	else
	{
		float2 uv = geometry.pos.xy;
		float m1 = VAR_m1(min = -1, max = 3, step = 0.1, start = 1);
		float m2 = VAR_m2(min = -1, max = 3, step = 0.1, start = 0);
		float width = VAR_width(min = 0.1, max = 0.5, step = 0.05, start = 0.4);
		float run_length = VAR_run_length(min = 1, max = 10, step = 1, start = 4);
		float run_flip = VAR_run_flip(min = 1, max = 10, step = 1, start = 2);

		if (MATERIAL(pane1))
		{
			float4 v = voronoi(uv * 5.f, 0.45f);
			float3 color = v.w > 0.05f ? random_color(v.xy) * 1.1f: float3(0.25f, 0.25f, 0.25f);
			material_output.diffuse_color = float4(color, 1.f);
			material_output.specular_color.rgb = 0.4f;
			material_output.specular_color.a = 20.f;
		}
		else if (MATERIAL(pane2))
		{
			float flip_chance = VAR_flip_chance(min = 0, max = 1, steps = 0.05);
			float width = VAR_truchet_width(min = 0, max = 0.2, step = 0.01);

			float2 uv_prime = opAB2UV(uv);
			float4 truchet = truchet_band(uv_prime * 3.f, flip_chance, width, float2(0.f, -1.f));
			float green = truchet.w < 0.f ? 0.f : sin(truchet.w * 2.f * pi * 5.f + stime * 2.f) * 0.5f + 0.5f;
			material_output.diffuse_color = float4(0.f, green * green, 0.f, 1.f);
		}
		else if (MATERIAL(pane3))
		{
			uv = opAB2UV(uv * 5.f);
			uv = float2(uv.x * m1 + uv.y * m2, uv.x * m2 + uv.y * m1);
			float4 pattern = braid(uv, width, run_length, run_flip, float2(-2.f, 0.f));

			float grey = step(-1.f, pattern.z) * (cos(pattern.z * 50.f) * 0.5f + 0.5f);
			float3 color = grey * grey;

			material_output.diffuse_color = float4(color * 0.8f, 1.f);
		}
		else if (MATERIAL(cable))
		{
			float angle = atan2(cable_pos.z, cable_pos.x);
			float2 uv_round = float2(angle * cable_radius, cable_pos.y);

			uv_round = opAB2UV(uv_round * 8.f);
			uv_round = float2(uv_round.x * m1 + uv_round.y * m2, uv_round.x * m2 + uv_round.y * m1);

			float4 pattern = braid(uv_round, width, run_length, run_flip, float2(-2.f, 0.f));

			float grey = step(-1.f, pattern.z) * (cos(pattern.z * 50.f) * 0.5f + 0.5f);
			float3 color = grey * grey;

			material_output.diffuse_color = float4(color * 0.9f, 1.f);
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
			material_output.specular_color.rgb = 0.5f;
		}
	}
}

void map_normal(GeometryInput input, inout NormalOutput output)
{
}

void map_light(GeometryInput input, inout LightOutput output[LIGHT_COUNT], inout float ambient_lighting_factor)
{
	output[0].used = true;
	output[0].pos = float4(-1.f, -1.f, 2.f, 1.f);
	output[0].color = float3(1.f, 1.2f, 1.f);
}

float3 map_background(float3 dir, uint iter_count)
{
	dir.xz = opRotate(dir.xz, -stime * 0.025f);
	float noiseval = turbulence(dir * float3(1.f, 6.f, 1.f) * 2.5f);
	float3 color1 = float3(43.f, 164.f, 247.f) / 255.f;
	float3 color2 = float3(212.f, 224.f, 238.f) / 255.f;
	float3 sky_color = lerp(color1, color2, noiseval * 0.8f + 0.2f) * 1.2f;
	float3 horizon_color = float3(0.25f, 0.25f, 0.25f);
	return lerp(horizon_color, sky_color, saturate(dir.y * 8.f + 0.125f));
}