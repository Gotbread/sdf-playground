#include "noise.hlsl"

float3 marble(float3 pos, float3 marble_color)
{
	float3 marble_dir = float3(3.f, 2.f, 1.f);
	float wave_pos = dot(marble_dir, pos) * 2.f + turbulence(pos) * 5.f;
	float sine_val = (1.f + sin(wave_pos)) * 0.5f;
	sine_val = pow(sine_val, 0.5f);
	return marble_color * sine_val;
}

float3 wood(float3 pos)
{
	static const float turbulence_scale = 0.125f;
	static const float rings = 12.f;

	float dist = sqrt(pos.x * pos.x + pos.y * pos.y) + turbulence_scale * turbulence(pos);
	float sine_val = 0.5f * abs(sin(2 * rings * dist * 3.14159));

	return float3(0.3125f + sine_val, 0.117f + sine_val, 0.117f);
}

float3 fire(float3 pos, float threshold)
{
	float turb = turbulence(pos) + 0.35f;
	turb = turb > threshold ? turb : 0.f;
	return float3(5.f, 2.f, 1.f) * turb;
}