using System;
using UnityEngine;

namespace Shader_010PlanerReflection
{
    [ExecuteAlways]
    public class ReflectionCamera:MonoBehaviour
    {
        public Camera reflectCamera;
        public Transform plane;

        public RenderTexture reflectionTx;

        void Start()
        {
            if (reflectionTx == null)
            {
                reflectionTx = RenderTexture.GetTemporary(Screen.width, Screen.height, 24);
                Shader.SetGlobalTexture("_ReflectionTex", reflectionTx);
            }

            if (reflectCamera == null)
            {
                var reflectionGo = new GameObject("reflection cam", typeof(Camera));
                reflectCamera = reflectionGo.GetComponent<Camera>();
            }
            reflectCamera.Reset();
            reflectCamera.cullingMask = 1<<LayerMask.NameToLayer("Default");
            reflectCamera.targetTexture = reflectionTx;
            // reflectCamera.enabled = false;
        }

        private void Update()
        {
            CameraUtils.ReflectionCamera(reflectCamera, Camera.main, 
                plane);
        }

        // private bool isRendering;
        // private void OnWillRenderObject()
        // {
        //     if (isRendering) return;
        //     isRendering = true;
        //     GL.invertCulling = true;
        //     reflectCamera.Render();
        //     GL.invertCulling = false;
        //     isRendering = false;
        // }
    }
}