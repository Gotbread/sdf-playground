#include "sdf_primitives.hlsl"
#include "sdf_ops.hlsl"
#include "sdf_common.hlsl"

float vase(float3 pos)
{
	float obj1 = sdSphere(pos - float3(0.f, 1.89f, 0.f), 0.5f);
	float obj2 = sdCappedCylinder(pos - float3(0.f, 0.8f, 0.f), 0.75f, 0.2f);
	float obj3 = sdBox(pos - float3(0.f, 0.075f, 0.f), float3(0.4f, 0.075f, 0.4f));
	float cut_plane1 = sdPlane(pos - float3(0.f, 1.9f, 0.f), float3(0.f, 1.f, 0.f));
	float cut_plane2 = sdPlane(pos - float3(0.f, 1.5f, 0.f), float3(0.f, -1.f, 0.f));

	float d = max(obj1, cut_plane2);
	d = opPipeMerge(d, obj2, 0.1f, 4.f);
	d = opPipeMerge(d, obj3, 0.1f, 4.f);
	d = max(d, cut_plane1);
	d = max(d, -obj1 - 0.06f);
	return d;
}

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
	map_groundplane(geometry, material_output, geometry_step, output_scene_distance);
	
	// wall
	float3 wall_pos = geometry.pos.xyz;
	wall_pos.xz = opRepInf(wall_pos.xz, float2(20.f, 20.f));
	wall_pos.xz = abs(wall_pos.xz);
	if (wall_pos.z > wall_pos.x)
	{
		wall_pos.xz = wall_pos.zx;
	}

	float wall1 = sdBox(wall_pos - float3(3.5f, 2.f, 3.f), float3(1.5f, 2.f, 1.f));
	float wall2 = sdBox(wall_pos - float3(7.f, 2.f, 5.f), float3(3.f, 2.f, 1.f));
	float wall = min(wall1, wall2);

	// object - vase
	float3 obj_pos = wall_pos;
	obj_pos.x -= 8.f;
	obj_pos.x = abs(obj_pos.x);
	float obj1 = vase(obj_pos - float3(1.f, 0.f, 3.f));

	// object - torch
	static const float torch_angle = 15.f * pi / 180.f;
	static const float torch_c = cos(torch_angle), torch_s = sin(torch_angle);

	float3 torch_pos = wall_pos.xyz - float3(5.f, 2.f, 3.f);
	float3 wood_pos = torch_pos;
	torch_pos.x -= 0.3f; // offset the torch slightly
	wood_pos.xy = float2(wood_pos.x * torch_c - wood_pos.y * torch_s, wood_pos.x * torch_s + wood_pos.y * torch_c);
	float wood = sdBox(wood_pos - float3(0.f, 0.6f, 0.f), float3(0.05f, 0.5f, 0.05f));
	float fire = sdRoundCone(torch_pos, float3(0.f, 1.1f, 0.f), float3(0.f, 1.6f, 0.f), 0.15f, 0.1f);

	float transparent_fire = sdRoundCone(march.last_transparent_pos, float3(0.f, 1.1f, 0.f), float3(0.f, 1.6f, 0.f), 0.15f, 0.1f);

	if (geometry_step)
	{
		OBJECT(wall);
		OBJECT(obj1);
		OBJECT(wood);
		OBJECT_TRANSPARENT(fire, transparent_fire);
	}
	else
	{
		if (MATERIAL(wall))
		{
			material_output.material_position.rgb = geometry.pos.xyz;
			material_output.material_id = MATERIAL_MARBLE_LIGHT;
		}
		else if (MATERIAL(obj1))
		{
			material_output.material_position.rgb = geometry.pos.xyz * 3.f;
			material_output.material_id = MATERIAL_MARBLE_DARK;
		}
		else if (MATERIAL(wood))
		{
			material_output.material_position.rgb = geometry.pos.xzy * 2.f;
			material_output.material_id = MATERIAL_WOOD;
		}
		else if (MATERIAL(fire))
		{
			material_output.material_position.rgb = torch_pos.xyz * 3.f - float3(0.f, stime * 3.f, 0.f);
			material_output.material_id = MATERIAL_FIRE;
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