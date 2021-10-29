#include "sdf_primitives.hlsl"
#include "sdf_ops.hlsl"
#include "sdf_common.hlsl"

float sdBranch(float3 pos, float h1, float h2, float h3, float r1, float r2)
{
	float2 p2 = float2(length(pos.xz), pos.y);

	float plane1 = dot(p2, normalize(float2(h1, -r1)));
	float plane2 = dot(p2 - float2(r1, h1), normalize(float2(h2 - h1, r1 - r2)));
	float plane3 = dot(p2 - float2(0.f, h3), normalize(float2(h3 - h2, r2)));
	float plane_bottom = -pos.y;
	float plane_top = pos.y - h3;

	return max(max(max(max(plane1, plane2), plane3), plane_bottom), plane_top);
}

float sdBranch(float3 pos, float h2, float r1, float r2)
{
	float2 p2 = float2(length(pos.xz), pos.y);

	float plane = dot(p2 - float2(r1, 0), normalize(float2(h2, r1 - r2)));
	float plane_bottom = -pos.y;
	float plane_top = pos.y - h2;

	return max(max(plane, plane_bottom), plane_top);
}

void sdTree(float3 pos, out float tree, out float leafes, float noiseval)
{
	float tree_scale = 1.f;
	float leaf_scale = 1.f;
	tree = 3e30;
	leafes = 3e30;

	float angle1 = 35.f;
	float angle2 = 34.f;
	float angle3 = 90.f - noiseval * 10.f;
	float side_offset = 0.075f;
	float height_offset1 = 0.33f + noiseval * 0.05f;
	float height_offset2 = 0.41f;
	float sphere_size = 0.07f - noiseval * 0.02f;
	uint iters = 9;

	float tree_scale_factor = 1.4f;
	float leaf_scale_factor = 1.3f;

	for (uint i = 0; i < iters; ++i)
	{
		// branches
		float branch = sdBranch(pos / tree_scale, 1.f, 0.1f, 0.05f) * tree_scale;
		tree = smin(tree, branch, 0.01f);

		// leafes
		float leaf = sdSphere(pos / tree_scale - float3(0.f, 1.f + sphere_size * leaf_scale, 0.f), sphere_size * leaf_scale) * tree_scale;
		leafes = min(leafes, leaf);

		float height = i == 0 ? height_offset1 : height_offset2;
		pos.y -= height * tree_scale;
		pos.xz = abs(pos.xz);
		if (pos.x > pos.z && i == 0)
			pos.xz = pos.zx;
		pos.z += side_offset * tree_scale;
		float angle = i == 0 ? angle1 : angle2;
		pos.yz = opRotate(pos.yz, -angle / 180.f * pi);
		pos.xz = opRotate(pos.xz, angle3 / 180.f * pi);

		// next iteration
		tree_scale /= tree_scale_factor;
		leaf_scale *= leaf_scale_factor;
	}
}

// uv: input position
// dir: input direction
void voronoi(float2 uv, float2 dir, float max_offset, out float2 closest_cell_id, out float2 closest_center_vec, out float closest_distance)
{
	float2 cell_index = floor(uv);
	float2 cell_pos = (uv - cell_index) - 0.5f;

	float2 local_point = voronoi_cell_offset(cell_index);
	float l_center_min = 10.f;
	closest_distance = 10.f;
	float2 closest_cell;
	for (int x = -1; x < 2; ++x)
	{
		for (int y = -1; y < 2; ++y)
		{
			float2 offset = float2(x, y);
			float2 cell_id = cell_index + offset;
			float2 point_pos = offset + voronoi_cell_offset(cell_id) * max_offset;
			float2 center_vec = point_pos - cell_pos;

			float l_center = length(center_vec);
			if (l_center < l_center_min)
			{
				l_center_min = l_center;
				closest_cell_id = cell_id;
				closest_cell = point_pos;
				closest_center_vec = center_vec;
			}
		}
	}
	{
		for (int x = -1; x < 2; ++x)
		{
			for (int y = -1; y < 2; ++y)
			{
				float2 offset = float2(x, y);
				float2 cell_id = cell_index + offset;
				float2 point_pos = offset + voronoi_cell_offset(cell_id) * max_offset;
				float2 center_vec = point_pos - cell_pos;

				float2 border_vec = (point_pos + closest_cell) * 0.5f;
				float2 normal_vec = normalize(closest_cell - border_vec);
				float edge_dist = abs(dot(normal_vec, cell_pos - border_vec));
				float dir_distance = edge_dist / max(dot(normal_vec, -dir), 0.0001f);

				closest_distance = min(closest_distance, dir_distance);
			}
		}
	}
}

float2 jump(float slide_time, float jump_time, float stime)
{
	float total_time = slide_time + jump_time;
	float cycle_pos = stime - floor(stime / total_time) * total_time;
	if (cycle_pos < slide_time)
	{
		return float2(cycle_pos / slide_time, 0.f);
	}
	else
	{
		float jump_cycle = (cycle_pos - slide_time) / jump_time;
		float x = 1.f - jump_cycle;
		float y = 4 * (jump_cycle - jump_cycle * jump_cycle);
		return float2(x, y);
	}
}

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
	float bounding = sdPlaneFast(geometry.pos - float3(0.f, 2.f, 0.f), geometry.dir, float3(0.f, 1.f, 0.f));

	float tree = 1e30, leafes = 1e30;
	float eye = 1e30, pupil = 1e30;
	float2 cell_index = float2(0.f, 0.f);
	float noise_val = 0.f;

	if (bounding < 0.1f)
	{
		float3 pos = geometry.pos;
		pos.z -= stime / 10.f * 0.4f;

		float tree_distance = 2.2f;
		float closest_distance;
		float2 cell_pos;
		voronoi(pos.xz / tree_distance, normalize(geometry.dir.xz), 0.3f, cell_index, cell_pos, closest_distance);
		noise_val = sin(cell_index.x * 356.12f + cell_index.y + 82.6f) * 0.5f + 0.5f;

		float2 jump_offset = jump(10.f, 1.f, stime + noise_val * 10.f) / tree_distance;
		cell_pos.y -= jump_offset.x * 0.4f - 0.05f;

		float3 tree_pos = float3(cell_pos * tree_distance, pos.y - jump_offset.y).xzy;
		cell_pos = opRotate(cell_pos, noise_val);
		float3 tree_pos_rotated = float3(cell_pos * tree_distance, pos.y - jump_offset.y).xzy;

		sdTree(tree_pos_rotated, tree, leafes, noise_val);
		tree_pos.x = abs(tree_pos.x);
		eye = sdSphere(tree_pos - float3(0.2f, 1.f, -0.5f), 0.12f);
		pupil = sdSphere(tree_pos - float3(0.2f, 1.f, -0.59f), 0.05f);

		tree = min(tree, closest_distance * tree_distance + 0.1f);
		leafes = min(leafes, closest_distance * tree_distance + 0.1f);
	}

	float ground_plane = sdPlaneFast(geometry.pos, geometry.dir, float3(0.f, 1.f, 0.f));

	if (geometry_step)
	{
		if (bounding >= 0.1f)
		{
			OBJECT(bounding);
		}
		OBJECT(tree);
		OBJECT(leafes);
		OBJECT(eye);
		OBJECT(pupil);
		OBJECT(ground_plane);
	}
	else
	{
		if (MATERIAL(tree))
		{
			material_output.diffuse_color.rgb = float3(0.5f, 0.25f, 0.1f);
			material_output.specular_color.rgb = 0.15f;
		}
		else if (MATERIAL(leafes))
		{
			float3 green1 = float3(0.2f, 0.9f, 0.2f);
			float3 green2 = float3(0.3f, 0.5f, 0.2f);
			float3 green = lerp(green1, green2, noise_val);

			material_output.diffuse_color.rgb = green;
			material_output.specular_color.rgb = 0.15f;
		}
		else if (MATERIAL(eye))
		{
			material_output.diffuse_color.rgb = float3(0.9f, 0.9f, 0.9f);
			material_output.specular_color.rgb = 0.15f;
		}
		else if (MATERIAL(pupil))
		{
			material_output.diffuse_color.rgb = float3(0.1f, 0.1f, 0.1f);
			material_output.specular_color.rgb = 0.15f;
		}
		else if (MATERIAL(ground_plane))
		{
			float turb = turbulence(geometry.pos);
			float3 brown1 = float3(218.f, 173.f, 136.f) / 255.f;
			float3 brown2 = float3(140.f, 90.f, 60.f) / 255.f;
			float3 brown = lerp(brown1, brown2, turb);
			material_output.diffuse_color.rgb = brown * 0.6f;
			material_output.specular_color.rgb = 0.05f;
		}
	}
}

void map_normal(GeometryInput geometry, inout NormalOutput output)
{
}

void map_light(GeometryInput input, inout LightOutput output[LIGHT_COUNT], inout float ambient_lighting_factor)
{
	output[0].used = true;
	output[0].pos = float4(-1.f, -1.f, 1.2f, 1.f);
	output[0].color = float3(1.f, 1.f, 1.f) * 1.3f;

	ambient_lighting_factor = 0.2f;
}

float3 map_background(float3 dir, uint iter_count)
{
	return sky_color(dir, stime);
}