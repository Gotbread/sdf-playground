#include "sdf_primitives.hlsl"
#include "sdf_ops.hlsl"
#include "sdf_common.hlsl"

float fast_noise(float3 p)
{
    return frac(sin(dot(p, float3(12.9898f, 78.233f, 34.531247f))) * 43758.5453f);
}

float sdSphereCorner(float3 center, float3 pos, float3 offset)
{
    float3 sphere_pos = center + offset;
    float rad = lerp(0.f, 0.3f, fast_noise(sphere_pos));

    return sdSphere(pos - sphere_pos, rad);
}

float sdBase(float3 pos)
{
    float3 ipos = floor(pos);

    float a = sdSphereCorner(ipos, pos, float3(0.f, 0.f, 0.f));
    float b = sdSphereCorner(ipos, pos, float3(0.f, 0.f, 1.f));
    float c = sdSphereCorner(ipos, pos, float3(0.f, 1.f, 0.f));
    float d = sdSphereCorner(ipos, pos, float3(0.f, 1.f, 1.f));
    float e = sdSphereCorner(ipos, pos, float3(1.f, 0.f, 0.f));
    float f = sdSphereCorner(ipos, pos, float3(1.f, 0.f, 1.f));
    float g = sdSphereCorner(ipos, pos, float3(1.f, 1.f, 0.f));
    float h = sdSphereCorner(ipos, pos, float3(1.f, 1.f, 1.f));

    return min(min(min(a, b), min(c, d)), min(min(e, f), min(g, h)));
}

float sdFbm(float3 p, float d)
{
    float3x3 mat = { 0.00, 1.60, 1.20,
                     -1.60, 0.72, -0.96,
                     -1.20, -0.96, 1.28 };
    float s = 1.0;
    for (int i = 0; i < 2; i++)
    {
        // evaluate new octave
        float n = s * sdBase(p);

        // add
        n = smax2(n, d - 0.1f * s, 0.3 * s);
        d = smin(n, d, 0.3 * s);

        // prepare next octave
        p = mul(mat, p);
        s = 0.5 * s;
    }
    return d;
}

void map(GeometryInput geometry, MarchingInput march, MaterialInput material_input, inout MaterialOutput material_output, bool geometry_step, inout float output_scene_distance)
{
    float box = sdBox(geometry.pos, float3(5.f, 5.f, 5.f));
    float plane = sdPlane(geometry.pos, float3(0.f, 1.f, 0.f));
    float obj = sdFbm(geometry.pos, plane);
    obj = max(obj, box);

    if (geometry_step)
    {
        OBJECT(obj);
    }
    else
    {
        if (MATERIAL(obj))
        {
            material_output.diffuse_color.rgb = float3(0.8f, 0.8f, 0.8f);
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