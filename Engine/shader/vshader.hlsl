struct vs_input
{
	float2 pos : POSITION;
};

struct vs_output
{
	float4 pos : SV_POSITION;
	float2 screenpos : SCREENPOS;
};

void vs_main(vs_input input, out vs_output output)
{
	output.pos = float4(input.pos, 0.f, 1.f);
	output.screenpos = input.pos;
}