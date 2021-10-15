#include "sdf_primitives.hlsl"
#include "sdf_ops.hlsl"

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
    for (int i = 0; i < 5; i++)
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
    //float obj = sdBase(pos.xyz);
    float box = sdBox(pos.xyz, float3(5.f, 5.f, 5.f));
    float plane = sdPlane(pos.xyz, float3(0.f, 1.f, 0.f));
    float obj = sdFbm(pos.xyz, plane);
    obj = max(obj, box);

    material_property = float3(0.8f, 0.8f, 0.8f);
    return float2(obj, 3.f);
}