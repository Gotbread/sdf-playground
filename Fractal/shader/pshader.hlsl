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
static const float3 lighting_dir = normalize(float3(-3.f, -1.f, 2.f));

static const float debug_ruler_scale = 0.2f;


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

float3 debug_plane_color(float scene_distance)
{
	float int_steps;
	float frac_steps = abs(modf(scene_distance / debug_ruler_scale, int_steps)) * 1.2f;
	float band_steps = modf(int_steps / 5.f, int_steps);

	float3 band_color = band_steps > 0.7f ? float3(1.f, 0.25f, 0.25f) : float3(0.75f, 0.75f, 1.f);
	float3 col = frac_steps < 1.f ? frac_steps * frac_steps * float3(1.f, 1.f, 1.f) : band_color;
	col.g = scene_distance < 0.f ? (scene_distance > -0.01f ? 1.f : 0.f) : col.g;
	return col;
}


float map_debug(float3 p, out bool color_distance)
{
	float distance_cut_plane = -p.z;
	float distance_scene = map(p);
	if (distance_cut_plane < distance_scene)
	{
		color_distance = true;
		return distance_cut_plane;
	}
	else
	{
		color_distance = false;
		return distance_scene;
	}
}

float3 grad(float3 p, float baseline)
{
	float d1 = map(p - float3(grad_eps, 0.f, 0.f)) - baseline;
	float d2 = map(p - float3(0.f, grad_eps, 0.f)) - baseline;
	float d3 = map(p - float3(0.f, 0.f, grad_eps)) - baseline;
	return normalize(float3(d1, d2, d3));
}

void ps_main(ps_input input, out ps_output output)
{
	float3 dir = normalize(front_vec + input.screenpos.x * right_vec + input.screenpos.y * top_vec);

	float3 pos = eye;
	float3 col = float3(0.1f, 0.1f, 0.f);
	bool color_distance = false;
	for (uint iter = 0; iter < 100; ++iter)
	{
		float d = map_debug(pos, color_distance);
		if (d < dist_eps)
		{
			if (color_distance)
			{
				float scene_distance = map(pos);
				col = debug_plane_color(scene_distance);
			}
			else
			{
				float3 normal = grad(pos, d);
				float diffuse_shading = clamp(dot(normal, lighting_dir), 0.f, 1.f);
				float3 specular_ref = reflect(lighting_dir, normal);
				float specular_shading = pow(saturate(dot(specular_ref, -dir)), 12.f);
				float3 marble_color = marble(pos);
				float3 specular_color = float3(1.f, 1.f, 1.f);

				col = marble_color * diffuse_shading + specular_color * specular_shading;
			}
			break;
		}
		pos += dir * d;
	}

	output.color = float4(col, 1.f);
};