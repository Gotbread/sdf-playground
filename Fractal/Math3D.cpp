#include <math.h>

#define D3DVECTOR_DEFINED
#define D3DMATRIX_DEFINED

struct D3DXVECTOR2;
struct D3DXVECTOR3;
struct D3DXVECTOR4;
struct D3DXMATRIX;

#include "Math3D.h"

namespace Math3D
{
	bool EqualsZero(float a, float epsilon = 8e-7f)
	{
		return fabs(a) < epsilon;
	}

	bool Equal(float a, float b)
	{
		int a_uint = *reinterpret_cast<int*>(&a);
		int b_uint = *reinterpret_cast<int*>(&b);
		if ((a_uint & (1 << 31)) != (b_uint & (1 << 31)))
		{
			return a == b;
		}

		return (abs(a_uint - b_uint) <= 4);
	}

	bool SafeEqual(float a, float b)
	{
		if (b < a)
		{
			float temp = a;
			a = b;
			b = temp;
		}
		if (EqualsZero(a, 0.01f))
			return EqualsZero(a - b);
		return Equal(a, b);
	}

	Vector2::Vector2()
	{
	}
	Vector2::Vector2(const Vector2 &other) : x(other.x), y(other.y)
	{
	}
	Vector2::Vector2(float _x, float _y) : x(_x), y(_y)
	{
	}
	Vector2::Vector2(const float *pf) : x(pf[0]), y(pf[1])
	{
	}
	Vector2::Vector2(const D3DXVECTOR2 &other) :
		x(reinterpret_cast<const float *>(&other)[0]), y(reinterpret_cast<const float *>(&other)[1])
	{
	}
	Vector2::operator D3DXVECTOR2 & ()
	{
		return reinterpret_cast<D3DXVECTOR2 &>(*this);
	}
	Vector2::operator const D3DXVECTOR2 & () const
	{
		return reinterpret_cast<const D3DXVECTOR2 &>(*this);
	}
	Vector2 Vector2::NullVector()
	{
		return Vector2(0.f, 0.f);
	}
	Vector2 Vector2::operator = (const Vector2 &other)
	{
		x = other.x;
		y = other.y;
		return *this;
	}
	Vector2 Vector2::operator + () const
	{
		return *this;
	}
	Vector2 Vector2::operator - () const
	{
		Vector2 vec(-x, -y);
		return vec;
	}
	Vector2 Vector2::operator * (float s) const
	{
		Vector2 vec(x * s, y * s);
		return vec;
	}
	Vector2 Vector2::operator / (float s) const
	{
		s = 1.f / s;
		Vector2 vec(x * s, y * s);
		return vec;
	}
	Vector2 Vector2::operator + (const Vector2 &other) const
	{
		Vector2 vec(x + other.x, y + other.y);
		return vec;
	}
	Vector2 Vector2::operator - (const Vector2 &other) const
	{
		Vector2 vec(x - other.x, y - other.y);
		return vec;
	}
	Vector2 &Vector2::operator += (const Vector2 &other)
	{
		x += other.x;
		y += other.y;
		return *this;
	}
	Vector2 &Vector2::operator -= (const Vector2 &other)
	{
		x -= other.x;
		y -= other.y;
		return *this;
	}
	Vector2 &Vector2::operator *= (float s)
	{
		x *= s;
		y *= s;
		return *this;
	}
	Vector2 &Vector2::operator /= (float s)
	{
		s = 1.f / s;
		x *= s;
		y *= s;
		return *this;
	}
	float Vector2::operator * (const Vector2 &other) const
	{
		return x * other.x + y * other.y;
	}
	float &Vector2::operator [] (unsigned index)
	{
		return v[index];
	}
	float Vector2::operator [] (unsigned index) const
	{
		return v[index];
	}
	void Vector2::Normalize()
	{
		float scale = 1.f / sqrtf(x * x + y * y);
		x *= scale;
		y *= scale;
	}
	Vector2 Vector2::Normalized() const
	{
		float scale = 1.f / sqrtf(x * x + y * y);
		return Vector2(x * scale, y * scale);
	}
	float Vector2::LengthSq() const
	{
		return x * x + y * y;
	}
	float Vector2::Length() const
	{
		return sqrtf(x * x + y * y);
	}
	Vector2 operator * (float s, const Vector2 &other)
	{
		return other * s;
	}
	////////////////////////////////////////////////////////
	Vector3::Vector3()
	{
	}
	Vector3::Vector3(const Vector3 &other) : x(other.x), y(other.y), z(other.z)
	{
	}
	Vector3::Vector3(float _x, float _y, float _z) : x(_x), y(_y), z(_z)
	{
	}
	Vector3::Vector3(const float *pf) : x(pf[0]), y(pf[1]), z(pf[2])
	{
	}
	Vector3::Vector3(const D3DXVECTOR3 &other) :
		x(reinterpret_cast<const float *>(&other)[0]),
		y(reinterpret_cast<const float *>(&other)[1]),
		z(reinterpret_cast<const float *>(&other)[2])
	{
	}
	Vector3::operator D3DXVECTOR3 &()
	{
		return reinterpret_cast<D3DXVECTOR3 &>(*this);
	}
	Vector3::operator const D3DXVECTOR3 &() const
	{
		return reinterpret_cast<const D3DXVECTOR3 &>(*this);
	}
	Vector3 Vector3::NullVector()
	{
		return Vector3(0.f, 0.f, 0.f);
	}
	Vector3 Vector3::operator = (const Vector3 &other)
	{
		x = other.x;
		y = other.y;
		z = other.z;
		return *this;
	}
	Vector3 Vector3::operator + () const
	{
		return *this;
	}
	Vector3 Vector3::operator - () const
	{
		Vector3 vec(-x, -y, -z);
		return vec;
	}
	Vector3 Vector3::operator * (float s) const
	{
		Vector3 vec(x * s, y * s, z * s);
		return vec;
	}
	Vector3 Vector3::operator / (float s) const
	{
		s = 1.f / s;
		Vector3 vec(x * s, y * s, z * s);
		return vec;
	}
	Vector3 Vector3::operator + (const Vector3 &other) const
	{
		Vector3 vec(x + other.x, y + other.y, z + other.z);
		return vec;
	}
	Vector3 Vector3::operator - (const Vector3 &other) const
	{
		Vector3 vec(x - other.x, y - other.y, z - other.z);
		return vec;
	}
	Vector3 &Vector3::operator += (const Vector3 &other)
	{
		x += other.x;
		y += other.y;
		z += other.z;
		return *this;
	}
	Vector3 &Vector3::operator -= (const Vector3 &other)
	{
		x -= other.x;
		y -= other.y;
		z -= other.z;
		return *this;
	}
	Vector3 &Vector3::operator *= (float s)
	{
		x *= s;
		y *= s;
		z *= s;
		return *this;
	}
	Vector3 &Vector3::operator /= (float s)
	{
		s = 1.f / s;
		x *= s;
		y *= s;
		z *= s;
		return *this;
	}
	float Vector3::operator * (const Vector3 &other) const
	{
		return x * other.x + y * other.y + z * other.z;
	}
	float &Vector3::operator [] (unsigned index)
	{
		return v[index];
	}
	float Vector3::operator [] (unsigned index) const
	{
		return v[index];
	}
	bool Vector3::operator==(const Vector3& other) const
	{
		return SafeEqual(x, other.x) && SafeEqual(z, other.z) && SafeEqual(y, other.y);
	}
	bool Vector3::operator!=(const Vector3& other) const
	{
		return !(*this == other);
	}
	Vector3 Vector3::operator ^ (const Vector3 &other) const
	{
		return Vector3(y * other.z - z * other.y, z * other.x - x * other.z, x * other.y - y * other.x);
	}
	void Vector3::Normalize()
	{
		float s = 1.f / sqrtf(x * x + y * y + z * z);
		x *= s;
		y *= s;
		z *= s;
	}
	Vector3 Vector3::Normalized() const
	{
		float s = 1.f / sqrtf(x * x + y * y + z * z);
		Vector3 vec(x * s, y * s, z * s);
		return vec;
	}
	float Vector3::LengthSq() const
	{
		return x * x + y * y + z * z;
	}
	float Vector3::Length() const
	{
		return sqrtf(x * x + y * y + z * z);
	}
	bool Vector3::EqualsZero() const
	{
		// NOTE: if you need a == b
		// don't do EqualsZero(a - b)
		// use Equal(a, b) instead!
		return Math3D::EqualsZero(x) && Math3D::EqualsZero(z), Math3D::EqualsZero(y);
	}
	bool Vector3::Equal(const Vector3& other) const
	{
		return Math3D::Equal(x, other.x) && Math3D::Equal(z, other.z) && Math3D::Equal(y, other.y);
	}
	Vector3 operator * (float s, const Vector3 &other)
	{
		return other * s;
	}
	//////////////////////////////////////////////////////////
	Vector4::Vector4()
	{
	}
	Vector4::Vector4(const Vector4 &other) : x(other.x), y(other.y), z(other.z), w(other.w)
	{
	}
	Vector4::Vector4(float p_x, float p_y, float p_z, float p_w) : x(p_x), y(p_y), z(p_z), w(p_w)
	{
	}
	Vector4::Vector4(const float *pf) : x(pf[0]), y(pf[1]), z(pf[2]), w(pf[3])
	{
	}
	Vector4::Vector4(const D3DXVECTOR4 &other) :
		x(reinterpret_cast<const float *>(&other)[0]),
		y(reinterpret_cast<const float *>(&other)[1]),
		z(reinterpret_cast<const float *>(&other)[2]),
		w(reinterpret_cast<const float *>(&other)[3])
	{
	}
	Vector4::operator D3DXVECTOR4 &()
	{
		return reinterpret_cast<D3DXVECTOR4 &>(*this);
	}
	Vector4::operator const D3DXVECTOR4 &() const
	{
		return reinterpret_cast<const D3DXVECTOR4 &>(*this);
	}
	Vector4 Vector4::NullVector()
	{
		return Vector4(0.f, 0.f, 0.f, 0.f);
	}
	Vector4 Vector4::operator = (const Vector4 &other)
	{
		x = other.x;
		y = other.y;
		z = other.z;
		w = other.w;
		return *this;
	}
	Vector4 Vector4::operator + () const
	{
		return *this;
	}
	Vector4 Vector4::operator - () const
	{
		Vector4 vec(-x, -y, -z, -w);
		return vec;
	}
	Vector4 Vector4::operator * (float s) const
	{
		Vector4 vec(x * s, y * s, z * s, w * s);
		return vec;
	}
	Vector4 Vector4::operator / (float s) const
	{
		s = 1.f / s;
		Vector4 vec(x * s, y * s, z * s, w *s);
		return vec;
	}
	Vector4 Vector4::operator + (const Vector4 &other) const
	{
		Vector4 vec(x + other.x, y + other.y, z + other.z, w + other.w);
		return vec;
	}
	Vector4 Vector4::operator - (const Vector4 &other) const
	{
		Vector4 vec(x - other.x, y - other.y, z - other.z, w - other.w);
		return vec;
	}
	Vector4 &Vector4::operator += (const Vector4 &other)
	{
		x += other.x;
		y += other.y;
		z += other.z;
		w += other.w;
		return *this;
	}
	Vector4 &Vector4::operator -= (const Vector4 &other)
	{
		x -= other.x;
		y -= other.y;
		z -= other.z;
		w -= other.w;
		return *this;
	}
	Vector4 &Vector4::operator *= (float s)
	{
		x *= s;
		y *= s;
		z *= s;
		w *= s;
		return *this;
	}
	Vector4 &Vector4::operator /= (float s)
	{
		s = 1.f / s;
		x *= s;
		y *= s;
		z *= s;
		w *= s;
		return *this;
	}
	float Vector4::operator * (const Vector4 &other) const
	{
		return x * other.x + y * other.y + z * other.z + w * other.w;
	}
	float &Vector4::operator [] (unsigned index)
	{
		return v[index];
	}
	float Vector4::operator [] (unsigned index) const
	{
		return v[index];
	}
	bool Vector4::operator == (const Vector4 &other) const
	{
		return !(*this != other);
	}
	bool Vector4::operator != (const Vector4 &other) const
	{
		if (x != other.x) return true;
		if (y != other.y) return true;
		if (z != other.z) return true;
		if (w != other.w) return true;
		return false;
	}
	void Vector4::Normalize()
	{
		float s = 1.f / sqrtf(x * x + y * y + z * z + w * w);
		x *= s;
		y *= s;
		z *= s;
		w *= s;
	}
	Vector4 Vector4::Normalized() const
	{
		float s = 1.f / sqrtf(x * x + y * y + z * z + w * w);
		Vector4 vec(x * s, y * s, z * s, w * s);
		return vec;
	}
	float Vector4::LengthSq() const
	{
		return x * x + y * y + z * z + w * w;
	}
	float Vector4::Length() const
	{
		return sqrtf(x * x + y * y + z * z + w * w);
	}
	bool Vector4::EqualsZero() const
	{
		float epsilon = 1e-6f;
		return (fabs(x) < epsilon && fabs(y) < epsilon && fabs(z) < epsilon && fabsf(z) < epsilon);
	}
	Vector4 operator * (float s, const Vector4 &other)
	{
		return other * s;
	}
	//////////////////////////////////////////////////////////
	Quaternion::Quaternion()
	{
		w=1.f;
		x=0.f;
		y=0.f;
		z=0.f;
	}

	Quaternion::Quaternion(const Quaternion& copy)
	{
		w=copy.w;
		x=copy.x;
		y=copy.y;
		z=copy.z;
	}

	Quaternion::Quaternion(float w_, float x_, float y_, float z_)
	{
		w=w_;
		x=x_;
		y=y_;
		z=z_;
		Normalize();
	}

	Quaternion::Quaternion(const Math3D::Vector3& other)
	{
		w=0.f;
		x=other.x;
		y=other.y;
		z=other.z;
		Normalize();
	}

	Quaternion::Quaternion(const Math3D::Vector3& other, float angle)
	{
		w=cosf(angle*0.5f);
		const float scale=sinf(angle*0.5f);
		x=other.x*scale;
		y=other.y*scale;
		z=other.z*scale;
		Normalize();
	}

	Quaternion::Quaternion(const float* f)
	{
		v[0]=f[0];
		v[1]=f[1];
		v[2]=f[2];
		v[3]=f[3];
	}

	Quaternion Quaternion::NullQuaternion()
	{
		return Quaternion(1.0f, 0.0f, 0.0f, 0.0f);
	}

	Quaternion& Quaternion::operator=(const Quaternion& other)
	{
		w=other.w;
		x=other.x;
		y=other.y;
		z=other.z;
		return *this;
	}

	Quaternion Quaternion::operator-() const
	{
		return Quaternion(w,-x,-y,-z);
	}

	Quaternion Quaternion::operator+(const Quaternion& other) const
	{
		return Quaternion(w+other.w,x+other.x,y+other.y,z+other.z);
	}

	Quaternion Quaternion::operator-(const Quaternion& other) const
	{
		return Quaternion(w-other.w,x-other.x,y-other.y,z-other.z);
	}

	Quaternion Quaternion::operator*(const Quaternion& other) const
	{
		return Quaternion(
			w * other.w - x * other.x - y * other.y - z * other.z,
			w * other.x + x * other.w + y * other.z - z * other.y,
			w * other.y - x * other.z + y * other.w + z * other.x,
			w * other.z + x * other.y - y * other.x + z * other.w
			);
	}

	Quaternion Quaternion::operator/(const Quaternion& other) const
	{
		return (*this)*other.Inverse();
	}

	Quaternion& Quaternion::operator+=(const Quaternion& other)
	{
		w+=other.w;
		x+=other.x;
		y+=other.y;
		z+=other.z;
		return *this;
	}

	Quaternion& Quaternion::operator-=(const Quaternion& other)
	{
		w-=other.w;
		x-=other.x;
		y-=other.y;
		z-=other.z;
		return *this;
	}

	Quaternion& Quaternion::operator*=(const Quaternion& other)
	{
		*this=(*this)*other;
		return *this;
	}

	Quaternion& Quaternion::operator/=(const Quaternion& other)
	{
		*this=(*this)/other;
		return *this;
	}

	Math3D::Vector3 Quaternion::operator*(const Vector3& other) const
	{
		Vector3 r1(.5f-y*y-z*z,		x*y-w*z,		x*z+w*y);
		Vector3 r2(x*y+w*z,			.5f-x*x-z*z,	y*z+w*x);
		Vector3 r3(x*z-w*y,			y*z-w*x,		.5f-x*x-y*y);
		return Vector3(2.f*(r1*other),2.f*(r2*other),2.f*(r3*other));
	}

	void Quaternion::Normalize()
	{
		float scale=1.f/sqrtf(w*w+x*x+y*y+z*z);
		w*=scale;
		x*=scale;
		y*=scale;
		z*=scale;
	}

	Quaternion Quaternion::Normalized() const
	{
		float scale=1.f/sqrtf(w*w+x*x+y*y+z*z);
		return Quaternion(w*scale,x*scale,y*scale,z*scale);
	}

	float Quaternion::LengthSq() const
	{
		return w*w+x*x+y*y+z*z;
	}

	float Quaternion::Length() const
	{
		return sqrtf(w*w+x*x+y*y+z*z);
	}

	Quaternion Quaternion::Inverse() const
	{
		return -(*this).Normalized();
	}

	float  Quaternion::GetRealPart() const
	{
		return w;
	}

	Vector3  Quaternion::GetScalarPart() const
	{
		return Vector3(x,y,z);
	}

	Matrix4x4 Quaternion::GetMatrixRepresentation() const
	{
		return Matrix4x4(
			w,	 x,	 y,	 z,
			-x,	 w,	-z,	 y,
			-y,	 z,	 w,	-x,
			-z,	-y,	 x,	 w
			);
	}
	//////////////////////////////////////////////////////////
	Plane::Plane()
	{
	}
	Plane::Plane(const Plane &other) : a(other.a), b(other.b), c(other.c), d(other.d)
	{
	}
	Plane::Plane(const Vector4 &vec) : a(vec.x), b(vec.y), c(vec.z), d(vec.w)
	{
	}
	Plane::Plane(float p_a, float p_b, float p_c, float p_d) : a(p_a), b(p_b), c(p_c), d(p_d)
	{
	}
	Plane::Plane(const float *ptr) : a(ptr[0]), b(ptr[1]), c(ptr[2]), d(ptr[3])
	{
	}
	void Plane::Normalize()
	{
		float inv_length = 1.f / sqrtf(a * a + b * b + c * c);
		a *= inv_length;
		b *= inv_length;
		c *= inv_length;
		d *= inv_length;
	}
	Plane Plane::Normalized() const
	{
		float inv_length = 1.f / sqrtf(a * a + b * b + c * c);
		return Plane(a * inv_length, b * inv_length, c * inv_length, d * inv_length);
	}
	float Plane::IntersectLine(const Vector3 &vec1, const Vector3 &vec2) const
	{
		return (a * vec1.x + b * vec1.y + c * vec1.z + d) / (a * vec1.x + b * vec1.y + c * vec1.z - a * vec2.x - b * vec2.y - c * vec2.z);
	}
	float Plane::DistanceFromPoint(const Vector3 &p) const
	{
		return a * p.x + b * p.y + c * p.z + d;
	}
	//////////////////////////////////////////////////////////
	Matrix4x4::Matrix4x4()
	{
	}
	Matrix4x4::Matrix4x4(const Matrix4x4 &other) :
	f11(other.f11), f12(other.f12), f13(other.f13), f14(other.f14),
		f21(other.f21), f22(other.f22), f23(other.f23), f24(other.f24),
		f31(other.f31), f32(other.f32), f33(other.f33), f34(other.f34),
		f41(other.f41), f42(other.f42), f43(other.f43), f44(other.f44)
	{
	}
	Matrix4x4::Matrix4x4(float _f11, float _f12, float _f13, float _f14,
				float _f21, float _f22, float _f23, float _f24,
				float _f31, float _f32, float _f33, float _f34,
				float _f41, float _f42, float _f43, float _f44) :
	f11(_f11), f12(_f12), f13(_f13), f14(_f14), f21(_f21), f22(_f22), f23(_f23), f24(_f24),
		f31(_f31), f32(_f32), f33(_f33), f34(_f34), f41(_f41), f42(_f42), f43(_f43), f44(_f44)
	{
	}
	Matrix4x4::Matrix4x4(const float *fp) :
	f11(fp[0]), f12(fp[1]), f13(fp[2]), f14(fp[3]), f21(fp[4]), f22(fp[5]), f23(fp[6]), f24(fp[7]),
		f31(fp[8]), f32(fp[9]), f33(fp[10]), f34(fp[11]), f41(fp[12]), f42(fp[13]), f43(fp[14]), f44(fp[15])
	{
	}
	Matrix4x4::Matrix4x4(const D3DXMATRIX &other)
	{
		const float *src = reinterpret_cast<const float *>(&other);
		for (unsigned i = 0; i < 16; ++i)
			m[0][i] = *src++;
	}
	Matrix4x4::operator D3DXMATRIX &()
	{
		return reinterpret_cast<D3DXMATRIX &>(*this);
	}
	Matrix4x4::operator const D3DXMATRIX &() const
	{
		return reinterpret_cast<const D3DXMATRIX &>(*this);
	}
	Matrix4x4 Matrix4x4::NullMatrix()
	{
		return Matrix4x4(0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f);
	}
	Matrix4x4 Matrix4x4::IdentityMatrix()
	{
		return Matrix4x4(1.f, 0.f, 0.f, 0.f, 0.f, 1.f, 0.f, 0.f, 0.f, 0.f, 1.f, 0.f, 0.f, 0.f, 0.f, 1.f);
	}
	Matrix4x4 Matrix4x4::RotationXMatrix(float angle)
	{
		float c = cosf(angle);
		float s = sinf(angle);
		return Matrix4x4(1.f, 0.f, 0.f, 0.f, 0.f, c, s, 0.f, 0.f, -s, c, 0.f, 0.f, 0.f, 0.f, 1.f);
	}
	Matrix4x4 Matrix4x4::RotationYMatrix(float angle)
	{
		float c = cosf(angle);
		float s = sinf(angle);
		return Matrix4x4(c, 0.f, -s, 0.f, 0.f, 1.f, 0.f, 0.f, s, 0.f, c, 0.f, 0.f, 0.f, 0.f, 1.f);
	}
	Matrix4x4 Matrix4x4::RotationZMatrix(float angle)
	{
		float c = cosf(angle);
		float s = sinf(angle);
		return Matrix4x4(c, s, 0.f, 0.f, -s, c, 0.f, 0.f, 0.f, 0.f, 1.f, 0.f, 0.f, 0.f, 0.f, 1.f);
	}
	Matrix4x4 Matrix4x4::RotationAxisMatrix(const Vector3 &axis, float angle)
	{
		float c = cosf(angle);
		float s = sinf(angle);
		float inv_c = 1.f - c;
		Vector3 n = axis.Normalized();
		Matrix4x4 ret;

		ret[0][0] = inv_c * n.x * n.x + c;
		ret[1][0] = inv_c * n.x * n.y - s * n.z;
		ret[2][0] = inv_c * n.x * n.z + s * n.y;
		ret[0][1] = inv_c * n.y * n.x + s * n.z;
		ret[1][1] = inv_c * n.y * n.y + c;
		ret[2][1] = inv_c * n.y * n.z - s * n.x;
		ret[0][2] = inv_c * n.z * n.x - s * n.y;
		ret[1][2] = inv_c * n.z * n.y + s * n.x;
		ret[2][2] = inv_c * n.z * n.z + c;
		ret[0][3] = 0.f;
		ret[1][3] = 0.f;
		ret[2][3] = 0.f;
		ret[3][0] = 0.f;
		ret[3][1] = 0.f;
		ret[3][2] = 0.f;
		ret[3][3] = 1.f;

		return ret;
	}
	Matrix4x4 Matrix4x4::TranslateMatrix(float x, float y, float z)
	{
		return Matrix4x4(1.f, 0.f, 0.f, 0.f, 0.f, 1.f, 0.f, 0.f, 0.f, 0.f, 1.f, 0.f, x, y, z, 1.f);
	}
	Matrix4x4 Matrix4x4::TranslateMatrix(const Vector3 &mov)
	{
		return Matrix4x4(1.f, 0.f, 0.f, 0.f, 0.f, 1.f, 0.f, 0.f, 0.f, 0.f, 1.f, 0.f, mov.x, mov.y, mov.z, 1.f);
	}
	Matrix4x4 Matrix4x4::ScaleMatrix(float x, float y, float z)
	{
		return Matrix4x4(x, 0.f, 0.f, 0.f, 0.f, y, 0.f, 0.f, 0.f, 0.f, z, 0.f, 0.f, 0.f, 0.f, 1.f);
	}
	Matrix4x4 Matrix4x4::CameraMatrix(const Vector3 &eye, const Vector3 &lookat, const Vector3 &up)
	{
		Vector3 zaxis = (lookat - eye).Normalized();
		Vector3 xaxis = (up ^ zaxis).Normalized();
		Vector3 yaxis = zaxis ^ xaxis;
		return Matrix4x4(xaxis.x, yaxis.x, zaxis.x, 0.f, xaxis.y, yaxis.y, zaxis.y, 0.f,
			xaxis.z, yaxis.z, zaxis.z, 0.f, -xaxis * eye, -yaxis * eye, -zaxis * eye, 1.f);
	}
	Matrix4x4 Matrix4x4::ProjectionMatrix(float fovy, float aspect, float zn, float zf)
	{
		float yscale = 1.f / tanf(fovy / 2.f);
		float xscale = yscale / aspect;
		float z = zf / (zf - zn);

		return Matrix4x4(xscale, 0.f, 0.f, 0.f, 0.f, yscale, 0.f, 0.f,
			0.f, 0.f, z, 1.f, 0.f, 0.f, -zn * z, 0.f);
	}
	//enum PlaneIndex {PlaneLeft, PlaneRight, PlaneTop, PlaneBottom, PlaneNear, PlaneFar};
	Plane Matrix4x4::GetClippingPlane(unsigned index) const
	{
		Matrix4x4 trans = Transposed();
		Plane p;
		switch (index)
		{
		case PlaneLeft:		p = Vector4(trans[3]) + Vector4(trans[0]);	break;
		case PlaneRight:	p = Vector4(trans[3]) - Vector4(trans[0]);	break;
		case PlaneTop:		p = Vector4(trans[3]) - Vector4(trans[1]);	break;
		case PlaneBottom:	p = Vector4(trans[3]) + Vector4(trans[1]);	break;
		case PlaneNear:		p = Vector4(trans[3]) + Vector4(trans[2]);	break;
		case PlaneFar:		p = Vector4(trans[3]) - Vector4(trans[2]);	break;
		}
		return p.Normalized();
	}
	Matrix4x4 Matrix4x4::operator = (const Matrix4x4 &other)
	{
		for (unsigned i = 0; i < 16; ++i)
			m[0][i] = other.m[0][i];
		return *this;
	}
	Matrix4x4 Matrix4x4::operator + () const
	{
		return *this;
	}
	Matrix4x4 Matrix4x4::operator - () const
	{
		return Matrix4x4(-f11, -f12, -f13, -f14, -f21, -f22, -f23, -f24,
			-f31, -f32, -f33, -f34, -f41, -f42, -f43, -f44);
	}
	Matrix4x4 Matrix4x4::operator * (float s) const
	{
		return Matrix4x4(f11 * s, f12 * s, f13 * s, f14 * s,
			f21 * s, f22 * s, f23 * s, f24 * s,
			f31 * s, f32 * s, f33 * s, f34 * s,
			f41 * s, f42 * s, f43 * s, f44 * s);
	}
	Matrix4x4 Matrix4x4::operator / (float s) const
	{
		s = 1.f / s;
		return Matrix4x4(f11 * s, f12 * s, f13 * s, f14 * s,
			f21 * s, f22 * s, f23 * s, f24 * s,
			f31 * s, f32 * s, f33 * s, f34 * s,
			f41 * s, f42 * s, f43 * s, f44 * s);
	}
	Matrix4x4 Matrix4x4::operator + (const Matrix4x4 &other) const
	{
		return Matrix4x4(f11 + other.f11, f12 + other.f12, f13 + other.f13, f14 + other.f14,
			f21 + other.f21, f22 + other.f22, f23 + other.f23, f24 + other.f24,
			f31 + other.f31, f32 + other.f32, f33 + other.f33, f34 + other.f34,
			f41 + other.f41, f42 + other.f42, f43 + other.f43, f44 + other.f44);
	}
	Matrix4x4 Matrix4x4::operator - (const Matrix4x4 &other) const
	{
		return Matrix4x4(f11 - other.f11, f12 - other.f12, f13 - other.f13, f14 - other.f14,
			f21 - other.f21, f22 - other.f22, f23 - other.f23, f24 - other.f24,
			f31 - other.f31, f32 - other.f32, f33 - other.f33, f34 - other.f34,
			f41 - other.f41, f42 - other.f42, f43 - other.f43, f44 - other.f44);
	}
	Matrix4x4 &Matrix4x4::operator += (const Matrix4x4 &other)
	{
		for (unsigned i = 0; i < 16; ++i)
			m[0][i] += other.m[0][i];
		return *this;
	}
	Matrix4x4 &Matrix4x4::operator -= (const Matrix4x4 &other)
	{
		for (unsigned i = 0; i < 16; ++i)
			m[0][i] -= other.m[0][i];
		return *this;
	}
	Matrix4x4 &Matrix4x4::operator *= (float s)
	{
		for (unsigned i = 0; i < 16; ++i)
			m[0][i] *= s;
		return *this;
	}
	Matrix4x4 &Matrix4x4::operator /= (float s)
	{
		s = 1.f / s;
		for (unsigned i = 0; i < 16; ++i)
			m[0][i] *= s;
		return *this;
	}
	Matrix4x4 Matrix4x4::operator * (const Matrix4x4 &other) const
	{
		Matrix4x4 ret = NullMatrix();
		for (unsigned i = 0; i < 4; ++i)
			for (unsigned j = 0; j < 4; ++j)
				for (unsigned k = 0; k < 4; ++k)
					ret[i][j] += m[i][k] * other.m[k][j];
		return ret;
	}

	float *Matrix4x4::operator [] (unsigned row)
	{
		return m[0] + row * 4;
	}
	const float *Matrix4x4::operator [] (unsigned row) const
	{
		return m[0] + row * 4;
	}
	void Matrix4x4::Transpose()
	{
		*this = Transposed();
	}
	Matrix4x4 Matrix4x4::Transposed() const
	{
		return Matrix4x4(f11, f21, f31, f41, f12, f22, f32, f42, f13, f23, f33, f43, f14, f24, f34, f44);
	}
	Vector3 Matrix4x4::operator * (const Vector3 &other) const
	{
		float w = f14 * other.x + f24 * other.y + f34 * other.z + f44;
		return Vector3(
			f11 * other.x + f12 * other.y + f13 * other.z + f14,
			f21 * other.x + f22 * other.y + f23 * other.z + f24,
			f31 * other.x + f32 * other.y + f33 * other.z + f34) / w;
	}
}