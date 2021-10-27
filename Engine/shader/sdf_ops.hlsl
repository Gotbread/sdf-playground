#include "math_constants.hlsl"

// replicates a box of space along all axes
// count: the extra count how many boxes will be added
// size: the size of the box that gets repeated
float3 opRepLim(float3 pos, float3 count, float3 size)
{
	float3 rounded = size * (round(pos / size + count / 2) - count / 2);
	float3 limit = count * size * 0.5f;
	return pos - clamp(rounded, -limit, limit);
}

float2 opRepLim(float2 pos, float2 count, float2 size)
{
	float2 rounded = size * (round(pos / size + count / 2) - count / 2);
	float2 limit = count * size * 0.5f;
	return pos - clamp(rounded, -limit, limit);
}

float opRepLim(float pos, float count, float size)
{
	float rounded = size * (round(pos / size + count / 2) - count / 2);
	float limit = count * size * 0.5f;
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

float opRepInf(float pos, float size)
{
	float x = pos + size * 0.5f;
	return x - size * floor(x / size) - size * 0.5f;
}

float opRepAngle(inout float2 pos, float count)
{
	float angle = atan2(pos.y, pos.x);

	float reduced_angle = angle * count / tau + 0.5f;
	float index = floor(reduced_angle);
	reduced_angle -= index;
	angle = (reduced_angle - 0.5f) * tau / count;

	pos = float2(cos(angle), sin(angle)) * length(pos);
	return index;
}

float2 opRotate(float2 pos, float angle)
{
	float s = sin(angle);
	float c = cos(angle);
	return float2(pos.x * c - pos.y * s, pos.x * s + pos.y * c);
}

// turns an object into a shell
// inner is the value of the distance field which gets turned to the inner surface
// outer is the value of the distance field which gets turned to the outer surface
float opShell(float distance, float inner, float outer)
{
	float avg = (outer + inner) * 0.5f;
	float diff = (outer - inner) * 0.5f;
	return abs(distance - avg) - diff;
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
	float h = saturate(0.5f + 0.5f * (b - a) / k);
	return lerp(b, a, h) - k * h * (1.f - h);
}

// smooth maximum
float smax1(float a, float b, float k)
{
	float h = saturate(0.5f - 0.5f * (b + a) / k);
	return lerp(b, -a, h) + k * h * (1.f - h);
}

float smax2(float a, float b, float k)
{
	float h = saturate(0.5 - 0.5 * (b - a) / k);
	return lerp(b, a, h) + k * h * (1.f - h);
}