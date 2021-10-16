Texture2D<float4> scene_input : register(t0);
RWTexture2D<float4> output : register(u0);

static const float3 brightness_fac = float3(0.2126f, 0.7152f, 0.0722f);
static const float coeffs[17] =
{
	0.070771f,
	0.069674f, 0.066483f, 0.061487f, 0.055116f,
	0.047886f, 0.040324f, 0.032912f, 0.026035f,
	0.019962f, 0.014834f, 0.010685f, 0.007459f,
	0.005047f, 0.003310f, 0.002104f, 0.001296f,
};

[numthreads(128, 1, 1)]
void cs_main1(uint3 dispatch_thread_id : SV_DispatchThreadID)
{
	float4 sum = 0.f;
	for (int i = -16; i <= +16; ++i)
	{
		float4 col = scene_input[dispatch_thread_id.xy + int2(2 * i, 0)];
		float brightness = dot(col.xyz, brightness_fac);
		float factor = saturate((saturate(brightness) - 0.75f) * 4.f);
		col *= factor;
		sum += col * coeffs[abs(i)];
	}
	output[dispatch_thread_id.xy] = sum * 2.f;
}

[numthreads(1, 128, 1)]
void cs_main2(uint3 dispatch_thread_id : SV_DispatchThreadID)
{
	float4 sum = 0.f;
	for (int i = -16; i <= +16; ++i)
	{
		sum += scene_input[dispatch_thread_id.xy + int2(0, 2 * i)] * coeffs[abs(i)];
	}
	output[dispatch_thread_id.xy] = sum * 2.f;
}