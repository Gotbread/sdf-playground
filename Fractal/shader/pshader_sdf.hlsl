#include "sdf_primitives.hlsl"
#include "sdf_ops.hlsl"
#include "sdf_materials.hlsl"
#include "user_variables.hlsl"
#include "noise.hlsl"
#include "math_constants.hlsl"

struct ps_input
{
	float4 pos : SV_POSITION;
	float2 screenpos : SCREENPOS;
};

struct ps_output
{
	float4 color : SV_TARGET;
};

cbuffer camera : register(b0)
{
	float3 eye;
	float3 front_vec;
	float3 right_vec;
	float3 top_vec;
	
	float3 debug_plane_point;
	float3 debug_plane_normal;

	float _unused;
	float stime;
	float debug_ruler_scale;
};

struct GeometryInput
{
	// the position in 3D worldspace
	float3 pos;

	// xyz: the direction of the ray, if directional
	float3 dir;

	// if true, the ray_dir is set and can be used for accelerating the marching
	bool has_dir;

	// if true, we are inside an object and work with negative distance values
	// if false, we are outside an object and work with positive distance values (default case)
	bool is_inside;

	// where the last point of transparency was, in order to remove this object
	float3 last_transparent_pos;

	// if last_transparent_pos is valid
	bool has_transparent;

	// the euclidean distance from the eye
	float camera_distance;

	// points to the pixel right of this one, per unit of eye distance
	float3 right_ray_offset;

	// points to the pixel below this one, per unit of eye distance
	float3 bottom_ray_offset;
};

struct NormalOutput
{
	// the spacing to use for sampling of the normal vector
	// larger than usual values lead to rounded corners
	// preloaded with the default one
	float normal_sample_dist;

	// the user generated normal
	float3 normal;

	// if true, uses the user generated normal instead of computing it by sampling
	// to increase speed. default false
	bool use_normal;
};

struct MaterialInput
{
	// the position in 3D worldspace
	float3 pos;

	// the normal of the object
	float3 obj_normal;

	// how many iterations we did to get here
	uint iteration_count;

	// the euclidean distance from the eye
	float camera_distance;

	// the last distance to the scene
	float scene_distance;

	// points to the pixel right of this one, per unit of eye distance
	float3 right_ray_offset;

	// points to the pixel below this one, per unit of eye distance
	float3 bottom_ray_offset;
};

struct MaterialOutput
{
	// which material to use
	uint material_id;

	// for volumetric materials. xyz is the space position, w could be time
	float4 material_position;

	// some extra material properties
	float4 material_properties;

	// rgb: normal color
	// a: transparency
	float4 diffuse_color;

	// rgb: specular color
	// a: specular power
	float4 specular_color;

	// glows on its own
	float3 emissive_color;

	// how the color reflected gets modulated. should be <1 per component
	// if zero, no reflection is calculated
	float3 reflection_color;

	// how the refraction gets modulated. should be <1 per component
	float3 refraction_color;

	// index of refraction of this medium
	float optical_index;

	// how quickly the light will fall off
	float optical_density;

	// xyz: output normal, if any
	// w: blend factor between the old normal and this. 1 means use this, 0 means use existing one
	float4 normal;
};

struct LightInput
{
	// the position in 3D worldspace
	float3 pos;

	// the euclidean distance from the eye
	float camera_distance;
};

struct LightOutput
{
	// whether this light source is used. preloaded with false
	bool used;

	// where is the source
	float3 pos;

	// what color does it have
	float3 color;

	// how fast does it fall off?
	float falloff;
};

static const float dist_eps = 0.0001f;    // how close to the object before terminating
static const float grad_eps = 0.0001f;    // how far to move when computing the gradient
static const float reflect_eps = 0.001f;  // how far to move the ray along after a reflection
static const float shadow_eps = 0.0003f;   // how far to step along the light ray when looking for occluders
static const float max_dist_check = 1e30; // maximum practical number

static const float3 lighting_dir = normalize(float3(-1.f, -2.f, 1.5f));
static const float ambient_lighting_factor = 0.05f;

// include the scene here so it has access to all constants
//#include "sdf_scene.hlsl"

/*
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
		distance_scene = map(float4(p, 0.f), float3(0.f, 0.f, 0.f), material_property);
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
	float3 color_multiplier = float3(1.f, 1.f, 1.f);
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
	if (material_id == 50.f) // 50 = mirror
	{
		float3 normal = grad(pos, scene_distance, 1.f);

		pos -= normal * 0.01f;
		dir = reflect(dir, normal);
		color_multiplier = material_property;

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
	return float4(color_multiplier * (col + extra_color), 1.f);
}*/

/*
void ps_main(ps_input input, out ps_output output)
{
	// calculate main ray
	float3 dir = normalize(front_vec + input.screenpos.x * right_vec + input.screenpos.y * top_vec);
	float3 right_pix_vec = ddx(input.screenpos.x) * right_vec;
	float3 down_pix_vec = ddy(input.screenpos.y) * top_vec;

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
}*/

struct Ray
{
	float3 pos;
	float3 dir;
	float3 contribution;
	float inside_sign;
	uint depth;
};

// must be bigger than bounce count
#define INVALID_DEPTH 1000

#define BOUNCE_COUNT 8
#define ITER_COUNT 100
#define RAY_COUNT 3

#define MATERIAL_NONE 0
#define MATERIAL_ITER 1
#define MATERIAL_NORMAL 2
#define MATERIAL_WOOD 20

float map_geometry(GeometryInput input)
{
	// lower background
	float3 background1_pos = input.pos - float3(0.f, -5.f, 0.f);
	background1_pos.xz = opRepInf(background1_pos.xz, 3.f);
	float background1_sphere = sdSphere(background1_pos, 1.f);
	float background1_box = sdBox(background1_pos, 1.f);
	float background1 = lerp(background1_sphere, background1_box, 0.65) - 0.1;

	// upper background
	float3 background2_pos = input.pos - float3(0.f, +5.f, 0.f);
	background2_pos.xz = opRepInf(background2_pos.xz, 10.f);
	float background2_sphere = sdSphere(background2_pos, 1.f);
	float background2_box = sdBox(background2_pos, 1.f);
	float background2 = lerp(background2_sphere, background2_box, 0.65) - 0.1;

	// lense
	float3 lance_pos = abs(input.pos);
	lance_pos.z -= 5.1f;
	float lance1 = sdSphere(lance_pos, 5.f);
	float lance2 = sdSphere(input.pos, 2.f);
	float lance = max(-lance1, lance2);

	// sphere
	float x = VAR_xpos(min = -4, max = 4, step = 0.1);
	float y = VAR_ypos(min = -4, max = 4, step = 0.1);
	float z = VAR_zpos(min = 0, max = 25, step = 0.1);
	float3 sphere_pos = input.pos - float3(x, y, z);
	float sphere = sdSphere(sphere_pos, 2.f);

	// mirror
	float3 mirror_position = input.pos - float3(0.f, 0.f, -5.f);
	mirror_position.xz = opRotate(mirror_position.xz, 1.2f);
	float mirror = sdBox(mirror_position, float3(1.f, 2.f, 0.1f));
	float mirror_frame = sdBox(mirror_position, float3(1.1f, 2.1f, 0.08f));

	float background = min(background1, background2);
	return min(min(min(min(lance, sphere), mirror), mirror_frame), background);
}

void map_normal(GeometryInput input, inout NormalOutput output)
{
}

void map_material(MaterialInput input, inout MaterialOutput output)
{
	// lower background
	float3 background1_pos = input.pos - float3(0.f, -5.f, 0.f);
	background1_pos.xz = opRepInf(background1_pos.xz, 3.f);
	float2 cell_index = (input.pos.xz - background1_pos.xz) / 3.f;
	float background1_sphere = sdSphere(background1_pos, 1.f);
	float background1_box = sdBox(background1_pos, 1.f);
	float background1 = lerp(background1_sphere, background1_box, 0.65) - 0.1;

	// upper background
	float3 background2_pos = input.pos - float3(0.f, +5.f, 0.f);
	background2_pos.xz = opRepInf(background2_pos.xz, 10.f);
	float background2_sphere = sdSphere(background2_pos, 1.f);
	float background2_box = sdBox(background2_pos, 1.f);
	float background2 = lerp(background2_sphere, background2_box, 0.65) - 0.1;

	// lense
	float3 lance_pos = abs(input.pos);
	lance_pos.z -= 5.1f;
	float lance1 = sdSphere(lance_pos, 5.f);
	float lance2 = sdSphere(input.pos, 2.f);
	float lance = max(-lance1, lance2);

	// sphere
	float x = VAR_xpos(min = -4, max = 4, step = 0.1);
	float y = VAR_ypos(min = -4, max = 4, step = 0.1);
	float z = VAR_zpos(min = 0, max = 25, step = 0.1);
	float3 sphere_pos = input.pos - float3(x, y, z);
	float sphere = sdSphere(sphere_pos, 2.f);

	// mirror
	float3 mirror_position = input.pos - float3(0.f, 0.f, -5.f);
	mirror_position.xz = opRotate(mirror_position.xz, 1.2f);
	float mirror = sdBox(mirror_position, float3(1.f, 2.f, 0.1f));

	// mirror frame
	float mirror_frame = sdBox(mirror_position, float3(1.1f, 2.1f, 0.08f));


	if (abs(background1) < dist_eps)
	{
		//float2 cell_color = sin(cell_index * 0.3f) * 0.5f + 0.5f;
		float3 cell_color = cell_index.x < 0.01f ? float3(0.f, 1.f, 0.f) : float3(0.f, 0.f, 1.f);
		output.diffuse_color = float4(cell_color, 1.f);
		output.specular_color.rgb = 1.f;
		output.reflection_color = 0.5f;
	}
	else if (abs(background2) < dist_eps)
	{
		output.diffuse_color = float4(1.f, 0.5f, 0.f, 1.f);
		output.specular_color.rgb = 1.f;
		output.reflection_color = 0.5f;
	}
	else if (abs(lance) < dist_eps)
	{
		output.diffuse_color = float4(0.3f, 0.3f, 0.3f, 1.f);
		output.refraction_color = float3(0.9f, 0.9f, 0.9f);
	}
	else if (abs(sphere) < dist_eps)
	{
		output.diffuse_color = float4(0.8f, 0.2f, 0.2f, 1.f);
		output.emissive_color = float3(8.f, 0.f, 0.f);
		output.specular_color.rgb = 1.f;
		output.reflection_color = 0.25f;
		output.normal.xyz = input.obj_normal + snoise(input.pos * 60.f) * 0.1f;
		output.normal.a = 0.f;
	}
	else if (abs(mirror) < dist_eps)
	{
		output.diffuse_color = float4(0.1f, 0.1f, 0.1f, 1.f);
		float mix_ratio = VAR_mixing(min = 0, max = 1, step = 0.05);
		output.refraction_color = mix_ratio;
		output.reflection_color = 1.f - mix_ratio;
	}
	else if (abs(mirror_frame) < dist_eps)
	{
		//output.diffuse_color = float4(1.f, 0.2f, 0.2f, 1.f);
		output.material_position.xyz = mirror_position;
		output.material_id = MATERIAL_WOOD;
	}
}

void map_light(LightInput input, inout LightOutput output)
{
	output.used = true;
	output.pos = float3(0.f, 5.f, 0.f);
	output.color = float3(0.f, 0.f, 1.f);
	output.falloff = 0.f; // still not decided
}

float3 grad(GeometryInput geometry, float baseline, float sample_distance)
{
	float3 offset = float3(sample_distance, 0.f, 0.f);
	float3 pos = geometry.pos;

	geometry.pos = pos + offset.xyz;
	float d1 = map_geometry(geometry) - baseline;
	geometry.pos = pos + offset.zxy;
	float d2 = map_geometry(geometry) - baseline;
	geometry.pos = pos + offset.yzx;
	float d3 = map_geometry(geometry) - baseline;

	return normalize(float3(d1, d2, d3));
}

bool march_ray(inout GeometryInput geometry, float dist_max, float inside_sign, out uint iter, out float scene_distance)
{
	float3 start_pos = geometry.pos;
	// TODO fast stepping
	geometry.camera_distance = 0.f;
	float step_factor = 1.0f;
	float last_scene_distance = 0.f;
	float last_safe_camera_distance = 0.f;
	for (iter = 0; iter < ITER_COUNT; ++iter)
	{
		if (iter == 3)
		{
			step_factor = 1.5f;
		}

		geometry.pos = start_pos + geometry.dir * geometry.camera_distance;
		scene_distance = map_geometry(geometry) * inside_sign;
		// check for overstepping
		if (step_factor > 1.f && (last_scene_distance + scene_distance) < last_scene_distance * step_factor)
		{
			// go back and try slowly
			geometry.camera_distance = last_safe_camera_distance;
			step_factor = 1.f;
			continue;
		}
		last_scene_distance = scene_distance;

		// handle distance
		if (scene_distance < dist_eps)
		{
			return true;
		}
		else if (scene_distance > dist_max)
		{
			return false;
		}

		last_safe_camera_distance = geometry.camera_distance + scene_distance;
		geometry.camera_distance += scene_distance * step_factor;
	}
	return false;
}

uint find_next_ray(Ray rays[RAY_COUNT])
{
	uint ray_index = 0;
	for (uint index = 1; index < RAY_COUNT; ++index)
	{
		if (rays[index].depth < rays[ray_index].depth)
		{
			ray_index = index;
		}
	}
	return ray_index;
}

uint find_free_ray(Ray rays[RAY_COUNT])
{
	uint index;
	for (index = 0; index < RAY_COUNT; ++index)
	{
		if (rays[index].depth == INVALID_DEPTH)
		{
			break;
		}
	}
	return index;
}

void ps_main(ps_input input, out ps_output output)
{
	// calculate main ray
	float3 dir = normalize(front_vec + input.screenpos.x * right_vec + input.screenpos.y * top_vec);
	float3 right_ray_vec = ddx(input.screenpos.x) * right_vec;
	float3 bottom_ray_vec = ddy(input.screenpos.y) * top_vec;

	Ray rays[RAY_COUNT];
	for (uint index = 1; index < RAY_COUNT; ++index)
		rays[index].depth = INVALID_DEPTH;

	rays[0].pos = eye;
	rays[0].dir = dir;
	rays[0].contribution = float3(1.f, 1.f, 1.f);
	rays[0].inside_sign = 1.f;
	rays[0].depth = 0;
	uint ray_count = 1;

	output.color = float4(0.f, 0.f, 0.f, 0.f);
	for (uint bounce = 0; bounce < BOUNCE_COUNT; ++bounce)
	{
		uint ray_index = find_next_ray(rays);
		// find a valid ray
		if (rays[ray_index].depth == INVALID_DEPTH) // no more rays, abort
		{
			break;
		}

		uint current_ray_depth = rays[ray_index].depth; // save for later
		float3 ray_contribution = rays[ray_index].contribution; // save for later
		float inside_sign = rays[ray_index].inside_sign;

		rays[ray_index].depth = INVALID_DEPTH; // disable original ray
		--ray_count;

		// march geometry
		GeometryInput geometry_input;
		geometry_input.pos = rays[ray_index].pos;
		geometry_input.dir = rays[ray_index].dir;
		geometry_input.has_dir = false;
		geometry_input.is_inside = false;
		geometry_input.has_transparent = false;
		geometry_input.last_transparent_pos = float3(0.f, 0.f, 0.f);
		geometry_input.right_ray_offset = right_ray_vec;
		geometry_input.bottom_ray_offset = bottom_ray_vec;

		uint iter_count;
		float scene_distance;
		if (march_ray(geometry_input, 100.f, inside_sign, iter_count, scene_distance))
		{
			// calculate the normal, first pass
			NormalOutput normal_output;
			normal_output.use_normal = false;
			normal_output.normal = float3(0.f, 0.f, 0.f);
			normal_output.normal_sample_dist = grad_eps;

			map_normal(geometry_input, normal_output);
			if (!normal_output.use_normal)
			{
				normal_output.normal = grad(geometry_input, scene_distance * inside_sign, normal_output.normal_sample_dist);
			}

			// get the material
			MaterialInput material_input;
			material_input.pos = geometry_input.pos;
			material_input.obj_normal = normal_output.normal;
			material_input.iteration_count = iter_count;
			material_input.camera_distance = geometry_input.camera_distance;
			material_input.scene_distance = scene_distance;
			material_input.right_ray_offset = right_ray_vec;
			material_input.bottom_ray_offset = bottom_ray_vec;

			MaterialOutput material_output;
			material_output.material_id = 0;
			material_output.material_position = float4(geometry_input.pos, 0.f);
			material_output.material_properties = float4(0.f, 0.f, 0.f, 0.f);
			material_output.diffuse_color = float4(0.f, 0.f, 0.f, 1.f);
			material_output.specular_color = float4(0.f, 0.f, 0.f, 12.f);
			material_output.emissive_color = float3(0.f, 0.f, 0.f);
			material_output.reflection_color = float3(0.f, 0.f, 0.f); // no reflection
			material_output.refraction_color = float3(0.f, 0.f, 0.f); // no refraction
			material_output.optical_index = 1.4f;
			material_output.optical_density = 0.f;
			material_output.normal = float4(0.f, 0.f, 0.f, 0.f);

			map_material(material_input, material_output);
			
			// get the new normal
			float3 new_normal = lerp(normal_output.normal, material_output.normal.xyz, material_output.normal.w);

			// do we have reflection?
			if (any(material_output.reflection_color) && inside_sign > 0.f) // only if we are an outside ray
			{
				if (ray_count < RAY_COUNT)
				{
					uint new_ray_index = find_free_ray(rays);

					float3 ref_vec = reflect(geometry_input.dir, new_normal);
					// start a new ray

					rays[new_ray_index].pos = geometry_input.pos + ref_vec * reflect_eps;
					rays[new_ray_index].dir = ref_vec;
					rays[new_ray_index].contribution = material_output.reflection_color * ray_contribution;
					rays[new_ray_index].inside_sign = 1.f;
					rays[new_ray_index].depth = current_ray_depth + 3;
					++ray_count;
				}
			}

			// do we have refraction?
			if (any(material_output.refraction_color))
			{
				if (ray_count < RAY_COUNT)
				{
					uint new_ray_index = find_free_ray(rays);

					if (inside_sign > 0.f) // just entering the material
					{
						float3 ref_vec = refract(geometry_input.dir, new_normal, 1.f / material_output.optical_index);
						// start a new ray

						rays[new_ray_index].pos = geometry_input.pos + ref_vec * reflect_eps;
						rays[new_ray_index].dir = ref_vec;
						rays[new_ray_index].contribution = material_output.refraction_color * ray_contribution;
						rays[new_ray_index].inside_sign = -1.f;
						rays[new_ray_index].depth = current_ray_depth + 2;
					}
					else // leaving the material
					{
						float3 ref_vec = refract(geometry_input.dir, -new_normal, material_output.optical_index);
						// start a new ray

						rays[new_ray_index].pos = geometry_input.pos + ref_vec * reflect_eps;
						rays[new_ray_index].dir = ref_vec;
						rays[new_ray_index].contribution = material_output.refraction_color * ray_contribution;
						rays[new_ray_index].inside_sign = 1.f;
						rays[new_ray_index].depth = current_ray_depth + 2;
					}
					++ray_count;
				}
			}

			float3 color = float3(0.f, 0.f, 0.f);
			float3 material_color = float3(0.f, 0.f, 0.f);

			float3 lighting_dir = normalize(float3(-3.f, -1.f, 1.f));
			float light_dot = saturate(dot(-new_normal, lighting_dir));

			// handle material
			if (material_output.material_id == MATERIAL_WOOD)
			{
				material_color = wood(material_output.material_position.xyz);
			}

			// handle diffuse color
			float3 diffuse_color = material_output.diffuse_color.rgb * (light_dot + ambient_lighting_factor);

			float3 specular_ref = reflect(lighting_dir, new_normal);
			float specular_shading = pow(saturate(dot(specular_ref, -geometry_input.dir)), material_output.specular_color.a);

			// handle specular color
			float3 specular_color = material_output.specular_color.rgb * specular_shading;

			// handle shadow
			geometry_input.pos += new_normal * shadow_eps;
			//geometry_input.pos += float3(0.f, 0.1f, 0.0);;
			geometry_input.dir = -lighting_dir;
			uint iter_count_unused;
			float scene_distance_unused;
			bool obstructed = march_ray(geometry_input, 100.f, inside_sign, iter_count_unused, scene_distance_unused);
			if (obstructed)
			{
				diffuse_color = 0.f;
				specular_color = 0.f;
				material_color = 0.f;
			}

			color += diffuse_color;
			color += specular_color;
			color += material_color;

			// handle emissive color
			color += material_output.emissive_color.rgb;

			output.color.rgb += color * ray_contribution;
		}
		else
		{
			float3 background_color = float3(0.f, 0.25f, 0.f);
			output.color.rgb += background_color * ray_contribution;
		}
		// keep track of closest point relative to camera distance -> antialiasing
	}

	output.color.a = 1.f; // disable HDR for debugging
}