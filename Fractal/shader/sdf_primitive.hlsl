// this library provides basic primitives for SDFs
//
// sdX functions are the signed distance functions itself
// opX functions are operations on SDFs
//
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
	float scale = dot(dir, -plane_norm);
	return plane_dist / saturate(scale);
}

float sdTorusXY(float3 pos, float radius_big, float radius_small)
{
	float2 q = float2(length(pos.xy) - radius_big, pos.z);
	return length(q) - radius_small;
}

// replicates a box of space along all axes
// count: the extra count how many boxes will be added
// size: the size of the box that gets repeated
float3 opRepLim(float3 pos, float3 count, float3 size)
{
	float3 rounded = size * (round(pos / size + count / 2) - count / 2);
	float3 limit = count * size * 0.5f;
	return pos - clamp(rounded, -limit, limit);
}

float2 opRotate(float2 pos, float angle)
{
	float s = sin(angle);
	float c = cos(angle);
	return float2(pos.x * c - pos.y * s, pos.x * s + pos.y * c);
}

// stepval = how far each step goes
// spread = how far apart the steps are
float staircase(float x, float stepval, float spread)
{
	return min(stepval, frac(x / spread) * spread) + floor(x / spread) * stepval;
}

// smooth minimum
float smin(float a, float b, float k)
{
	float h = clamp(0.5f + 0.5f * (b - a) / k, 0.f, 1.f);
	return lerp(b, a, h) - k * h * (1.f - h);
}

