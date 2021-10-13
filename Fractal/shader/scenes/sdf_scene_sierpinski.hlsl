#include "sdf_primitive.hlsl"


float sierpinski(float3 p, uint depth)
{
      float3 a1 = float3(+1.f, +1.f, +1.f);
      float3 a2 = float3(-1.f, -1.f, +1.f);
      float3 a3 = float3(+1.f, -1.f, -1.f);
      float3 a4 = float3(-1.f, +1.f, -1.f);
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
      return length(p) / pow(scale, depth) - 2 * dist_eps;
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
    float obj = sierpinski(pos.xyz, 5);

    material_property = float3(0.9f, 0.7f, 0.2f);
    return float2(obj, 3.f);
}