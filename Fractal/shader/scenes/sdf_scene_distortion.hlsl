#include "sdf_primitives.hlsl"
#include "sdf_materials.hlsl"
#include "sdf_ops.hlsl"
#include "sdf_common.hlsl"

// obj: the objects distance
// val: value of the function
// lip: lipschitz constant
// h: maximum height of the distortion
float distort(float obj, float val, float lip, float h)
{
	float actual_distance = (obj - val) / sqrt(1 + lip * lip);
	return lerp(actual_distance, obj - h, saturate(obj / h - 1.f));
}

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
	map_groundplane(geometry, material_output, geometry_step, output_scene_distance);

	float3 box_pos = geometry.pos - float3(0.f, 1.5f, 0.f);
	float scaled_pos = box_pos.y * 2.5f - 1.25f;
	float index = scaled_pos - floor(scaled_pos);
	float offset = step(0.5f, index);
	float val_x = 1.f - pow(saturate(sin((box_pos.x + offset * 0.2f) * pi * 5.f)), 10.f);
	float val_y = 1.f - pow(abs(sin(box_pos.y * pi * 5.f)), 10.f);
	float n = turbulence(box_pos * 7.5f);
	float val = min(val_x, val_y);
	val = lerp(val * 0.8f, val, n);
	float height = 0.025f;
	float lip = 2.f;
	float box = sdBox(box_pos, float3(1.f, 1.f, 0.1f));
	box = distort(box, val * height, lip * height, height);

	if (geometry_step)
	{
		OBJECT(box);
	}
	else
	{
		if ((box - 0.1f) < dist_eps)
		{
			float3 color_wall1 = float3(0.8f, 0.2f, 0.2f);
			float3 color_wall2 = float3(0.5f, 0.1f, 0.1f);
			float3 color_gap = float3(0.5f, 0.5f, 0.5f);
			float3 color_wall = lerp(color_wall2, color_wall1, n);
			float3 color = val < 0.15f ? color_gap : color_wall;
			material_output.diffuse_color.rgb = color;
			material_output.specular_color.rgb = 0.125f;
			material_output.material_id = MATERIAL_ITER;
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