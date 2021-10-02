#include "noise.hlsl"
#include "sdf_scene.hlsl"


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
};


static const float dist_eps = 0.0001f;
static const float grad_eps = 0.0001f;
static const float max_dist = 3e30;
static const float max_dist_check = 1e30;
static const float3 lighting_dir = normalize(float3(-3.f, -1.f, 2.f));

static const float debug_ruler_scale = 0.1f;


float turbulence(float3 pos)
{
	return (snoise(pos) + snoise(pos * 2.f) / 2.f + snoise(pos * 4.f) / 4.f) * 4.f / 7.f;
}

float3 marble(float3 pos)
{
	float3 marble_dir = float3(3.f, 2.f, 1.f);
	float wave_pos = dot(marble_dir, pos) * 2.f + turbulence(pos) * 5.f;
	float sine_val = (1.f + sin(wave_pos)) * 0.5f;
	sine_val = pow(sine_val, 0.5f);
	return float3(0.556f, 0.478f, 0.541f) * sine_val;
}

float3 wood(float3 pos)
{
	static const float turbulence_scale = 0.125f;
	static const float rings = 12.f;

	float dist = sqrt(pos.x * pos.x + pos.y * pos.y) + turbulence_scale * turbulence(pos);
	float sine_val = 0.5f * abs(sin(2 * rings * dist * 3.14159));

	return float3(0.3125f + sine_val, 0.117f + sine_val, 0.117f);
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
	float distance_cut_plane = sdPlaneFast(p, dir, normalize(float3(0.f, 0.f, -1.f)));
	float2 distance_scene = map(p, dir, material_property);
	if (distance_cut_plane < distance_scene.x && false)
	{
		material_property = debug_plane_color(distance_scene.x);
		return float2(distance_cut_plane, 0.f);
	}
	else
	{
		return distance_scene;
	}
}

float3 grad(float3 p, float baseline)
{
	float3 unused;
	float d1 = map(p - float3(grad_eps, 0.f, 0.f), float3(0.f, 0.f, 0.f), unused).x - baseline;
	float d2 = map(p - float3(0.f, grad_eps, 0.f), float3(0.f, 0.f, 0.f), unused).x - baseline;
	float d3 = map(p - float3(0.f, 0.f, grad_eps), float3(0.f, 0.f, 0.f), unused).x - baseline;
	return normalize(float3(d1, d2, d3));
}

float4 colorize(float3 pos, float3 dir, float scene_distance, float material_id, float3 material_property)
{
	float3 col; // the output color

	// now select the material id
	if (material_id == 0.f) // 0 = debug plane
	{
		col = material_property;
	}
	else if (material_id == 1.f) // 1 = solid color
	{
		col = material_property;
	}
	else // all other colors are with shading now
	{
		float3 diffuse_color = float3(0.5f, 0.5f, 0.5f);
		if (material_id == 2.f) // 2 = solid color with shading
		{
			diffuse_color = material_property;
		}
		else if (material_id == 3.f) // 3 = marble
		{
			diffuse_color = marble(material_property);
		}
		else if (material_id == 4.f) // 4 = wood
		{
			diffuse_color = wood(material_property);
		}

		float3 normal = grad(pos, scene_distance);
		float diffuse_shading = clamp(dot(normal, lighting_dir), 0.05f, 1.f);
		float3 specular_ref = reflect(lighting_dir, normal);
		float specular_shading = pow(saturate(dot(specular_ref, -dir)), 12.f);
		float3 specular_color = float3(1.f, 1.f, 1.f);

		col = diffuse_color * diffuse_shading + specular_color * specular_shading;
	}
	return float4(col, 1.f);
}

void ps_main(ps_input input, out ps_output output)
{
	float3 dir = normalize(front_vec + input.screenpos.x * right_vec + input.screenpos.y * top_vec);

	float3 pos = eye;
	float4 col = float4(0.1f, 0.1f, 0.f, 1.f);
	for (uint iter = 0; iter < 100; ++iter)
	{
		float3 material_property;
		float2 scene_distance = map_debug(pos, dir, material_property);
		if (scene_distance.x < dist_eps)
		{
			col = colorize(pos, dir, scene_distance.x, scene_distance.y, material_property);
			break;
		}
		else if (scene_distance.x > max_dist_check)
		{
			break;
		}
		pos += dir * scene_distance.x;
	}

	output.color = col;
};