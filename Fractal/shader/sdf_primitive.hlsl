float sdSphere(float3 p, float r)
{
	return length(p) - r;
}

float sdBox(float3 p, float3 size)
{
	float3 q = abs(p) - size;
	return length(max(q, 0.f)) + min(max(q.x, max(q.y, q.z)), 0.f);
}

float sdBoxFast(float3 p, float3 dir, float3 size)
{
	float3 q = abs(p) - size;
	return length(max(q, 0.f)) + min(max(q.x, max(q.y, q.z)), 0.f);
}

float smin(float a, float b, float k)
{
	float h = clamp(0.5f + 0.5f * (b - a) / k, 0.f, 1.f);
	return lerp(b, a, h) - k * h * (1.f - h);
}