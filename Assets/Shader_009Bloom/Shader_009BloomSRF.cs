using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Shader_009BloomSRF : ScriptableRendererFeature
{
    class Shader_009BloomPass : ScriptableRenderPass
    {

        public static string k_RenderTag = "Shader_009BloomPass";

        private Shader_009BloomVolume volume;
        private RenderTargetIdentifier _renderTargetIdentifier;
        private Material _material;

        private static readonly int MainTexId = Shader.PropertyToID("_MainTex");
        private static readonly int TmpTexId = Shader.PropertyToID("_TmpTex");
        private static readonly int BlurTexId = Shader.PropertyToID("_BlurTex");
        private static readonly int shader009BloomSize = Shader.PropertyToID("_bloomSize");
        
        // private RenderTextureDescriptor _cameraTextureDescriptor;


        public Shader_009BloomPass()
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
            volume = stack.GetComponent<Shader_009BloomVolume>();
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
            
            _material.SetVector(shader009BloomSize,new Vector4(volume.size.value,volume.seperate.value,
                volume.threshold.value,volume.amount.value));

            MaterialEnable("GRAY", volume.intensity.value == 1);
            MaterialEnable("CLIP", volume.intensity.value == 2);
            MaterialEnable("BLUR", volume.intensity.value == 3);


            var cmd = CommandBufferPool.Get(k_RenderTag);
            Render(cmd,ref renderingData);
            
            context.ExecuteCommandBuffer(cmd);
            
            CommandBufferPool.Release(cmd);
        }
        
        private void MaterialEnable(string cameraVertex, bool p1)
        {
            if (p1)
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
            string shaderName = "Shader/Shader_009Bloom";
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
            cmd.GetTemporaryRT(BlurTexId,w,h,0,FilterMode.Point, RenderTextureFormat.Default);

            cmd.Blit(soruce,TmpTexId);
            cmd.Blit(soruce,BlurTexId,_material,0);
            cmd.SetGlobalTexture(BlurTexId,BlurTexId);
            cmd.Blit(TmpTexId,soruce,_material,1);
            
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    Shader_009BloomPass m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new Shader_009BloomPass();

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


