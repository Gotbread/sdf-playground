#include "sdf_primitive.hlsl"


float fractal(float3 p, uint depth)
{
	float d = 1e20;
	float3 abspos = abs(p);
	float scale = 1.f;
	for (uint iter = 0; iter < depth; ++iter)
	{
		float new_d = sdBox(abspos, float3(1.f, 1.f, 1.f)) / scale;
		d = min(d, new_d);

		if (abspos.z > abspos.y)
		{
			abspos.yz = abspos.zy;
		}
		if (abspos.y > abspos.x)
		{
			abspos.xy = abspos.yx;
		}

		if (abspos.y > 1.f / 3.f)
		{
			abspos.y -= 2.f / 3.f;
		}
		if (abspos.z > 1.f / 3.f)
		{
			abspos.z -= 2.f / 3.f;
		}

		abspos.x -= 10.f / 9.f;
		abspos *= 9.f;
		scale *= 9.f;

		abspos = abs(abspos);
	}
	return d;
}


float sdGyroid(float3 p)
{
	return dot(sin(p.xyz), cos(p.zxy));
}

float map(float3 p, float3 dir)
{
	float gyroid = abs(sdGyroid(p * 7.f) / 7.f) - 0.03f;
	float box = sdBox(p, float3(1.f, 1.f, 1.f));
	return max(gyroid, box);
	//return sdBox(p, float3(1.f, 1.f, 1.f)) - 0.05f;
	//return fractal(p, 2);
}