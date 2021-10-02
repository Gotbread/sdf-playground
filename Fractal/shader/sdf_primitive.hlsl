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

float sdPlane(float3 p, float3 plane_norm)
{
	return dot(p, plane_norm);
}

float sdPlaneFast(float3 p, float3 dir, float3 plane_norm)
{
	float plane_dist = dot(p, plane_norm);
	float scale = dot(dir, -plane_norm);
	return plane_dist / saturate(scale);
}

float smin(float a, float b, float k)
{
	float h = clamp(0.5f + 0.5f * (b - a) / k, 0.f, 1.f);
	return lerp(b, a, h) - k * h * (1.f - h);
}