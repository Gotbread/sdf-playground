#pragma once

#include "Math3D.h"

class Camera
{
public:
	enum CameraMode {CameraModeFPS, CameraModeFlight};

	Camera();

	void SetCameraMode(CameraMode);
	CameraMode GetCameraMode();

	void SetEye(const Math3D::Vector3 &eye);
	const Math3D::Vector3 &GetEye() const;
	void SetLookat(const Math3D::Vector3 &lookat);
	void SetDirection(const Math3D::Vector3 &direction);
	const Math3D::Vector3 &GetDirection() const;
	const Math3D::Vector3 GetRelXAxis() const; // scaled to unity
	const Math3D::Vector3 GetRelYAxis() const;
	void SetAspect(float);
	float GetAspect() const;
	void SetFOVY(float);
	float GetFOVY() const;
	void SetNearPlane(float);
	float GetNearPlane() const;
	void SetFarPlane(float);
	float GetFarPlane() const;
	void SetMaxXAngle(float);
	float GetMaxXAngle() const;
	void SetMinXAngle(float);
	float GetMinXAngle() const;

	void SetRoll(float radian);
	float GetRoll() const;

	void RotateX(float); // relative
	void RotateY(float);

	// 0 -> top right
	// 1 -> bottom right
	// 2 -> bottom left
	// 3 -> top left
	Math3D::Vector3 GetFrustrumEdge(unsigned index) const;

	void MoveAbs(const Math3D::Vector3 &);
	void MoveRel(const Math3D::Vector3 &);

	Math3D::Matrix4x4 GetViewMatrix() const;
	Math3D::Matrix4x4 GetProjectionMatrix() const;
	Math3D::Matrix4x4 GetFullMatrix() const; // simply view * proj
private:
	CameraMode mode;

	Math3D::Vector3 eye, dir, up; // up is fixed to (0/1/0) in FPS mode
	float roll; // only in FPS mode
	float fovy, aspect;
	float nearplane, farplane;
	float minx, maxx;
};