#ifndef SDF_COMMON_HLSL
#define SDF_COMMON_HLSL

float3 HUEtoRGB(float H)
{
	float R = abs(H * 6 - 3) - 1;
	float G = 2 - abs(H * 6 - 2);
	float B = 2 - abs(H * 6 - 4);
	return saturate(float3(R, G, B));
}

float3 HSVtoRGB(float3 HSV)
{
	float3 RGB = HUEtoRGB(HSV.x);
	return ((RGB - 1) * HSV.y + 1) * HSV.z;
}

float RGBtoBrightness(float3 rgb)
{
	static const float3 brightness_fac = float3(0.2126f, 0.7152f, 0.0722f);
	return dot(rgb, brightness_fac);
}

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

float3 total_tile_color(float3 pos, float3 dir, float3 offset_right, float3 offset_bottom)
{
	float2 tile_pos1 = get_tile_impact(pos, dir);
	float4 color1 = tile_color_from_pos(tile_pos1);

	float2 tile_pos2 = get_tile_impact(pos + offset_right, dir);
	float4 color2 = tile_color_from_pos(tile_pos2);

	float2 tile_pos3 = get_tile_impact(pos + offset_bottom, dir);
	float4 color3 = tile_color_from_pos(tile_pos3);

	float2 tile_pos4 = get_tile_impact(pos + offset_bottom + offset_right, dir);
	float4 color4 = tile_color_from_pos(tile_pos4);

	float total_dist = color1.w + color2.w + color3.w + color4.w;
	float3 color = (color1.rgb * color1.a + color2.rgb * color2.a + color3.rgb * color3.a + color4.rgb * color4.a) / total_dist;
	return color.rgb;
}

void map_groundplane(GeometryInput geometry, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
	float floor1 = sdPlaneFast(geometry.pos, geometry.dir, float3(0.f, 1.f, 0.f));

	if (geometry_step)
	{
		OBJECT(floor1);
	}
	else
	{
		if (MATERIAL(floor1))
		{
			float3 offset_right = geometry.right_ray_offset * geometry.camera_distance;
			float3 offset_bottom = geometry.bottom_ray_offset * geometry.camera_distance;
			// ===========
			float3 color = total_tile_color(geometry.pos, geometry.dir.xyz, offset_right, offset_bottom);
			// ============
			material_output.diffuse_color = float4(color, 1.f);
			material_output.specular_color.rgb = 1.f;
		}
	}
}

float3 sky_color(float3 dir, float phase)
{
	dir.xz = opRotate(dir.xz, -phase * 0.025f);
	float noiseval = turbulence(dir * float3(1.f, 6.f, 1.f) * 2.5f);
	float3 color1 = float3(43.f, 164.f, 247.f) / 255.f;
	float3 color2 = float3(212.f, 224.f, 238.f) / 255.f;
	float3 sky_color = lerp(color1, color2, noiseval) * 1.2f;
	float3 horizon_color = float3(0.25f, 0.25f, 0.25f);
	return lerp(horizon_color, sky_color, saturate(dir.y * 8.f + 0.125f));
}

#endif