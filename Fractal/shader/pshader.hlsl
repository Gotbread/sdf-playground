#include "noise.hlsl"


struct ps_input
{
	float4 pos : SV_POSITION;
	float2 screenpos : SCREENPOS;
};

struct ps_output
{
	float4 color : SV_TARGET;
};

cbuffer camera
{
	float3 eye;
	float3 front_vec;
	float3 right_vec;
	float3 top_vec;
	
	float3 debug_plane_point;
	float3 debug_plane_normal;

	float _unused;
	float stime;
	float free_param;
};

// to allow use of the stime constant
#include "sdf_scene.hlsl"


static const float dist_eps = 0.0001f;    // how close to the object before terminating
static const float grad_eps = 0.0001f;    // how far to move when computing the gradient
static const float shadow_eps = 0.0003f;   // how far to step along the light ray when looking for occluders
static const float max_dist_check = 1e30; // maximum practical number

static const float3 lighting_dir = normalize(float3(-1.f, -2.f, 1.5f));
static const float ambient_lighting_factor = 0.25f;

static const float debug_ruler_scale = 0.01f;


float3 marble(float3 pos, float3 marble_color)
{
	float3 marble_dir = float3(3.f, 2.f, 1.f);
	float wave_pos = dot(marble_dir, pos) * 2.f + turbulence(pos) * 5.f;
	float sine_val = (1.f + sin(wave_pos)) * 0.5f;
	sine_val = pow(sine_val, 0.5f);
	return marble_color * sine_val;
}

float3 wood(float3 pos)
{
	static const float turbulence_scale = 0.125f;
	static const float rings = 12.f;

	float dist = sqrt(pos.x * pos.x + pos.y * pos.y) + turbulence_scale * turbulence(pos);
	float sine_val = 0.5f * abs(sin(2 * rings * dist * 3.14159));

	return float3(0.3125f + sine_val, 0.117f + sine_val, 0.117f);
}

float3 fire(float3 pos, float threshold)
{
	float turb = turbulence(pos) + 0.35f;
	turb = turb > threshold ? turb : 0.f;
	return float3(5.f, 2.f, 1.f) * turb;
}

float3 debug_plane_color(float scene_distance)
{
	float int_steps;
	float frac_steps = abs(modf(scene_distance / debug_ruler_scale, int_steps)) * 1.2f;
	float band_steps = modf(int_steps / 5.f, int_steps);

	float3 band_color = band_steps > 0.7f ? float3(1.f, 0.25f, 0.25f) : float3(0.75f, 0.75f, 1.f);
	frac_steps = scene_distance < 5.f ? frac_steps : 0.5f;
	float3 col = frac_steps < 1.f ? frac_steps * frac_steps * float3(1.f, 1.f, 1.f) : band_color;
	col.g = scene_distance < 0.f ? (scene_distance > -0.01f ? 1.f : 0.f) : col.g;
	return col;
}

float2 map_debug(float3 p, float3 dir, out float3 material_property)
{
	float distance_cut_plane = sdPlaneFast(p - debug_plane_point, dir, debug_plane_normal);
	float2 distance_scene = map(float4(p, 1.f), dir, material_property);
	if (dot(debug_plane_normal, debug_plane_normal) > 0.5f && distance_cut_plane < distance_scene.x)
	{
		material_property = debug_plane_color(distance_scene.x);
		return float2(distance_cut_plane, 0.f);
	}
	else
	{
		return distance_scene;
	}
}

float3 grad(float3 p, float baseline, float transparency)
{
	float3 unused;
	float d1 = map(float4(p - float3(grad_eps, 0.f, 0.f), transparency), float3(0.f, 0.f, 0.f), unused).x - baseline;
	float d2 = map(float4(p - float3(0.f, grad_eps, 0.f), transparency), float3(0.f, 0.f, 0.f), unused).x - baseline;
	float d3 = map(float4(p - float3(0.f, 0.f, grad_eps), transparency), float3(0.f, 0.f, 0.f), unused).x - baseline;
	return normalize(float3(d1, d2, d3));
}

// true if it hit something
// hit_info.x = material_id
// hit_info.y = iter count
// hit_info.z = scene distance
// hit_info.w = total distance
bool raymarch_scene_transparent(inout float3 pos, float3 dir, float max_dist, out float4 hit_info, out float3 material_property)
{
	float total_dist = 0.f;
	for (uint iter = 0; iter < 100; ++iter)
	{
		float2 scene_distance = map_debug(pos, dir, material_property);
		total_dist += scene_distance.x;
		if (scene_distance.x < dist_eps)
		{
			hit_info.x = scene_distance.y;
			hit_info.y = (float)iter;
			hit_info.z = scene_distance.x;
			hit_info.w = total_dist;
			return true;
		}
		else if (total_dist > max_dist)
		{
			return false;
		}
		pos += dir * scene_distance.x;
	}
	return false;
}

// true if it hit something
// hit_info.x = material_id
// hit_info.y = iter count
// hit_info.z = scene distance
// hit_info.w = total distance
bool raymarch_scene_opaque(inout float3 pos, float3 dir, float max_dist, out float4 hit_info, out float3 material_property)
{
	float total_dist = 0.f;
	for (uint iter = 0; iter < 100; ++iter)
	{
		float2 scene_distance = map(float4(pos, 0.f), dir, material_property);
		total_dist += scene_distance.x;
		if (scene_distance.x < dist_eps)
		{
			hit_info.x = scene_distance.y;
			hit_info.y = (float)iter;
			hit_info.z = scene_distance.x;
			hit_info.w = total_dist;
			return true;
		}
		else if (total_dist > max_dist)
		{
			return false;
		}
		pos += dir * scene_distance.x;
	}
	return false;
}

// tests if we can reach a target
// scene_rel_distance = how close we ever came to other scene objects
// relative to the distance traveled. if this value is close to one, we were
// mostly unobstructed
bool raymarch_scene_obstruction(float3 pos, float3 dir, float max_dist, out float scene_rel_distance)
{
	scene_rel_distance = 1.f;
	float total_dist = 0.f;
	for (uint iter = 0; iter < 100; ++iter)
	{
		float3 material_property;
		float2 scene_distance = map(float4(pos, 0.f), dir, material_property);
		total_dist += scene_distance.x;
		scene_rel_distance = min(scene_rel_distance, scene_distance.x / total_dist);
		if (scene_distance.x < dist_eps)
		{
			return true;
		}
		else if (total_dist > max_dist)
		{
			return false;
		}
		pos += dir * scene_distance.x;
	}
	return true;
}

float4 colorize(float3 pos, float3 dir, float scene_distance, float iter_count, float material_id, float3 material_property)
{
	float3 col = float3(0.1f, 0.1f, 0.f); // the output color
	float3 extra_color = float3(0.f, 0.f, 0.f);

	if (material_id == 100.f) // 100 = fire. if we hit fire, continue with the marching process until we hit something else
	{
		// add the fire color
		float3 normal = grad(pos, scene_distance, 1.f);

		float fadeout = saturate(dot(dir, normal));
		extra_color = fire(material_property, 1.f - fadeout);
		
		// continue
		float4 hit_info;
		if (raymarch_scene_opaque(pos, dir, max_dist_check, hit_info, material_property))
		{
			scene_distance = hit_info.z;
			iter_count += hit_info.y;
			material_id = hit_info.x;
		}
	}

	// now select the material id
	if (material_id == 0.f) // 0 = debug plane
	{
		col = material_property;
	}
	else if (material_id == 1.f) // 1 = iter count
	{
		col = iter_count / 100.f;
	}
	else if (material_id == 2.f) // 2 = solid color
	{
		col = material_property;
	}
	else // all other colors are with shading now
	{
		float3 diffuse_color = float3(0.5f, 0.5f, 0.5f);
		if (material_id == 3.f) // 3 = solid color with shading
		{
			diffuse_color = material_property;
		}
		else if (material_id == 4.f) // 4 = marble
		{
			diffuse_color = marble(material_property, float3(0.556f, 0.478f, 0.541f));
		}
		else if (material_id == 5.f) // 5 = white marble
		{
			diffuse_color = marble(material_property, float3(0.7f, 0.7f, 0.7f));
		}
		else if (material_id == 6.f) // 6 = wood
		{
			diffuse_color = wood(material_property);
		}

		float3 normal = grad(pos, scene_distance, 0.f);
		float diffuse_shading = saturate(dot(normal, lighting_dir));
		float3 specular_ref = reflect(lighting_dir, normal);
		float specular_shading = pow(saturate(dot(specular_ref, -dir)), 12.f);
		float3 specular_color = float3(1.f, 1.f, 1.f);

		float scene_rel_distance;
		bool obstructed = raymarch_scene_obstruction(pos - normal * shadow_eps, -lighting_dir, 100.f, scene_rel_distance);
		if (obstructed)
		{
			diffuse_shading = 0.f;
			specular_shading = 0.f;
		}

		col = diffuse_color * (diffuse_shading + ambient_lighting_factor) + specular_color * specular_shading;
	}
	return float4(col + extra_color, 1.f);
}

void ps_main(ps_input input, out ps_output output)
{
	// calculate main ray
	float3 dir = normalize(front_vec + input.screenpos.x * right_vec + input.screenpos.y * top_vec);

	// march it
	float3 pos = eye;
	float4 col = float4(0.1f, 0.1f, 0.f, 1.f);
	float4 hit_info;
	float3 material_property;
	if (raymarch_scene_transparent(pos, dir, max_dist_check, hit_info, material_property))
	{
		col = colorize(pos, dir, hit_info.z, hit_info.y, hit_info.x, material_property);
	}

	output.color = col;

	//float x = input.screenpos.x * 0.5f + 0.5f;
	//float greyscale = floor(x * 10.f) / 9.f;
	//output.color = greyscale;
}