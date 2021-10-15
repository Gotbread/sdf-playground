struct ps_input
{
	float4 pos : SV_POSITION;
	float2 screenpos : SCREENPOS;
};

struct ps_output
{
	float4 color : SV_TARGET;
};

Texture2D<float4> scene : register(t0);
Texture2D<float4> bloom : register(t1);
SamplerState samp;

void ps_main(ps_input input, out ps_output output)
{
	float2 uv = input.screenpos * float2(+0.5f, -0.5f) + float2(0.5f, 0.5f);
	
	float4 scene_color = scene.Sample(samp, uv);
	float4 bloom_color = bloom.Sample(samp, uv);
	float4 total_color = scene_color + bloom_color;
	//output.color = total_color / (1.f + total_color);
	float exposure = 1.f;
	float4 ldr_color = 1.f - exp(-total_color * exposure);
	output.color = lerp(scene_color, ldr_color, scene_color.a);
}