#include <string>
#include <vector>
#include <d3dcompiler.h>

#include "Application.h"
#include "Math3D.h"

#pragma comment(lib, "d3dcompiler.lib")

using namespace Math3D;


bool Application::Init(HINSTANCE hInstance)
{
	WNDCLASS wc = { 0 };
	wc.cbWndExtra = sizeof(this);
	wc.hCursor = LoadCursor(0, IDC_ARROW);
	wc.hInstance = hInstance;
	wc.lpszClassName = "Mainwnd";
	wc.lpfnWndProc = sWndProc;

	RegisterClass(&wc);

	bool fullscreen = true;
	std::string title = "SDF Fractal";

	if (fullscreen)
	{
		unsigned width = GetSystemMetrics(SM_CXSCREEN);
		unsigned height = GetSystemMetrics(SM_CXSCREEN);
		hWnd = CreateWindow(wc.lpszClassName, title.c_str(), WS_POPUP, 0, 0, width, height, 0, 0, hInstance, this);
	}
	else
	{
		unsigned windowstyle = WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;
		int xpos = CW_USEDEFAULT;
		int ypos = CW_USEDEFAULT;
		unsigned width = 800;
		unsigned height = 600;

		RECT r;
		SetRect(&r, 0, 0, width, height);
		AdjustWindowRect(&r, windowstyle, 0);
		hWnd = CreateWindow(wc.lpszClassName, title.c_str(), windowstyle, xpos, ypos, r.right - r.left, r.bottom - r.top, 0, 0, hInstance, this);
	}

	if (!hWnd)
	{
		return false;
	}

	mouse_tracking = false;
	for (auto &elem : keystate)
	{
		elem = false;
	}

	return initGraphics();
}


void Application::Run()
{
	ShowWindow(hWnd, SW_SHOWNORMAL);

	DWORD lasttime = GetTickCount();

	MSG Msg;
	do
	{
		while (PeekMessage(&Msg, 0, 0, 0, PM_REMOVE))
		{
			TranslateMessage(&Msg);
			DispatchMessage(&Msg);
		}

		unsigned newtime = GetTickCount();
		unsigned diff = newtime - lasttime;
		lasttime = newtime;

		updateSimulation(static_cast<float>(diff) / 1000.f);
		render();
	}
	while (Msg.message != WM_QUIT);
}


LRESULT CALLBACK Application::sWndProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam)
{
	if (Msg == WM_NCCREATE)
	{
		SetWindowLongPtr(hWnd, 0, reinterpret_cast<LONG_PTR>(reinterpret_cast<CREATESTRUCT *>(lParam)->lpCreateParams));
	}
	Application *app = reinterpret_cast<Application *>(GetWindowLongPtr(hWnd, 0));
	if (app)
	{
		return app->WndProc(hWnd, Msg, wParam, lParam);
	}
	return DefWindowProc(hWnd, Msg, wParam, lParam);
}


LRESULT CALLBACK Application::WndProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam)
{
	switch (Msg)
	{
	case WM_MOUSEMOVE:
		{
			if (mouse_tracking)
			{
				int xdiff = LOWORD(lParam) - lastmouse.x;
				int ydiff = HIWORD(lParam) - lastmouse.y;
				if (xdiff || ydiff)
				{
					camera.RotateY(xdiff / -500.f);
					camera.RotateX(ydiff / -500.f);
				}
			}
			lastmouse.x = LOWORD(lParam);
			lastmouse.y = HIWORD(lParam);
		}
		break;
	case WM_KEYDOWN:
		keystate[static_cast<char>(LOWORD(wParam))] = true;
		if (LOWORD(wParam) == VK_ESCAPE)
		{
			PostQuitMessage(0);
		}
		break;
	case WM_KEYUP:
		keystate[static_cast<char>(LOWORD(wParam))] = false;
		break;
	case WM_LBUTTONDOWN:
		mouse_tracking = true;
		break;
	case WM_LBUTTONUP:
		mouse_tracking = false;
		break;
	case WM_DESTROY:
		PostQuitMessage(0);
		break;
	}
	return DefWindowProc(hWnd, Msg, wParam, lParam);
}


bool Application::initGraphics()
{
	graphics = std::make_unique<Graphics>();
	if (!graphics->init(hWnd))
		return false;

	if (!initShaders())
		return false;

	if (!initGeometry())
		return false;

	RECT rect;
	GetClientRect(hWnd, &rect);
	float width = static_cast<float>(rect.right - rect.left);
	float height = static_cast<float>(rect.bottom - rect.top);

	camera.SetCameraMode(Camera::CameraModeFPS);
	camera.SetAspect(width / height);
	camera.SetFOVY(ToRadian(60));
	camera.SetNearPlane(1.f);
	camera.SetFarPlane(300.f);
	camera.SetMinXAngle(ToRadian(80.f));
	camera.SetMaxXAngle(ToRadian(80.f));
	camera.SetRoll(0.f);
	
	camera.SetEye(Vector3(3.f, 2.f, -6.f));
	camera.SetLookat(Vector3(0.f, 0.f, 0.f));

	stime = 0.f;

	return true;
}


bool Application::initShaders()
{
	auto v_code = R"r1y(
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
	)r1y";

	auto p_code = R"r1y(
		struct ps_input
		{
			float4 pos : SV_POSITION;
			float2 screenpos : SCREENPOS;
		};

		struct ps_output
		{
			float4 color : SV_TARGET;
		};

		cbuffer camera
		{
			float3 eye;
			float3 front_vec;
			float3 right_vec;
			float3 top_vec;
		};

		// 1 / 289
		#define NOISE_SIMPLEX_1_DIV_289 0.00346020761245674740484429065744f

		float mod289(float x)
		{
			return x - floor(x * NOISE_SIMPLEX_1_DIV_289) * 289.0;
		}

		float2 mod289(float2 x)
		{
			return x - floor(x * NOISE_SIMPLEX_1_DIV_289) * 289.0;
		}

		float3 mod289(float3 x)
		{
			return x - floor(x * NOISE_SIMPLEX_1_DIV_289) * 289.0;
		}

		float4 mod289(float4 x)
		{
			return x - floor(x * NOISE_SIMPLEX_1_DIV_289) * 289.0;
		}


		// ( x*34.0 + 1.0 )*x = 
		// x*x*34.0 + x
		float permute(float x)
		{
			return mod289(x*x*34.0 + x);
		}

		float3 permute(float3 x)
		{
			return mod289(x*x*34.0 + x);
		}

		float4 permute(float4 x)
		{
			return mod289(x*x*34.0 + x);
		}

		float snoise(float3 v)
		{
			const float2 C = float2(
				0.166666666666666667, // 1/6
				0.333333333333333333  // 1/3
			);
			const float4 D = float4(0.0, 0.5, 1.0, 2.0);
	
			// First corner
			float3 i = floor( v + dot(v, C.yyy) );
			float3 x0 = v - i + dot(i, C.xxx);
	
			// Other corners
			float3 g = step(x0.yzx, x0.xyz);
			float3 l = 1 - g;
			float3 i1 = min(g.xyz, l.zxy);
			float3 i2 = max(g.xyz, l.zxy);
	
			float3 x1 = x0 - i1 + C.xxx;
			float3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
			float3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y
	
			// Permutations
			i = mod289(i);
			float4 p = permute(
				permute(
					permute(
						i.z + float4(0.0, i1.z, i2.z, 1.0 )
					) + i.y + float4(0.0, i1.y, i2.y, 1.0 )
				) 	+ i.x + float4(0.0, i1.x, i2.x, 1.0 )
			);
	
			// Gradients: 7x7 points over a square, mapped onto an octahedron.
			// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
			float n_ = 0.142857142857; // 1/7
			float3 ns = n_ * D.wyz - D.xzx;
	
			float4 j = p - 49.0 * floor(p * ns.z * ns.z); // mod(p,7*7)
	
			float4 x_ = floor(j * ns.z);
			float4 y_ = floor(j - 7.0 * x_ ); // mod(j,N)
	
			float4 x = x_ *ns.x + ns.yyyy;
			float4 y = y_ *ns.x + ns.yyyy;
			float4 h = 1.0 - abs(x) - abs(y);
	
			float4 b0 = float4( x.xy, y.xy );
			float4 b1 = float4( x.zw, y.zw );
	
			float4 s0 = floor(b0)*2.0 + 1.0;
			float4 s1 = floor(b1)*2.0 + 1.0;
			float4 sh = -step(h, 0.0);
	
			float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
			float4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;
	
			float3 p0 = float3(a0.xy,h.x);
			float3 p1 = float3(a0.zw,h.y);
			float3 p2 = float3(a1.xy,h.z);
			float3 p3 = float3(a1.zw,h.w);
	
			//Normalise gradients
			float4 norm = rsqrt(float4(
				dot(p0, p0),
				dot(p1, p1),
				dot(p2, p2),
				dot(p3, p3)
			));
			p0 *= norm.x;
			p1 *= norm.y;
			p2 *= norm.z;
			p3 *= norm.w;
	
			// Mix final noise value
			float4 m = max(
				0.6 - float4(
				dot(x0, x0),
				dot(x1, x1),
				dot(x2, x2),
				dot(x3, x3)
			),
			0.0
			);
			m = m * m;
			return 42.0 * dot(
				m*m,
				float4(
					dot(p0, x0),
					dot(p1, x1),
					dot(p2, x2),
					dot(p3, x3)
				)
			);
		}

		float turbulence(float3 pos)
		{
			return (snoise(pos) + snoise(pos * 2.f) / 2.f + snoise(pos * 4.f) / 4.f) * 4.f / 7.f;
		}

		float3 marble(float3 pos)
		{
			float3 marble_dir = float3(3.f, 2.f, 1.f);
			float wave_pos = dot(marble_dir, pos) * 2.f + turbulence(pos) * 5.f;
			float sine_val = (1.f + sin(wave_pos)) * 0.5f;
			sine_val = pow(sine_val, 0.5f);
			return float3(0.556f, 0.478f, 0.541f) * sine_val;
		}


		static const float dist_eps = 0.001f;
		static const float grad_eps = 0.001f;
		static const float3 lighting_dir = normalize(float3(-3.f, -1.f, 2.f));

		float sdSphere(float3 p, float r)
		{
			return length(p) - r;
		}

		float sdBox(float3 p, float3 size)
		{
			float3 q = abs(p) - size;
			return length(max(q, 0.f)) + min(max(q.x, max(q.y, q.z)), 0.f);
		}

		float smin( float a, float b, float k )
		{
			float h = clamp(0.5f + 0.5f * (b - a) / k, 0.f, 1.f);
			return lerp(b, a, h) - k * h * (1.f - h);
		}

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

				bool center = true;
				if (abspos.y > 1.f / 3.f)
				{
					abspos.y -= 2.f / 3.f;
					center = false;
				}
				if (abspos.z > 1.f / 3.f)
				{
					abspos.z -= 2.f / 3.f;
					center = false;
				}

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
			float d1 = sdBox(p, float3(1.f, 1.f, 1.f));
			float d2 = sdSphere(p - float3(0.f, 2.f, 0.f), 1.f);
			return smin(d1, d2, 0.5f);

			//return fractal(p, 2);
		}

		float map_debug(float3 p, out bool color_distance)
		{
			float distance_cut_plane = -p.z;
			float distance_scene = map(p);
			if (distance_cut_plane < distance_scene || true)
			{
				color_distance = true;
				return distance_cut_plane;
			}
			else
			{
				color_distance = false;
				return distance_scene;
			}
		}

		float3 grad(float3 p, float baseline)
		{
			float d1 = map(p - float3(grad_eps, 0.f, 0.f)) - baseline;
			float d2 = map(p - float3(0.f, grad_eps, 0.f)) - baseline;
			float d3 = map(p - float3(0.f, 0.f, grad_eps)) - baseline;
			return normalize(float3(d1, d2, d3));
		}

		void ps_main(ps_input input, out ps_output output)
		{
			float3 dir = normalize(front_vec + input.screenpos.x * right_vec + input.screenpos.y * top_vec);

			float3 pos = eye;
			float3 col = float3(0.1f, 0.1f, 0.f);
			bool color_distance = false;
			float ruler_scale = 0.2f;
			for (uint iter = 0; iter < 100; ++iter)
			{
				float d = map_debug(pos, color_distance);
				if (d < dist_eps)
				{
					if (color_distance)
					{
						float scene_distance = map(pos);
						float int_steps;
						float frac_steps = abs(modf(scene_distance / ruler_scale, int_steps)) * 1.2f;
						float band_steps = modf(int_steps / 5.f, int_steps);
						
						float3 band_color = band_steps > 0.7f ? float3(1.f, 0.25f, 0.25f) : float3(0.75f, 0.75f, 1.f);
						col = frac_steps < 1.f ? frac_steps * frac_steps * float3(1.f, 1.f, 1.f) : band_color;
						col.g = scene_distance < 0.f ? (scene_distance > -0.01f ? 1.f : 0.f) : col.g;
					}
					else
					{
						float3 normal = grad(pos, d);
						float diffuse_shading = clamp(dot(normal, lighting_dir), 0.f, 1.f);
						float3 specular_ref = reflect(lighting_dir, normal);
						float specular_shading = pow(saturate(dot(specular_ref, -dir)), 12.f);
						float3 marble_color = marble(pos);
						float3 specular_color = float3(1.f, 1.f, 1.f);

						col = marble_color * diffuse_shading + specular_color * specular_shading;
					}
					break;
				}
				pos += dir * d;
			}

			output.color = float4(col, 1.f);
		};
	)r1y";

	UINT flags =
#ifdef _DEBUG
		D3DCOMPILE_DEBUG |
#endif
		0;

	Comptr<ID3DBlob> v_compiled, v_error;
	D3DCompile(v_code, strlen(v_code), "vshader", nullptr, nullptr, "vs_main", "vs_5_0", flags, 0, &v_compiled, &v_error);
	if (v_error)
	{
		auto title = v_compiled ? "Warning" : "Error";
		auto style = v_compiled ? MB_ICONWARNING : MB_ICONERROR;
		MessageBox(0, static_cast<const char *>(v_error->GetBufferPointer()), title, style);
	}
	if (!v_compiled)
	{
		return false;
	}

	Comptr<ID3DBlob> p_compiled, p_error;
	D3DCompile(p_code, strlen(p_code), "pshader", nullptr, nullptr, "ps_main", "ps_5_0", flags, 0, &p_compiled, &p_error);
	if (p_error)
	{
		auto title = p_compiled ? "Warning" : "Error";
		auto style = p_compiled ? MB_ICONWARNING : MB_ICONERROR;
		MessageBox(0, static_cast<const char *>(p_error->GetBufferPointer()), title, style);
	}
	if (!p_compiled)
	{
		return false;
	}

	auto device = graphics->GetDevice();
	HRESULT hr = device->CreateVertexShader(v_compiled->GetBufferPointer(), v_compiled->GetBufferSize(), 0, &v_shader);
	if (FAILED(hr))
		return false;

	hr = device->CreatePixelShader(p_compiled->GetBufferPointer(), p_compiled->GetBufferSize(), 0, &p_shader);
	if (FAILED(hr))
		return false;
	
	auto context = graphics->GetContext();
	context->VSSetShader(v_shader, nullptr, 0);
	context->PSSetShader(p_shader, nullptr, 0);

	// build the input assembler
	D3D11_INPUT_ELEMENT_DESC input_desc[] =
	{
		{"POSITION", 0, DXGI_FORMAT_R32G32_FLOAT, 0, D3D11_APPEND_ALIGNED_ELEMENT, D3D11_INPUT_PER_VERTEX_DATA, 0},
	};

	hr = device->CreateInputLayout(input_desc, static_cast<UINT>(std::size(input_desc)), v_compiled->GetBufferPointer(), v_compiled->GetBufferSize(), &input_layout);
	if (FAILED(hr))
		return false;

	context->IASetInputLayout(input_layout);

	return true;
}


bool Application::initGeometry()
{
	auto device = graphics->GetDevice();
	
	Vertex vertices[4] =
	{
		{-1.f, +1.f},
		{+1.f, +1.f},
		{-1.f, -1.f},
		{+1.f, -1.f},
	};

	D3D11_BUFFER_DESC vertex_buffer_desc = { 0 };
	vertex_buffer_desc.StructureByteStride = sizeof(Vertex);
	vertex_buffer_desc.ByteWidth = static_cast<UINT>(sizeof(Vertex) * std::size(vertices));
	vertex_buffer_desc.BindFlags = D3D11_BIND_VERTEX_BUFFER;
	vertex_buffer_desc.Usage = D3D11_USAGE_DEFAULT;

	D3D11_SUBRESOURCE_DATA vertex_init_data = { 0 };
	vertex_init_data.pSysMem = vertices;
	HRESULT hr = device->CreateBuffer(&vertex_buffer_desc, &vertex_init_data, &vertex_buffer);
	if (FAILED(hr))
		return false;

	using Index = unsigned short;
	Index indices[] =
	{
		0, 1, 2, 2, 1, 3,
	};

	D3D11_BUFFER_DESC index_buffer_desc = { 0 };
	index_buffer_desc.StructureByteStride = sizeof(Index);
	index_buffer_desc.ByteWidth = static_cast<UINT>(sizeof(Index) * std::size(indices));
	index_buffer_desc.BindFlags = D3D11_BIND_INDEX_BUFFER;
	index_buffer_desc.Usage = D3D11_USAGE_DEFAULT;

	D3D11_SUBRESOURCE_DATA index_init_data = { 0 };
	index_init_data.pSysMem = indices;
	hr = device->CreateBuffer(&index_buffer_desc, &index_init_data, &index_buffer);
	if (FAILED(hr))
		return false;

	D3D11_BUFFER_DESC cbuffer_desc = { 0 };
	cbuffer_desc.ByteWidth = sizeof(camera_cbuffer);
	cbuffer_desc.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
	cbuffer_desc.Usage = D3D11_USAGE_DYNAMIC;
	cbuffer_desc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
	hr = device->CreateBuffer(&cbuffer_desc, nullptr, &camera_buffer);
	if (FAILED(hr))
		return false;

	return true;
}


void Application::render()
{
	float clear_color[4] = {0.2f, 0.f, 0.f, 0.f};
	auto ctx = graphics->GetContext();
	ctx->ClearRenderTargetView(graphics->GetMainRendertargetView(), clear_color);
	ctx->ClearDepthStencilView(graphics->GetMainDepthStencilView(), D3D11_CLEAR_DEPTH | D3D11_CLEAR_STENCIL, 1.f, 0);

	D3D11_MAPPED_SUBRESOURCE sub;
	ctx->Map(camera_buffer, 0, D3D11_MAP_WRITE_DISCARD, 0, &sub);
	camera_cbuffer *cam_buf = static_cast<camera_cbuffer *>(sub.pData);
	cam_buf->eye = camera.GetEye();
	cam_buf->front_vec = camera.GetDirection();
	cam_buf->right_vec = (camera.GetFrustrumEdge(0) - camera.GetFrustrumEdge(3)) * 0.5f;
	cam_buf->top_vec = (camera.GetFrustrumEdge(0) - camera.GetFrustrumEdge(1)) * 0.5f;

	ctx->Unmap(camera_buffer, 0);
	ctx->PSSetConstantBuffers(0, 1, &camera_buffer);

	UINT v_strides[] =
	{
		sizeof(Vertex),
	};
	UINT v_offsets[] =
	{
		0,
	};
	ID3D11Buffer *vertex_buffers[] =
	{
		vertex_buffer,
	};
	ctx->IASetVertexBuffers(0, 1, vertex_buffers, v_strides, v_offsets);
	ctx->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);

	ctx->IASetIndexBuffer(index_buffer, DXGI_FORMAT_R16_UINT, 0);

	ctx->DrawIndexed(6, 0, 0);

	graphics->Present();
	graphics->WaitForVBlank();
}


void Application::updateSimulation(float dt)
{
	stime += dt;

	Vector3 move = Vector3::NullVector();
	if (keystate['W'])
	{
		move += Vector3(0.f, 0.f, +1.f);
	}
	if (keystate['S'])
	{
		move += Vector3(0.f, 0.f, -1.f);
	}
	if (keystate['A'])
	{
		move += Vector3(-1.f, 0.f, 0.f);
	}
	if (keystate['D'])
	{
		move += Vector3(+1.f, 0.f, 0.f);
	}
	if (keystate['Q'])
	{
		move += Vector3(0.f, +1.f, 0.f);
	}
	if (keystate['E'])
	{
		move += Vector3(0.f, -1.f, 0.f);
	}

	camera.MoveRel(move * dt);
}
