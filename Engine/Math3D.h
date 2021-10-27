#pragma once

namespace Math3D
{
	class Vector2;
	class Vector3;
	class Quaternion;
	class Plane;
	class Matrix4x4;

	bool EqualsZero(float a, float epsilon);
	bool Equal(float a, float b);
	bool SafeEqual(float a, float b);

	class Vector2
	{
	public:
		Vector2();
		Vector2(const Vector2 &);
		Vector2(float x, float y);
		Vector2(const float *);

#ifdef D3DVECTOR_DEFINED
		Vector2(const D3DXVECTOR2 &);
		operator D3DXVECTOR2 &();
		operator const D3DXVECTOR2 &() const;
#endif

		static Vector2 NullVector();

		Vector2 operator = (const Vector2 &);
		Vector2 operator + () const;
		Vector2 operator - () const;
		Vector2 operator * (float) const;
		Vector2 operator / (float) const;
		Vector2 operator + (const Vector2 &) const;
		Vector2 operator - (const Vector2 &) const;
		Vector2 &operator += (const Vector2 &);
		Vector2 &operator -= (const Vector2 &);
		Vector2 &operator *= (float);
		Vector2 &operator /= (float);
		float operator * (const Vector2 &) const;
		float &operator [] (unsigned);
		float operator [] (unsigned) const;

		void Normalize();
		Vector2 Normalized() const;
		float LengthSq() const;
		float Length() const;
	
		union
		{
			float v[2];
			struct
			{
				float x, y;
			};
		};
	};
	Vector2 operator * (float, const Vector2 &);

	class Vector3
	{
	public:
		Vector3();
		Vector3(const Vector3 &);
		Vector3(float x, float y, float z);
		Vector3(const float *);

#ifdef D3DVECTOR_DEFINED
		Vector3(const D3DXVECTOR3 &);
		operator D3DXVECTOR3 &();
		operator const D3DXVECTOR3 &() const;
#endif

		static Vector3 NullVector();

		Vector3 operator = (const Vector3 &);
		Vector3 operator + () const;
		Vector3 operator - () const;
		Vector3 operator * (float) const;
		Vector3 operator / (float) const;
		Vector3 operator + (const Vector3 &) const;
		Vector3 operator - (const Vector3 &) const;
		Vector3 &operator += (const Vector3 &);
		Vector3 &operator -= (const Vector3 &);
		Vector3 &operator *= (float);
		Vector3 &operator /= (float);
		float operator * (const Vector3 &) const;
		float &operator [] (unsigned);
		float operator [] (unsigned) const;
		bool operator == (const Vector3 &) const;
		bool operator != (const Vector3 &) const;

		Vector3 operator ^ (const Vector3 &other) const;

		void Normalize();
		Vector3 Normalized() const;
		float LengthSq() const;
		float Length() const;
		bool EqualsZero() const;
		bool Equal(const Vector3& other) const;
	
		union
		{
			float v[3];
			struct
			{
				float x, y, z;
			};
		};
	};
	Vector3 operator * (float, const Vector3 &);

	class Vector4
	{
	public:
		Vector4();
		Vector4(const Vector4 &);
		Vector4(float x, float y, float z, float w);
		Vector4(const float *);

#ifdef D3DVECTOR_DEFINED
		Vector4(const D3DXVECTOR4 &);
		operator D3DXVECTOR4 &();
		operator const D3DXVECTOR4 &() const;
#endif

		static Vector4 NullVector();

		Vector4 operator = (const Vector4 &);
		Vector4 operator + () const;
		Vector4 operator - () const;
		Vector4 operator * (float) const;
		Vector4 operator / (float) const;
		Vector4 operator + (const Vector4 &) const;
		Vector4 operator - (const Vector4 &) const;
		Vector4 &operator += (const Vector4 &);
		Vector4 &operator -= (const Vector4 &);
		Vector4 &operator *= (float);
		Vector4 &operator /= (float);
		float operator * (const Vector4 &) const;
		float &operator [] (unsigned);
		float operator [] (unsigned) const;
		bool operator == (const Vector4 &) const;
		bool operator != (const Vector4 &) const;

		//Vector4 operator ^ (const Vector4 &other) const;

		void Normalize();
		Vector4 Normalized() const;
		float LengthSq() const;
		float Length() const;
		bool EqualsZero() const;
	
		union
		{
			float v[4];
			struct
			{
				float x, y, z, w;
			};
		};
	};
	Vector4 operator * (float, const Vector4 &);

	class Quaternion
	{
	public:
		Quaternion();
		Quaternion(const Quaternion &);
		Quaternion(float w, float x, float y, float z);
		Quaternion(const Vector3 &other);
		Quaternion(const Vector3 &other, float angle);
		Quaternion(const float *f);

		static Quaternion NullQuaternion();

		Quaternion &operator = (const Quaternion &other);
		Quaternion operator - () const;
		Quaternion operator + (const Quaternion &other) const;
		Quaternion operator - (const Quaternion &other) const;
		Quaternion operator * (const Quaternion &other) const;
		Quaternion operator / (const Quaternion &other) const;
		Quaternion &operator += (const Quaternion &other);
		Quaternion &operator -= (const Quaternion &other);
		Quaternion &operator *= (const Quaternion &other);
		Quaternion &operator /= (const Quaternion &other);
		Vector3 operator * (const Vector3 &other) const;

		void Normalize();
		Quaternion Normalized() const;
		float LengthSq() const;
		float Length() const;
		Quaternion Inverse() const;
		float GetRealPart() const;
		Vector3 GetScalarPart() const;
		Matrix4x4 GetMatrixRepresentation() const;

		union
		{
			float v[4];
			struct
			{
				float w, x, y, z;
			};
		};
	};

	class Plane // a*x + b*y + c*z + d*w = 0
	{
	public:
		Plane();
		Plane(const Plane &other);
		Plane(const Vector4 &);
		Plane(float a, float b, float c, float d);
		Plane(const float *);

		void Normalize();
		Plane Normalized() const;

		float IntersectLine(const Vector3 &a, const Vector3 &b) const;
		float DistanceFromPoint(const Vector3 &p) const;

		union
		{
			float v[4];
			struct
			{
				float a, b, c, d;
			};
		};
	};

	class Matrix4x4
	{
	public:
		Matrix4x4();
		Matrix4x4(const Matrix4x4 &);
		Matrix4x4(float f11, float f12, float f13, float f14,
				  float f21, float f22, float f23, float f24,
				  float f31, float f32, float f33, float f34,
				  float f41, float f42, float f43, float f44);
		Matrix4x4(const float *);

#ifdef D3DMATRIX_DEFINED
		Matrix4x4(const D3DXMATRIX &);
		operator D3DXMATRIX &();
		operator const D3DXMATRIX &() const;
#endif

		static Matrix4x4 NullMatrix();
		static Matrix4x4 IdentityMatrix();
		static Matrix4x4 RotationXMatrix(float);
		static Matrix4x4 RotationYMatrix(float);
		static Matrix4x4 RotationZMatrix(float);
		static Matrix4x4 RotationAxisMatrix(const Vector3 &, float);
		static Matrix4x4 TranslateMatrix(float x, float y, float z);
		static Matrix4x4 TranslateMatrix(const Vector3 &);
		static Matrix4x4 ScaleMatrix(float x, float y, float z);
		static Matrix4x4 CameraMatrix(const Vector3 &eye, const Vector3 &lookat, const Vector3 &up = Vector3(0.f, 1.f, 0.f));
		static Matrix4x4 ProjectionMatrix(float fovy, float aspect, float zn, float zf);

		enum PlaneIndex {PlaneLeft, PlaneRight, PlaneTop, PlaneBottom, PlaneNear, PlaneFar};
		Plane GetClippingPlane(unsigned index) const;

		Matrix4x4 operator = (const Matrix4x4 &);
		Matrix4x4 operator + () const;
		Matrix4x4 operator - () const;
		Matrix4x4 operator * (float) const;
		Matrix4x4 operator / (float) const;
		Matrix4x4 operator + (const Matrix4x4 &) const;
		Matrix4x4 operator - (const Matrix4x4 &) const;
		Matrix4x4 &operator += (const Matrix4x4 &);
		Matrix4x4 &operator -= (const Matrix4x4 &);
		Matrix4x4 &operator *= (float);
		Matrix4x4 &operator /= (float);
		Matrix4x4 operator * (const Matrix4x4 &) const;

		float *operator [] (unsigned);
		const float *operator [] (unsigned) const;

		void Transpose();
		Matrix4x4 Transposed() const;
		Vector3 operator * (const Vector3 &) const;
	
		union
		{
			float m[4][4];
			struct
			{
				float f11, f12, f13, f14;
				float f21, f22, f23, f24;
				float f31, f32, f33, f34;
				float f41, f42, f43, f44;
			};
		};
	};
	const float PI = 3.14159265358979f;
	inline float ToRadian(float val)
	{
		return val * PI / 180.f;
	}
	inline float ToDegree(float val)
	{
		return val * 180.f / PI;
	}
}