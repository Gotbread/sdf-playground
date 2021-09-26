#include "Camera.h"
#include <math.h>

Camera::Camera() : mode(CameraModeFPS)
{
}
void Camera::SetCameraMode(Camera::CameraMode p_mode)
{
	mode = p_mode;
	up = Math3D::Vector3(0.f, 1.f, 0.f);
}
Camera::CameraMode Camera::GetCameraMode()
{
	return mode;
}
void Camera::SetEye(const Math3D::Vector3 &p_eye)
{
	eye = p_eye;
}
const Math3D::Vector3 &Camera::GetEye() const
{
	return eye;
}
void Camera::SetLookat(const Math3D::Vector3 &lookat)
{
	dir = (lookat - eye).Normalized();
}
void Camera::SetDirection(const Math3D::Vector3 &direction)
{
	dir = direction.Normalized();
}
const Math3D::Vector3 &Camera::GetDirection() const
{
	return dir;
}
const Math3D::Vector3 Camera::GetRelXAxis() const
{
	if (mode == CameraModeFPS)
		return (Math3D::Vector3(0.f, 1.f, 0.f) ^ dir).Normalized();
	else
		return (up ^ dir).Normalized();
}
const Math3D::Vector3 Camera::GetRelYAxis() const
{
	if (mode == CameraModeFPS)
		return (dir ^ GetRelXAxis()).Normalized();
	else
		return up.Normalized();
}
void Camera::SetAspect(float p_aspect)
{
	aspect = p_aspect;
}
float Camera::GetAspect() const
{
	return aspect;
}
void Camera::SetFOVY(float p_fovy)
{
	fovy = p_fovy;
}
float Camera::GetFOVY() const
{
	return fovy;
}
void Camera::SetNearPlane(float p_nearplane)
{
	nearplane = p_nearplane;
}
float Camera::GetNearPlane() const
{
	return nearplane;
}
void Camera::SetFarPlane(float p_farplane)
{
	farplane = p_farplane;
}
float Camera::GetFarPlane() const
{
	return farplane;
}
void Camera::SetRoll(float radian)
{
	roll = radian;
}
float Camera::GetRoll() const
{
	return roll;
}
void Camera::SetMaxXAngle(float p_maxx)
{
	maxx = p_maxx;
}
float Camera::GetMaxXAngle() const
{
	return maxx;
}
void Camera::SetMinXAngle(float p_minx)
{
	minx = p_minx;
}
float Camera::GetMinXAngle() const
{
	return minx;
}
void Camera::RotateX(float ang)
{
	Math3D::Vector3 xaxis = GetRelXAxis();
	if (mode == CameraModeFPS)
	{
		float curr_ang = atan2f(dir.y, sqrtf(dir.x * dir.x + dir.z * dir.z));
		if (ang > 0.f) // pos
		{
			if (curr_ang + ang > maxx)
				ang = maxx - curr_ang;
		}
		else
		{
			if (curr_ang + ang < -minx)
				ang = -minx - curr_ang;
		}
		Math3D::Matrix4x4 rot = Math3D::Matrix4x4::RotationAxisMatrix(xaxis, ang);
		dir = (rot * dir).Normalized();
	}
	else
	{
		Math3D::Matrix4x4 rot = Math3D::Matrix4x4::RotationAxisMatrix(xaxis, ang);
		dir = (rot * dir).Normalized();
		up = dir ^ xaxis;
	}
}
void Camera::RotateY(float ang)
{
	if (mode == CameraModeFPS)
	{
		Math3D::Matrix4x4 rot = Math3D::Matrix4x4::RotationYMatrix(ang);
		dir = (rot * dir).Normalized();
	}
	else
	{
		Math3D::Matrix4x4 rot = Math3D::Matrix4x4::RotationAxisMatrix(GetRelYAxis(), ang);
		dir = (rot * dir).Normalized();
	}
}
void Camera::MoveAbs(const Math3D::Vector3 &vec)
{
	eye += vec;
}
void Camera::MoveRel(const Math3D::Vector3 &vec)
{
	Math3D::Vector3 yaxis = mode == CameraModeFPS ? Math3D::Vector3(0.f, 1.f, 0.f) : GetRelYAxis();
	Math3D::Vector3 xaxis = GetRelXAxis();
	Math3D::Vector3 change = dir * vec.z + yaxis * vec.y + xaxis * vec.x;
	MoveAbs(change);
}
Math3D::Vector3 Camera::GetFrustrumEdge(unsigned index) const
{
	if (index > 3)
		index = 3;

	float flip[] = {1, 1, -1, 1, -1, -1, 1, -1};
	Math3D::Vector3 yaxis = GetRelYAxis();
	Math3D::Vector3 xaxis = GetRelXAxis();
	Math3D::Matrix4x4 mat = Math3D::Matrix4x4::RotationAxisMatrix(dir, roll);
	return dir + (mat * yaxis) * tanf(fovy / 2.f) * flip[2 * index] + (mat * xaxis) * tanf(fovy / 2.f) * aspect * flip[2 * index + 1];
}
Math3D::Matrix4x4 Camera::GetViewMatrix() const
{
	if (mode == CameraModeFPS)
	{
		Math3D::Vector3 new_up = Math3D::Vector3(0.f, 1.f, 0.f);
		return Math3D::Matrix4x4::CameraMatrix(eye, eye + dir, Math3D::Matrix4x4::RotationAxisMatrix(dir, roll) * new_up);
	}
	else
	{
		return Math3D::Matrix4x4::CameraMatrix(eye, eye + dir, up);
	}
}
Math3D::Matrix4x4 Camera::GetProjectionMatrix() const
{
	return Math3D::Matrix4x4::ProjectionMatrix(fovy, aspect, nearplane, farplane);
}
Math3D::Matrix4x4 Camera::GetFullMatrix() const
{
	return GetViewMatrix() * GetProjectionMatrix();
}
