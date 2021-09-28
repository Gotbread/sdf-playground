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

		bool center = true;/*
		if (abspos.y > 1.f / 3.f)
		{
			abspos.y -= 2.f / 3.f;
			center = false;
		}
		if (abspos.z > 1.f / 3.f)
		{
			abspos.z -= 2.f / 3.f;
			center = false;
		}*/

		if (center)
		{
			abspos.x -= 4.f / 3.f;
			abspos *= 3.f;
			scale *= 3.f;
		}
		else
		{
			abspos.x -= 10.f / 9.f;
			abspos *= 9.f;
			scale *= 9.f;
		}

		abspos = abs(abspos);
	}
	return d;
}

float map(float3 p)
{
	/*float d1 = sdBox(p, float3(1.f, 1.f, 1.f));
	float d2 = sdSphere(p - float3(0.f, 2.f, 0.f), 1.f);
	return smin(d1, d2, 0.5f);*/

	return fractal(p, 6);
}