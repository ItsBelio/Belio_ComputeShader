using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class PlaneTool 
{
    // Start is called before the first frame update
    public static Vector4 Plane(Vector3 normal,Vector3 Point)
	{
		return new Vector4(normal.x, normal.y, normal.z, -(normal.x * Point.x + normal.y * Point.y + normal.z * Point.z));
	}

	public static Vector4 Plane(Vector3 A,Vector3 B,Vector3 C)
	{
		Vector3 lineA = B - A;
		Vector3 LineB = C - A;
		return Plane(Vector3.Cross(lineA, LineB), A);
	}

	public static Vector3[] Camera_Far_Point(Camera camera)
	{
		Transform TF = camera.transform;
		float deg = camera.fieldOfView/2 * Mathf.Deg2Rad;
		float up = Mathf.Tan(deg) * camera.farClipPlane;
		float wid = up * camera.aspect;
		Vector3 pos = TF.position + TF.forward * camera.farClipPlane;
		Vector3[] Points = new Vector3[4];
		Points[0] = pos - TF.right * wid - TF.up * up;
		Points[1] = pos - TF.right * wid + TF.up * up;
		Points[2] = pos + TF.right * wid + TF.up * up;
		Points[3] = pos + TF.right * wid - TF.up * up;
		return Points;
	}
	public static Vector4[] Camera_Plane(Camera camera)
	{
		Transform TF = camera.transform;
		Vector3[] Points = Camera_Far_Point(camera);
		Vector4[] Planes = new Vector4[6];
		Planes[0] = Plane(TF.position, Points[0], Points[1]);
		Planes[1] = Plane(TF.position, Points[1], Points[2]);
		Planes[2] = Plane(TF.position, Points[2], Points[3]);
		Planes[3] = Plane(TF.position, Points[3], Points[0]);
		Planes[4] = Plane(TF.forward, TF.position + TF.forward * camera.farClipPlane);
		Planes[5] = Plane(-TF.forward, TF.position + TF.forward * camera.nearClipPlane);
		return Planes;
	}
}