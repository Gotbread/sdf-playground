#include "sdf_primitives.hlsl"
#include "sdf_ops.hlsl"
#include "sdf_common.hlsl"

float sdSierpinski(float3 p, uint depth)
{
    float3 a1 = float3(0.f, +1.f, 0.f);
    float3 a2 = float3(-0.7f, 0.f, -0.5f);
    float3 a3 = float3(+0.7f, 0.f, -0.5f);
    float3 a4 = float3(0.f, 0.f, +0.7f);
    float scale = 2.f;
    for (uint iter = 0; iter < depth; ++iter)
    {
        float3 c = a1;
        float dist = length(p - a1);
        float d = length(p - a2);
        if (d < dist)
        {
            c = a2;
            dist = d;
        }
        d = length(p - a3);
        if (d < dist)
        {
            c = a3;
            dist = d;
        }
        d = length(p - a4);
        if (d < dist)
        {
            c = a4;
            dist = d;
        }
        p = scale * p - c * (scale - 1.f);
    }
    return length(p) / pow(scale, depth) - 0.002f;
}

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
    map_groundplane(geometry, material_output, geometry_step, output_scene_distance);

    float obj = sdSierpinski(geometry.pos - float3(0.f, 1.f, 0.f), 10);

    if (geometry_step)
    {
        OBJECT(obj);
    }
    else
    {
        if (MATERIAL(obj))
        {
            material_output.diffuse_color.rgb = float3(0.9f, 0.7f, 0.2f);
            material_output.specular_color.rgb = 0.5f;
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