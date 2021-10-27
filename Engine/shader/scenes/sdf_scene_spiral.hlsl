#include "sdf_primitives.hlsl"
#include "sdf_ops.hlsl"
#include "sdf_common.hlsl"

// occupies the negative xyz octant
float sdCorner(float3 pos)
{
	return length(max(pos, 0));
}

float sdSpiral(float3 pos, float r1, float h, float r2, float angle_start, float angle_end)
{
	// todo: add lipschitz continuity
	float k = h / ((angle_end - angle_start) * r1);
	float height_per_rotation = tau * h / (angle_end - angle_start);
	float rel_height = height_per_rotation * atan2(pos.z, pos.x) / tau;
	float start_height = height_per_rotation * angle_start / tau;

	float offset_pos_y = pos.y;
	float height_diff = clamp(offset_pos_y, height_per_rotation * 0.5f, h - height_per_rotation * 0.5f);
	height_diff -= rel_height - start_height;
	offset_pos_y -= rel_height - start_height;
	float closest_height = round(height_diff / height_per_rotation) * height_per_rotation;

	float axial_dist = closest_height - offset_pos_y;

	float radial_length = length(pos.xz);
	float radial_dist = radial_length - r1;

	float2 ab = float2(radial_dist, axial_dist);
	float body_length = length(ab) - r2; // TODO: adjust

	float3 cap1 = float3(r1 * cos(angle_start), 0.f, r1 * sin(angle_start));
	float3 cap2 = float3(r1 * cos(angle_end), h, r1 * sin(angle_end));

	return min(body_length, min(length(pos - cap1) - r2, length(pos - cap2) - r2));
}

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
	float speed = 1.5f;
	float total_x = stime * speed;

	float width = 4.f;
	float height = 6.f;
	float spring_length = 3.f;
	float pen = 2.f;

	float arc_pos = frac(total_x / width);
	float x = arc_pos * width;
	float y = arc_pos * (1.f - arc_pos) * 4.f * height;

	float y_top = y - pen + spring_length;
	float y_bottom = max(y - pen, 0);

	float dydx = (1 - 2 * arc_pos) * 4.f * height / width;
	float spring_angle = -atan(dydx) - pi * 0.5f;

	float spring_s = sin(spring_angle), spring_c = cos(spring_angle);

	float3 spring_pos = geometry.pos.xyz;
	spring_pos.y -= (y_top + y_bottom) * 0.5f + 0.1f;
	spring_length = y_top - y_bottom;

	spring_pos.xy = float2(spring_pos.x * spring_c - spring_pos.y * spring_s, spring_pos.x * spring_s + spring_pos.y * spring_c);

	float obj = sdSpiral(spring_pos + float3(0.f, spring_length * 0.5f, 0.f), 1.f, spring_length, 0.1f, 0.f, 4.5f * tau) * 0.98f;

	geometry.pos.x += x;

	map_groundplane(geometry, material_output, geometry_step, output_scene_distance);

	if (geometry_step)
	{
		OBJECT(obj);
	}
	else
	{
		if (MATERIAL(obj))
		{
			material_output.diffuse_color.rgb = 0.5f;
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