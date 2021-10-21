#ifndef SDF_STRUCTS_HLSL
#define SDF_STRUCTS_HLSL

struct GeometryInput
{
	// the position in 3D worldspace
	float3 pos;

	// xyz: the direction of the ray, if directional
	float3 dir;

	// the euclidean distance from the eye
	float camera_distance;

	// points to the pixel right of this one, per unit of eye distance
	float3 right_ray_offset;

	// points to the pixel below this one, per unit of eye distance
	float3 bottom_ray_offset;
};

struct MarchingInput
{
	// if true, we are just marching along a ray and can use fast methods if available
	// the "dir" member will be valid if this is set
	bool use_fast;

	// if true, we are inside an object and work with negative distance values
	// if false, we are outside an object and work with positive distance values (default case)
	bool is_inside;

	// where the last point of transparency was, in order to remove this object
	float3 last_transparent_pos;

	// if last_transparent_pos is valid
	bool has_transparent;
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
	// the normal of the object
	float3 obj_normal;

	// how many iterations we did to get here
	uint iteration_count;

	// the last distance to the scene
	float scene_distance;
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

	// how deep the rays we can launch from this
	uint max_cost;
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

#endif
