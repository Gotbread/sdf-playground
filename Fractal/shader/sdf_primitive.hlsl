// this library provides basic primitives for SDFs
//
// sdX functions are the signed distance functions itself
// opX functions are operations on SDFs
//
// in all functions, "pos" refers to the space position for which to evaluate the SDF

static const float sqrt_half = 0.7071067811865f;
static const float sqrt_two = 1.414213562373096f;
static const float pi = 3.14159265358979323f;

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
	return plane_dist / (saturate(scale) + 0.0001f);
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

// replicates a box of space along all axes
// count: the extra count how many boxes will be added
// size: the size of the box that gets repeated
float3 opRepLim(float3 pos, float3 count, float3 size)
{
	float3 rounded = size * (round(pos / size + count / 2) - count / 2);
	float3 limit = count * size * 0.5f;
	return pos - clamp(rounded, -limit, limit);
}

float3 opRepInf(float3 pos, float3 size)
{
	float3 x = pos + size * 0.5f;
	return x - size * floor(x / size) - size * 0.5f;
}

float2 opRepInf(float2 pos, float2 size)
{
	float2 x = pos + size * 0.5f;
	return x - size * floor(x / size) - size * 0.5f;
}

float2 opRotate(float2 pos, float angle)
{
	float s = sin(angle);
	float c = cos(angle);
	return float2(pos.x * c - pos.y * s, pos.x * s + pos.y * c);
}

// transforms a 2D vector to a 45° tilted coordinate system
// same transform also works backwards
float2 opAB2UV(float2 input)
{
	return float2(input.x + input.y, input.x - input.y) * sqrt_half;
}

float opChamfer(float a, float b, float size)
{
	return (a + b - size) * sqrt_half;
}

float opChamferMerge(float a, float b, float size)
{
	return min(min(a, b), opChamfer(a, b, size));
}

float opPipe(float a, float b, float size, float count)
{
	float2 ab = float2(a, b);
	float2 uv = opAB2UV(ab);
	float diag = size * sqrt_half - uv.y;
	diag = fmod(diag, sqrt_two * size / count);
	uv.y = size * sqrt_half - diag;
	ab = opAB2UV(uv);

	float a_offset = (count - 1.f) / count;
	return length(float2(ab.x - a_offset * size, ab.y)) - size / count;
}

float opPipeMerge(float a, float b, float size, float count)
{
	return min(min(a, b), opPipe(a, b, size, count));
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

