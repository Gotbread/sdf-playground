#include "sdf_primitives.hlsl"


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

// params:
// pos.xyz: 3D position in the scene
// pos.w: one when rendering with transparent objects, zero without
// 
// dir: input normal. normalized to 1 for normal passes, zero for gradient-only passes
// 
// return value:
// x: scene distance
// y: material ID
//
// material_property:
// extra vector, meaning depends on material
float2 map(float4 pos, float3 dir, out float3 material_property)
{
	// testing
	//float sphere = sdSphere(pos.xyz - float3(0.f, 1.f, 0.f), 0.5f);
	/*float box1 = sdBox(pos.xyz - float3(+1.f, 3.f, +1.f), float3(2.f, 2.f, 2.f));
	float box2 = sdBox(pos.xyz - float3(-1.f, 5.f, -1.f), float3(2.f, 2.f, 2.f));
	float obj = length(float2(box1, box2)) - 0.2f;*/

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

	float3 spring_pos = pos.xyz;
	spring_pos.y -= (y_top + y_bottom) * 0.5f + 0.1f;
	spring_length = y_top - y_bottom;

	spring_pos.xy = float2(spring_pos.x * spring_c - spring_pos.y * spring_s, spring_pos.x * spring_s + spring_pos.y * spring_c);

	float obj = sdSpiral(spring_pos + float3(0.f, spring_length * 0.5f, 0.f), 1.f, spring_length, 0.1f, 0.f, 4.5f * tau) * 0.98f;

	pos.x += x;

	// floor
	float floor1 = sdPlaneFast(pos.xyz, dir, float3(0.f, 1.f, 0.f));

	// select
	if (obj < floor1)
	{
		material_property = float3(0.5f, 0.5f, 0.5f);
		return float2(obj, 3.f);
	}
	else
	{
		float2 tile_pos = floor(pos.xz);
		float tile_parity = round(frac((tile_pos.x + tile_pos.y) * 0.5f + 0.25f));
		float3 tile_color = tile_parity > 0.5f ? float3(0.3f, 0.3f, 0.3f) : float3(0.9f, 0.9f, 0.9f);
		float3 neutral_color = float3(0.6f, 0.6f, 0.6f);
		float tile_lod = saturate((length(pos.xyz - eye) - 30.f) / 40.f);
		material_property = lerp(tile_color, neutral_color, tile_lod);
		return float2(floor1, 3.f);
	}
}




