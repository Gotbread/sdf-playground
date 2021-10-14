Texture2D<float4> scene_input : register(t0);
RWTexture2D<float4> output : register(u0);

static const float3 brightness_fac = float3(0.2126f, 0.7152f, 0.0722f);

[numthreads(128, 1, 1)]
void cs_main1(uint3 dispatch_thread_id : SV_DispatchThreadID)
{
	float4 sum = 0.f;
	for (int i = -16; i <= +16; ++i)
	{
		float4 col = scene_input[dispatch_thread_id.xy + int2(i, 0)];
		float brightness = dot(col.xyz, brightness_fac);
		if (brightness < 1.f)
			col = 0.f;
		sum += col;
	}
	output[dispatch_thread_id.xy] = sum / 33.f;
}

[numthreads(1, 128, 1)]
void cs_main2(uint3 dispatch_thread_id : SV_DispatchThreadID)
{
	float4 sum = 0.f;
	for (int i = -16; i <= +16; ++i)
	{
		sum += scene_input[dispatch_thread_id.xy + int2(0, i)];
	}
	output[dispatch_thread_id.xy] = sum / 33.f;
}