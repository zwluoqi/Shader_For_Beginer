using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Shader_015DepthOfFieldSRF : ScriptableRendererFeature
{
    class Shader_015DepthOfFieldPass : ScriptableRenderPass
    {

        public static string k_RenderTag = "Shader_015DepthOfField";

        private Shader_015DepthOfFieldVolume volume;
        private RenderTargetIdentifier _renderTargetIdentifier;
        private Material _material;

        private static readonly int MainTexId = Shader.PropertyToID("_MainTex");
        private static readonly int BlurTexId = Shader.PropertyToID("_BlurTex");
        private static readonly int TmpTexId = Shader.PropertyToID("_TmpTex");
        private static readonly int shader008BlurSize = Shader.PropertyToID("_blurSize");
        private static readonly int maxDistance = Shader.PropertyToID("maxDistance");
        private static readonly int minDistance = Shader.PropertyToID("minDistance");
        
        private static readonly int mouseFocusPoint = Shader.PropertyToID("mouseFocusPoint");

        // private RenderTextureDescriptor _cameraTextureDescriptor;


        public Shader_015DepthOfFieldPass()
        {
            
        }
        
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {

        }

        public void SetUp(RenderTargetIdentifier targetIdentifier)
        {
            this._renderTargetIdentifier = targetIdentifier;
            
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var stack = VolumeManager.instance.stack;
            volume = stack.GetComponent<Shader_015DepthOfFieldVolume>();
            if (!volume.IsActive())
            {
                return;
            }

            if (_material == null)
            {
                CreateMaterial(GetShaderName(volume.intensity.value));
            }else if (_material.shader.name != GetShaderName(volume.intensity.value))
            {
                CreateMaterial(GetShaderName(volume.intensity.value));
            }
            
            _material.SetVector(shader008BlurSize,volume.shader008BlurSize.value);
            _material.SetFloat(minDistance,volume.minDistance.value);
            _material.SetFloat(maxDistance,volume.maxDistance.value);

            if (Input.GetMouseButton(0))
            {
                Rect pixelRect = renderingData.cameraData.camera.pixelRect;
                float renderScale = renderingData.cameraData.isSceneViewCamera ? 1f :  renderingData.cameraData.renderScale;
                float scaledCameraWidth = (float)pixelRect.width * renderScale;
                float scaledCameraHeight = (float)pixelRect.height * renderScale;

                _material.SetVector(mouseFocusPoint, new Vector4(Input.mousePosition.x/scaledCameraWidth,
                    Input.mousePosition.y/scaledCameraHeight,1,0));
            }
            else
            {
                _material.SetVector(mouseFocusPoint, new Vector4(0.5f,0.5f,1,0));
            }
            
            
            var cmd = CommandBufferPool.Get(k_RenderTag);
            Render(cmd,ref renderingData);
            
            context.ExecuteCommandBuffer(cmd);
            
            CommandBufferPool.Release(cmd);
        }

        private string GetShaderName(int intensityValue)
        {
            string shaderName = "Shader/Shader_015DepthOfField";
            return shaderName;
        }

        private void Render(CommandBuffer cmd,ref RenderingData renderingData)
        {
            var w = renderingData.cameraData.camera.scaledPixelWidth;
            var h = renderingData.cameraData.camera.scaledPixelHeight;
            
            var soruce = _renderTargetIdentifier;
            cmd.SetGlobalTexture(MainTexId,soruce);
            
            cmd.GetTemporaryRT(TmpTexId,w,h,0,FilterMode.Bilinear, RenderTextureFormat.Default);
            cmd.GetTemporaryRT(BlurTexId,w,h,0,FilterMode.Bilinear, RenderTextureFormat.Default);
            
            cmd.Blit(soruce,BlurTexId);
            //cmd.Blit(TmpTexId,soruce,_material,0);
            cmd.Blit(BlurTexId,TmpTexId,_material,1);
            cmd.Blit(TmpTexId,BlurTexId,_material,2);
            cmd.SetGlobalTexture(BlurTexId, BlurTexId);
            cmd.Blit(soruce,TmpTexId,_material,3);
            cmd.Blit(TmpTexId,soruce);
        }

        private void CreateMaterial(string shaderName)
        {
            if (_material != null)
            {
                CoreUtils.Destroy(_material);
            }

            var shader = Shader.Find(shaderName);
            _material = CoreUtils.CreateEngineMaterial(shader);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    Shader_015DepthOfFieldPass m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new Shader_015DepthOfFieldPass();

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        m_ScriptablePass.SetUp(renderer.cameraColorTarget);
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


