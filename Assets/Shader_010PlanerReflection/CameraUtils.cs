using UnityEngine;

namespace Shader_010PlanerReflection
{
    public class CameraUtils
    {

        public static void ReflectionCamera(Camera target, Camera source, Transform plane)
        {
            ReflectionTransform(target.transform,source.transform,plane);
            
            var identity = Matrix4x4.identity;
            identity.m22 = -1;
            identity.m00 = -1;
            var inverse = identity * target.transform.worldToLocalMatrix;
            Debug.LogWarning("1:" + inverse);
            target.worldToCameraMatrix = inverse;

            //屏幕空间 <平面表达>(N,D);
            Vector4 viewplane = CameraSpacePlane(target.worldToCameraMatrix, plane.position, plane.up);
            target.projectionMatrix = target.CalculateObliqueMatrix(viewplane);
        }

        private static  Vector4 CameraSpacePlane(Matrix4x4 targetWorldToCameraMatrix, Vector3 planePosition, Vector3 planeUp)
        {
            var planeOffset = 0;
            Vector3 offsetPos = planePosition + planeUp * planeOffset;
            Vector3 cpos = targetWorldToCameraMatrix.MultiplyPoint3x4(offsetPos);
            Vector3 cnormal = targetWorldToCameraMatrix.MultiplyVector(planeUp).normalized;
            float d = -Vector3.Dot(cpos, cnormal);
            return new Vector4(cnormal.x, cnormal.y, cnormal.z, d);
        }

        static  void ReflectionTransform(Transform target,Transform source,Transform plane)
        {
            var forward = source.forward;
            var up = source.up;
            var pos = source.position;

            //transform to plane local 
            forward = plane.InverseTransformDirection(forward);
            up = plane.InverseTransformDirection(up);
            pos = plane.InverseTransformPoint(pos);
        
            //reflection
            forward.y *= -1;
            up.y *= -1;
            pos.y *= -1;

        
            //back to world
            forward = plane.TransformDirection(forward);
            up = plane.TransformDirection(up);
            pos = plane.TransformPoint(pos);

            target.transform.position = pos;
            target.transform.LookAt(pos+forward,up);
        }
        
        
    }
}