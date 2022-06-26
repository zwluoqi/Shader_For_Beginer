using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using Random = System.Random;

public class Shader_010SSAOSRF : ScriptableRendererFeature
{
    class Shader_010SSAOPass : ScriptableRenderPass
    {

        public static string k_RenderTag = "Shader_010SSAOPass";

        private Shader_010SSAOVolume volume;
        private RenderTargetIdentifier _renderTargetIdentifier;
        private Material _material;

        private static readonly int MainTexId = Shader.PropertyToID("_MainTex");
        private static readonly int TmpTexId = Shader.PropertyToID("_TmpTex");
        private static readonly int radius = Shader.PropertyToID("radius");
        private static readonly int bias = Shader.PropertyToID("bias");
        private static readonly int magnitude = Shader.PropertyToID("magnitude");
        private static readonly int contrast = Shader.PropertyToID("contrast");
        
        private static readonly int samples = Shader.PropertyToID("samples");
        private static readonly int noise = Shader.PropertyToID("noises");

        static readonly int SAMPLE_NUM = 16;
        private Vector4[] sampleVecs = new Vector4[SAMPLE_NUM];
        private Vector4[] noiseVecs= new Vector4[SAMPLE_NUM];
        
        
        // private RenderTextureDescriptor _cameraTextureDescriptor;


        public Shader_010SSAOPass()
        {
            for (int i = 0; i < SAMPLE_NUM; ++i) {
                var s = new Vector3(UnityEngine.Random.Range(0.0f,1.0f)*2.0f-1.0f,
                    UnityEngine.Random.Range(0.0f,1.0f)*2.0f-1.0f,
                    UnityEngine.Random.Range(0.0f,1.0f));
                s = s.normalized;
                
                float rand = UnityEngine.Random.Range(0.0f,1.0f);
                s *= rand;

                float scale = (float) i / (float) SAMPLE_NUM;
                scale = Mathf.Lerp(0.1f, 1.0f, scale * scale);
                s *= scale;
                
                
                sampleVecs[i] = new Vector4(s.x,s.y,s.z,
                    1.0f);
                noiseVecs[i] = new Vector4(UnityEngine.Random.Range(0.0f,1.0f)*2.0f-1.0f,
                    UnityEngine.Random.Range(0.0f,1.0f)*2.0f-1.0f,
                    0.0f,
                    0.0f);
            }
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
            
            //需要存储法线
            ConfigureInput(ScriptableRenderPassInput.Normal|ScriptableRenderPassInput.Depth|ScriptableRenderPassInput.Color);
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var stack = VolumeManager.instance.stack;
            volume = stack.GetComponent<Shader_010SSAOVolume>();
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
            
            _material.SetFloat(radius,volume.radius.value);
            _material.SetFloat(bias,volume.bias.value);
            _material.SetFloat(magnitude,volume.magnitude.value);
            _material.SetFloat(contrast,volume.contrast.value);
            
            _material.SetVectorArray(samples,sampleVecs);
            _material.SetVectorArray(noise,noiseVecs);

            MaterialEnable("CAMERA_VERTEX", volume.intensity.value == 1);
            MaterialEnable("CAMERA_NORMAL", volume.intensity.value == 2);
            MaterialEnable("TANGENT_NOISE", volume.intensity.value == 3);
            MaterialEnable("CAMERA_SAMPLE_VERTEX", volume.intensity.value == 4);
            MaterialEnable("OCCLUSION", volume.intensity.value == 5);
            
            MaterialEnable("WORLD_VERTEX", volume.intensity.value == 6);
            MaterialEnable("CAMERA_TANGENT", volume.intensity.value == 7);
            

            var cmd = CommandBufferPool.Get(k_RenderTag);
            
            
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            
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
            string shaderName = "Shader/Shader_010SSAO";
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

    Shader_010SSAOPass m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new Shader_010SSAOPass();

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


