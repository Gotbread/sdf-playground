#include "sdf_materials.hlsl"
#include "sdf_structs.hlsl"
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

static const float dist_eps = 0.0001f;    // how close to the object before terminating
static const float grad_eps = 0.0001f;    // how far to move when computing the gradient
static const float reflect_eps = 0.001f;  // how far to move the ray along after a reflection
static const float refract_eps = 0.001f;  // how far to move the ray along after a refraction
static const float shadow_eps = 0.0003f;   // how far to step along the light ray when looking for occluders
static const float max_dist_check = 1e30; // maximum practical number

static const float3 lighting_dir = normalize(float3(-0.5f, -1.f, 1.75f));

/*

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

struct Ray
{
	float3 pos;
	float3 dir;
	float3 contribution;
	float inside_sign;
	uint depth;
};

// must be bigger than bounce count
#define INVALID_DEPTH 1000000

#define BOUNCE_COUNT 8
#define RAY_COUNT 3
#define ITER_COUNT 100
#define LIGHT_COUNT 8
#define RANGE 100.f

// numbers are somewhat arbitrary
#define MATERIAL_NONE 0            // no material. just use the diffuse color with lighting. default case
#define MATERIAL_PLAIN 1           // just use the diffuse color without lighting
#define MATERIAL_ITER 2            // shows the iteration count as a heat map
#define MATERIAL_NORMAL 3          // show the normal vector color coded
#define MATERIAL_DISTANCE_PLANE 4  // the distance plane
#define MATERIAL_WOOD 20           // wood. uses the material_position
#define MATERIAL_MARBLE_DARK 21    // dark marble. uses the material_position
#define MATERIAL_MARBLE_LIGHT 22   // light marble. uses the material position

// makros for convenience
#define OBJECT(distance) output_scene_distance = min(output_scene_distance, distance)
#define MATERIAL(distance) (abs(distance) < dist_eps)

#include "sdf_scene.hlsl"

float map_geometry(GeometryInput geometry, MarchingInput march)
{
	float output_scene_distance = 3e38;

	MaterialInput material_input = (MaterialInput)0;
	MaterialOutput material_output = (MaterialOutput)0;

	map(geometry, march, material_input, material_output, true, output_scene_distance);
	float distance_debug_plane = sdPlaneFast(geometry.pos - debug_plane_point, geometry.dir, debug_plane_normal);

	if (any(debug_plane_normal))
	{
		return min(output_scene_distance, distance_debug_plane);
	}
	else
	{
		return output_scene_distance;
	}
}

void map_material(GeometryInput geometry, MaterialInput material_input, inout MaterialOutput material_output)
{
	float output_scene_distance = 3e38;
	MarchingInput march = (MarchingInput)0;
	float distance_debug_plane = sdPlaneFast(geometry.pos - debug_plane_point, geometry.dir, debug_plane_normal);
	if (any(debug_plane_normal) && MATERIAL(distance_debug_plane))
	{
		MaterialInput material_input_dummy = (MaterialInput)0;
		MaterialOutput material_output_dummy = (MaterialOutput)0;

		geometry.dir.w = 0.f;
		map(geometry, march, material_input_dummy, material_output_dummy, true, output_scene_distance);

		material_output.material_id = MATERIAL_DISTANCE_PLANE;
		material_output.material_properties.x = output_scene_distance;
	}
	else
	{
		map(geometry, march, material_input, material_output, false, output_scene_distance);
	}
}

float3 grad(GeometryInput geometry, MarchingInput march, float baseline, float sample_distance)
{
	float3 offset = float3(sample_distance, 0.f, 0.f);
	float3 pos = geometry.pos;

	geometry.pos = pos + offset.xyz;
	float d1 = map_geometry(geometry, march) - baseline;
	geometry.pos = pos + offset.zxy;
	float d2 = map_geometry(geometry, march) - baseline;
	geometry.pos = pos + offset.yzx;
	float d3 = map_geometry(geometry, march) - baseline;

	return normalize(float3(d1, d2, d3));
}

bool march_ray(inout GeometryInput geometry, MarchingInput march, float dist_max, float inside_sign, out uint iter, out float scene_distance)
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

		geometry.pos = start_pos + geometry.dir.xyz * geometry.camera_distance;
		scene_distance = map_geometry(geometry, march) * inside_sign;
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
		if (geometry.camera_distance > dist_max)
		{
			return false;
		}
		else if (scene_distance < dist_eps)
		{
			return true;
		}

		last_safe_camera_distance = geometry.camera_distance + scene_distance;
		geometry.camera_distance = geometry.camera_distance + scene_distance * step_factor;
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
	float3 dir = front_vec + input.screenpos.x * right_vec + input.screenpos.y * top_vec;
	float dir_invlen = 1.f / length(dir);
	dir *= dir_invlen;
	float3 right_ray_vec = ddx(input.screenpos.x) * right_vec * dir_invlen;
	float3 bottom_ray_vec = ddy(input.screenpos.y) * top_vec * dir_invlen;

	Ray rays[RAY_COUNT];
	for (uint index = 1; index < RAY_COUNT; ++index)
		rays[index].depth = INVALID_DEPTH;

	rays[0].pos = eye;
	rays[0].dir = dir;
	rays[0].contribution = float3(1.f, 1.f, 1.f);
	rays[0].inside_sign = 1.f;
	rays[0].depth = 0;
	uint ray_count = 1;

	float hdr_output = -1.f;
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
		geometry_input.dir.xyz = rays[ray_index].dir;
		geometry_input.dir.w = 1.f;
		geometry_input.right_ray_offset = right_ray_vec;
		geometry_input.bottom_ray_offset = bottom_ray_vec;

		MarchingInput marching_input;
		marching_input.is_inside = false;
		marching_input.has_transparent = false;
		marching_input.last_transparent_pos = float3(0.f, 0.f, 0.f);
		marching_input.is_shadow_pass = false;

		uint iter_count;
		float scene_distance;
		if (march_ray(geometry_input, marching_input, RANGE, inside_sign, iter_count, scene_distance))
		{
			// calculate the normal, first pass
			NormalOutput normal_output;
			normal_output.use_normal = false;
			normal_output.normal = float3(0.f, 0.f, 0.f);
			normal_output.normal_sample_dist = grad_eps;

			geometry_input.dir.w = 0;
			map_normal(geometry_input, normal_output);
			if (!normal_output.use_normal)
			{
				normal_output.normal = grad(geometry_input, marching_input, scene_distance * inside_sign, normal_output.normal_sample_dist);
			}

			// get the material
			MaterialInput material_input;
			material_input.obj_normal = normal_output.normal;
			material_input.iteration_count = iter_count;
			material_input.scene_distance = scene_distance;

			MaterialOutput material_output;
			material_output.material_id = MATERIAL_NONE;
			material_output.material_position = float4(geometry_input.pos, 0.f);
			material_output.material_properties = float4(0.f, 0.f, 0.f, 0.f);
			material_output.diffuse_color = float4(0.f, 0.f, 0.f, 1.f);
			material_output.specular_color = float4(0.f, 0.f, 0.f, 48.f);
			material_output.emissive_color = float3(0.f, 0.f, 0.f);
			material_output.reflection_color = float3(0.f, 0.f, 0.f); // no reflection
			material_output.refraction_color = float3(0.f, 0.f, 0.f); // no refraction
			material_output.optical_index = 1.4f;
			material_output.optical_density = 0.f;
			material_output.normal = float4(0.f, 0.f, 0.f, 0.f);
			material_output.max_cost = 7;
			material_output.use_hdr = true;

			map_material(geometry_input, material_input, material_output);

			// change the hdr output to what the material wants, but only in the first iteration
			float new_hdr = material_output.use_hdr ? 1.f : 0.f;
			hdr_output = lerp(hdr_output, new_hdr, step(hdr_output, 0.f));
			
			// get the new normal
			float3 new_normal = lerp(normal_output.normal, material_output.normal.xyz, material_output.normal.w);

			// do we have reflection?
			if (any(material_output.reflection_color) && inside_sign > 0.f && current_ray_depth + 3 < material_output.max_cost) // only if we are an outside ray
			{
				if (ray_count < RAY_COUNT)
				{
					uint new_ray_index = find_free_ray(rays);

					float3 ref_vec = reflect(geometry_input.dir.xyz, new_normal);
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
			if (any(material_output.refraction_color) && current_ray_depth + 4 < material_output.max_cost)
			{
				if (ray_count < RAY_COUNT)
				{
					uint new_ray_index = find_free_ray(rays);

					if (inside_sign > 0.f) // just entering the material
					{
						float3 ref_vec = refract(geometry_input.dir.xyz, new_normal, 1.f / material_output.optical_index);
						// start a new ray

						rays[new_ray_index].pos = geometry_input.pos + ref_vec * refract_eps;
						rays[new_ray_index].dir = ref_vec;
						rays[new_ray_index].contribution = material_output.refraction_color * ray_contribution;
						rays[new_ray_index].inside_sign = -1.f;
						rays[new_ray_index].depth = current_ray_depth + 2;
					}
					else // leaving the material
					{
						float3 ref_vec = refract(geometry_input.dir.xyz, -new_normal, material_output.optical_index);
						// start a new ray

						rays[new_ray_index].pos = geometry_input.pos + ref_vec * refract_eps;
						rays[new_ray_index].dir = ref_vec;
						rays[new_ray_index].contribution = material_output.refraction_color * ray_contribution;
						rays[new_ray_index].inside_sign = 1.f;
						rays[new_ray_index].depth = current_ray_depth + 2;
					}
					++ray_count;
				}
			}

			float3 diffuse_color = material_output.diffuse_color.rgb;
			float3 color = float3(0.f, 0.f, 0.f);

			bool use_light = true;
			// handle material
			if (material_output.material_id == MATERIAL_ITER)
			{
				color += iter_count_to_color(iter_count, ITER_COUNT - 1);
				use_light = false;
				hdr_output = 0.f;
			}
			else if (material_output.material_id == MATERIAL_PLAIN)
			{
				color += diffuse_color;
				use_light = false;
			}
			else if (material_output.material_id == MATERIAL_NORMAL)
			{
				float3 normal_color = max(0.01f, new_normal);// *0.5f + 0.5f;
				normal_color = normal_color / max(max(normal_color.r, normal_color.g), normal_color.b);
				color += normal_color;
				use_light = false;
				hdr_output = 0.f;
			}
			else if (material_output.material_id == MATERIAL_DISTANCE_PLANE)
			{
				color += debug_plane_color(material_output.material_properties.x / debug_ruler_scale);
				use_light = false;
				hdr_output = 0.f;
			}
			else if (material_output.material_id == MATERIAL_WOOD)
			{
				diffuse_color += wood(material_output.material_position.xyz);
			}
			else if (material_output.material_id == MATERIAL_MARBLE_DARK)
			{
				diffuse_color += marble(material_output.material_position.xyz, float3(0.556f, 0.478f, 0.541f));
			}
			else if (material_output.material_id == MATERIAL_MARBLE_LIGHT)
			{
				diffuse_color += marble(material_output.material_position.xyz, float3(0.7f, 0.7f, 0.7f));
			}

			if (use_light)
			{
				LightOutput light_output[LIGHT_COUNT];
				for (uint i1 = 0; i1 < LIGHT_COUNT; ++i1)
				{
					light_output[i1].used = false;
					light_output[i1].pos = float4(0.f, 0.f, 0.f, 0.f);
					light_output[i1].color = float3(0.f, 0.f, 0.f);
					light_output[i1].falloff = 0.f;
					light_output[i1].extend = 0.f;
				}

				float ambient_lighting_factor = 0.075f;
				map_light(geometry_input, light_output, ambient_lighting_factor);

				// adjust for shadow eps
				float3 view_dir = geometry_input.dir.xyz;
				float3 scene_pos = geometry_input.pos + new_normal * max(shadow_eps, normal_output.normal_sample_dist);

				marching_input.is_shadow_pass = true;

				// handle all lights
				for (uint i2 = 0; i2 < LIGHT_COUNT; ++i2)
				{
					if (light_output[i2].used)
					{
						// get light dir
						float3 lighting_dir;
						float distance_to_trace;
						float falloff_factor = 1.f;
						if (light_output[i2].pos.w == 1.f) // directional light
						{
							lighting_dir = light_output[i2].pos.xyz;
							lighting_dir /= length(lighting_dir) + dist_eps;
							distance_to_trace = RANGE; // reasonable default
						}
						else // point light
						{
							lighting_dir = scene_pos - light_output[i2].pos.xyz;
							distance_to_trace = length(lighting_dir);
							lighting_dir /= distance_to_trace;
							distance_to_trace -= light_output[i2].extend;

							falloff_factor = pow(0.1, light_output[i2].falloff);
						}
						float3 light_color = light_output[i2].color * falloff_factor;

						// handle the shadow first
						geometry_input.pos = scene_pos;
						geometry_input.dir = float4(-lighting_dir, 1.f);

						uint iter_count_unused;
						float scene_distance_unused;
						bool obstructed = march_ray(geometry_input, marching_input, distance_to_trace, inside_sign, iter_count_unused, scene_distance_unused);
						if (!obstructed)
						{
							// handle diffuse color
							float light_dot = saturate(dot(-new_normal, lighting_dir));
							color += diffuse_color.rgb * light_color * light_dot;

							// handle specular
							float3 half_vec = -normalize(view_dir + lighting_dir);
							float specular_dot = saturate(dot(new_normal, half_vec));
							float specular_factor = pow(specular_dot, material_output.specular_color.a);

							color += material_output.specular_color.rgb * light_color * specular_factor;
						}
						// handle ambient
						color += diffuse_color.rgb * light_color * ambient_lighting_factor;
					}
				}

				// handle emissive color
				color += material_output.emissive_color.rgb;
			}

			output.color.rgb += color * ray_contribution;
		}
		else
		{
			float3 background_color = map_background(geometry_input.dir.xyz, iter_count);
			output.color.rgb += background_color * ray_contribution;
		}
		// keep track of closest point relative to camera distance -> antialiasing
	}

	// hdr_output is either -1 (not set), 0 (disable), or 1 (enable)
	// with abs we map the "not set" case to the "enabled" case as well
	output.color.a = abs(hdr_output);
}