#include "sdf_primitives.hlsl"
#include "sdf_ops.hlsl"
#include "sdf_common.hlsl"

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
    map_groundplane(geometry, material_output, geometry_step, output_scene_distance);

    float3 obj_pos = geometry.pos;
    obj_pos.xz = opRotate(obj_pos.xz, stime * 0.5f);
    float index = opRepAngle(obj_pos.xz, 8.f);
    obj_pos.x -= 1.f;
    obj_pos.y -= 1.f;
    opRepAngle(obj_pos.xz, 8.f);
    float plane1 = sdPlane(obj_pos.xyz - float3(0.1f, 0.1f, 0.f), float3(0.707f, 0.707f, 0.f));
    float plane2 = sdPlane(obj_pos.xyz, float3(0.707f, -0.707f, 0.f));
    float plane3 = sdPlane(obj_pos.xyz - float3(0.f, 0.13f, 0.f), float3(0.f, 1.f, 0.f));
    float gems = smax2(smax2(plane1, plane2, 0.001f), plane3, 0.001f);

    if (geometry_step)
    {
        OBJECT(gems);
    }
    else
    {
        if (MATERIAL(gems))
        {
            float3 ruby_color = float3(0.8f, 0.1f, 0.3f);
            float3 saph_color = float3(0.8f, 0.7f, 0.1f);
            material_output.diffuse_color.xyz = frac(index * 0.5f + 0.25f) > 0.5f ? ruby_color : saph_color;
            material_output.specular_color.rgb = 1.f;
            material_output.refraction_color.rgb = 0.5f;
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