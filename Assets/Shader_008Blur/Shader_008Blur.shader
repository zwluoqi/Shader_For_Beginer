
Shader "Shader/Shader_008Blur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FogColor ("FogColor", Color) = (1,1,1,1)
        _blurSize("BlurSize",Vector )= (1,2.0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="TransParent" "Queue" = "TransParent"}
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual
            Cull Off
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ BOX GUSSION
            // make fog work
            // #pragma multi_compile_fog

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
                float4 screenPos:TEXCOORD1;
                float3 viewRayWorld:TEXCOORD2;
               
            };

            sampler2D _MainTex;
            
            CBUFFER_START(UnityPerMaterial) // Required to be compatible with SRP Batcher
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            float4 _FogColor;
            //x控制采样size、y控制分离度
            float _blurSize;
            float2 _blurOffset;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                //vertex
                o.screenPos = ComputeScreenPos(o.vertex);//o.vertex是裁剪空间的顶点


                float sceneRawDepth = 1;
                float3 worldPos = ComputeWorldSpacePosition(v.uv, sceneRawDepth, UNITY_MATRIX_I_VP);
                o.viewRayWorld = (worldPos - _WorldSpaceCameraPos.xyz);

                return o;
            }


            half4 SampleBox(float2 uv){
                float4 color = 0;
                float2 offset = _blurOffset*_MainTex_TexelSize.xy;
                color += 0.2 * tex2D(_MainTex, uv);
                color += 0.2 * tex2D(_MainTex, uv+offset);
                color += 0.2 * tex2D(_MainTex, uv-offset);
                color += 0.2 * tex2D(_MainTex, uv+2*offset);
                color += 0.2 * tex2D(_MainTex, uv-2*offset);
                return color;
            }
            
            half4 SampleGussion(float2 uv){
                half4 color = float4(0, 0, 0, 0);
                float2 offset = _blurOffset*_MainTex_TexelSize.xy;
                color += 0.40 * tex2D(_MainTex, uv);
                color += 0.15 * tex2D(_MainTex, uv+offset);
                color += 0.15 * tex2D(_MainTex, uv-offset);
                color += 0.10 * tex2D(_MainTex, uv+2*offset);
                color += 0.10 * tex2D(_MainTex, uv-2*offset);
                color += 0.05 * tex2D(_MainTex, uv+3*offset);
                color += 0.05 * tex2D(_MainTex, uv-3*offset);
            
                return color;
            }
             
            half4 frag (v2f input) : SV_Target
            {

              float4 mainTexColor = tex2D(_MainTex, input.uv.xy);
              int size = int(_blurSize);
              if (size<=0)
              {
                  return mainTexColor;
              }

                //box平均滤波
                //和提纲技术一样，框模糊技术使用一个以当前片段为中心的内核/矩阵/窗口。窗口的大小是size * 2 + 1乘以size * 2 + 1。例如，当大小设置为2时，窗口使用(2 * 2 + 1)^2 =每个片段25个样本。
               
               #ifdef GUSSION
               float4 color = SampleGussion(input.uv.xy);
               #else
               float4 color = SampleBox(input.uv.xy);
               #endif
                
                
              half4 texColor = color;
              return texColor;
              //return float4(0,0,intensity,1);
                            
            }
            ENDHLSL
        }
    }
}
