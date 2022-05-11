
Shader "Shader/Shader_016RayMarch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FogColor ("FogColor", Color) = (1,1,1,1)
        _blurSize("BlurSize",Vector )= (1,2.0,0,0)
    }
    
    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
    
            sampler2D _MainTex;
            sampler2D _BlurTex;            
            CBUFFER_START(UnityPerMaterial) // Required to be compatible with SRP Batcher
            float4 _MainTex_ST;
            float4 _FogColor;
            //x控制采样size、y控制分离度
            float2 _blurSize;
            float3 mouseFocusPoint;
            float minDistance = 1.0;
            float maxDistance = 3.0;
            CBUFFER_END
            
            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };
            
            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
                float4 screenPos :TEXCOORD1;
            };
            
            Varyings FullscreenVert(Attributes input)
            {
                Varyings o;
                o.vertex = TransformObjectToHClip(input.vertex.xyz);
                o.uv = TRANSFORM_TEX(input.uv, _MainTex);
                o.color = input.color;
                               //vertex
                o.screenPos = ComputeScreenPos(o.vertex);//o.vertex是裁剪空间的顶点
                return o;
            }
            
            half4 FragBlurH(Varyings input) : SV_Target
            {
              float4 ndcPos = (input.screenPos / input.screenPos.w);
                 //int size = int(_blurSize.x);
              float deviceDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, ndcPos.xy);                
              float3 colorWorldPos = ComputeWorldSpacePosition(ndcPos.xy, deviceDepth, UNITY_MATRIX_I_VP);
              float4 viewPos = mul(unity_WorldToCamera, float4(colorWorldPos, 1.0)); //TransformWorldToView(UNITY_MATRIX_V,float4(colorWorldPos,1.0));

              // float sceneDepth = length(viewPos.xyz)*0.1;
              float sceneDepth =  LinearEyeDepth(deviceDepth,_ZBufferParams)*0.1;
              return float4(sceneDepth,sceneDepth,sceneDepth,1);
            }
           
            
    ENDHLSL
    
    SubShader
    {
        Tags { "RenderType"="TransParent" "Queue" = "TransParent"}
        LOD 100

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        ZTest LEqual
        Cull Off
        
        Pass
        {            
            HLSLPROGRAM
            #pragma vertex FullscreenVert
            #pragma fragment FragBlurH           
            ENDHLSL
        }
    }
}
