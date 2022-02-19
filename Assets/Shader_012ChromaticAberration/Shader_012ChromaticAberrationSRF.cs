using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Shader_012ChromaticAberrationSRF : ScriptableRendererFeature
{
    class Shader_012ChromaticAberrationPass : ScriptableRenderPass
    {

        public static string k_RenderTag = "Shader_012ChromaticAberrationPass";

        private Shader_012ChromaticAberrationVolume volume;
        private RenderTargetIdentifier _renderTargetIdentifier;
        private Material _material;

        private static readonly int MainTexId = Shader.PropertyToID("_MainTex");
        private static readonly int TmpTexId = Shader.PropertyToID("_TmpTex");
        private static readonly int redOffset = Shader.PropertyToID("redOffset");
        private static readonly int greenOffset = Shader.PropertyToID("greenOffset");
        private static readonly int blueOffset = Shader.PropertyToID("blueOffset");
        private static readonly int mouseFocusPoint = Shader.PropertyToID("mouseFocusPoint");
        
        

        public Shader_012ChromaticAberrationPass()
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
            volume = stack.GetComponent<Shader_012ChromaticAberrationVolume>();
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
            
            _material.SetFloat(redOffset,volume.redOffset.value);
            _material.SetFloat(greenOffset,volume.greenOffset.value);
            _material.SetFloat(blueOffset,volume.blueOffset.value);
            if (Input.GetMouseButton(0))
            {
                Rect pixelRect = renderingData.cameraData.camera.pixelRect;
                float renderScale = renderingData.cameraData.isSceneViewCamera ? 1f :  renderingData.cameraData.renderScale;
                float scaledCameraWidth = (float)pixelRect.width * renderScale;
                float scaledCameraHeight = (float)pixelRect.height * renderScale;
                // float cameraWidth = (float)pixelRect.width;
                // float cameraHeight = (float)pixelRect.height;

                _material.SetVector(mouseFocusPoint, new Vector4(Input.mousePosition.x/scaledCameraWidth,
                    Input.mousePosition.y/scaledCameraHeight,1,0));
            }
            else
            {
                _material.SetVector(mouseFocusPoint, Vector4.zero);
            }


            MaterialEnableKey("CAMERA_VERTEX", volume.intensity.value == 1);
            MaterialEnableKey("PRE_CAMERA_VERTEX", volume.intensity.value == 2);

            var cmd = CommandBufferPool.Get(k_RenderTag);
            Render(cmd,ref renderingData);
            
            context.ExecuteCommandBuffer(cmd);
            
            CommandBufferPool.Release(cmd);
        }

        private void MaterialEnableKey(string cameraVertex, bool b)
        {
            if (b)
            {
                _material.EnableKeyword(cameraVertex);
            }
            else
            {
                _material.DisableKeyword(cameraVertex);
            }
        }

        private string GetShaderName(int intensityValue)
        {
            string shaderName = "Shader/Shader_012ChromaticAberration";
            return shaderName;
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

        private void Render(CommandBuffer cmd,ref RenderingData renderingData)
        {
            var w = renderingData.cameraData.camera.scaledPixelWidth;
            var h = renderingData.cameraData.camera.scaledPixelHeight;
            
            var soruce = _renderTargetIdentifier;
            cmd.SetGlobalTexture(MainTexId,soruce);
            
            cmd.GetTemporaryRT(TmpTexId,w,h,0,FilterMode.Point, RenderTextureFormat.Default);
            
            cmd.Blit(soruce,TmpTexId);
            cmd.Blit(TmpTexId,soruce,_material,0);
            
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    Shader_012ChromaticAberrationPass m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new Shader_012ChromaticAberrationPass();

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


