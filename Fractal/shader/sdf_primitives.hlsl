#include "math_constants.hlsl"

// this library provides basic primitives for SDFs
// in all functions, "pos" refers to the space position for which to evaluate the SDF

float sdSphere(float3 pos, float radius)
{
	return length(pos) - radius;
}

float sdBox(float3 pos, float3 size)
{
	float3 q = abs(pos) - size;
	return length(max(q, 0.f)) + min(max(q.x, max(q.y, q.z)), 0.f);
}

// TODO: output an "extra distance" which is a fast step towards the box based on the exact distance
float sdBoxFast(float3 pos, float3 dir, float3 size)
{
	float3 q = abs(pos) - size;
	return length(max(q, 0.f)) + min(max(q.x, max(q.y, q.z)), 0.f);
}

float sdPlane(float3 pos, float3 plane_norm)
{
	return dot(pos, plane_norm);
}

// TODO: find out if changing the return value is okay
float sdPlaneFast(float3 pos, float3 dir, float3 plane_norm)
{
	float plane_dist = dot(pos, plane_norm);
	float fast_skip = dot(dir, dir);
	if (fast_skip > 0.5f)
	{
		return plane_dist / (saturate(dot(dir, -plane_norm)) + 0.000000001f);
	}
	else
	{
		return plane_dist;
	}
}

float sdTorusXY(float3 pos, float radius_big, float radius_small)
{
	float2 q = float2(length(pos.xy) - radius_big, pos.z);
	return length(q) - radius_small;
}

float sdCappedCylinder(float3 pos, float h, float r)
{
	float2 d = abs(float2(length(pos.xz), pos.y)) - float2(r, h);
	return min(max(d.x, d.y), 0.f) + length(max(d, 0.f));
}

float sdRoundCone(float3 p, float3 a, float3 b, float r1, float r2)
{
	// sampling independent computations (only depend on shape)
	float3 ba = b - a;
	float l2 = dot(ba, ba);
	float rr = r1 - r2;
	float a2 = l2 - rr * rr;
	float il2 = 1.0 / l2;

	// sampling dependant computations
	float3 pa = p - a;
	float y = dot(pa, ba);
	float z = y - l2;
	float3 x2_s = pa * l2 - ba * y;
	float x2 = dot(x2_s, x2_s);
	float y2 = y * y * l2;
	float z2 = z * z * l2;

	// single square root!
	float k = sign(rr) * rr * rr * x2;
	if (sign(z) * a2 * z2 > k) return  sqrt(x2 + z2) * il2 - r2;
	if (sign(y) * a2 * y2 < k) return  sqrt(x2 + y2) * il2 - r1;
	return (sqrt(x2 * a2 * il2) + y * rr) * il2 - r1;
}
