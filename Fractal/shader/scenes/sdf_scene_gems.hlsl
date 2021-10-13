#include "sdf_primitive.hlsl"

float smax(float d1, float d2, float k)
{
    float h = clamp(0.5 - 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return lerp(d2, d1, h) + k * h * (1.0 - h);
}

// params:
// pos.xyz: 3D position in the scene
// pos.w: one when rendering with transparent objects, zero without
//
// dir: input normal. normalized to 1 for normal passes, zero for gradient-only passes
//
// return value:
// x: scene distance
// y: material ID
//
// material_property:
// extra vector, meaning depends on material
float2 map(float4 pos, float3 dir, out float3 material_property)
{
    // testing
    float3 obj_pos = pos.xyz;
    obj_pos.xz = opRotate(obj_pos.xz, stime * 0.5f);
    float index = opRepAngle(obj_pos.xz, 8.f);
    obj_pos.x -= 1.f;
    obj_pos.y -= 1.f;
    opRepAngle(obj_pos.xz, 8.f);
    float plane1 = sdPlane(obj_pos.xyz - float3(0.1f, 0.1f, 0.f), float3(0.707f, 0.707f, 0.f));
    float plane2 = sdPlane(obj_pos.xyz, float3(0.707f, -0.707f, 0.f));
    float plane3 = sdPlane(obj_pos.xyz - float3(0.f, 0.13f, 0.f), float3(0.f, 1.f, 0.f));
    float obj = smax(smax(plane1, plane2, 0.001f), plane3, 0.001f);

    // floor
    float floor1 = sdPlaneFast(pos.xyz, dir, float3(0.f, 1.f, 0.f));

    // select
    if (obj < floor1)
    {
        float3 ruby_color = float3(0.8f, 0.1f, 0.3f);
        float3 saph_color = float3(0.8f, 0.7f, 0.1f);
        material_property = frac(index * 0.5f + 0.25f) > 0.5f ? ruby_color : saph_color;
        return float2(obj, 3.f);
    }
    else
    {
        float2 tile_pos = floor(pos.xz);
        float tile_parity = round(frac((tile_pos.x + tile_pos.y) * 0.5f + 0.25f));
        material_property = tile_parity > 0.5f ? float3(0.1f, 0.1f, 0.1f) : float3(0.8f, 0.8f, 0.8f);
        return float2(floor1, 3.f);
    }
}

