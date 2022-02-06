
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
            float4 _FogColor;
            //x控制采样size、y控制分离度
            float2 _blurSize;
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


             
            half4 frag (v2f input) : SV_Target
            {

              float4 mainTexColor = tex2D(_MainTex, input.uv.xy);
              int size = int(_blurSize.x);
              if (size<=0)
              {
                  return mainTexColor;
              }

                //box平均滤波
                //和提纲技术一样，框模糊技术使用一个以当前片段为中心的内核/矩阵/窗口。窗口的大小是size * 2 + 1乘以size * 2 + 1。例如，当大小设置为2时，窗口使用(2 * 2 + 1)^2 =每个片段25个样本。
                for(int i=-size;i<size;i++)
                {
                    for(int j=-size;j<size;j++)
                    {
                        mainTexColor += tex2D(_MainTex, input.uv.xy+ _blurSize.y* float2(i,j)/_ScreenParams.xy);
                    }
                }
                mainTexColor /= pow(size * 2 + 1, 2);

                //Middle Filter
                //中值过滤器使用所采集样本的中值颜色。通过使用中间值而不是平均值，图像中的边缘被保留了下来——这意味着边缘保持得很好和清晰。例如，看看框中的窗口模糊图像与中值滤波图像。
                //有一种技术可以在线性时间内找到中间值，但在着色器中可能会相当尴尬。下面的数值方法在线性时间内近似中值。它接近中值的程度是可以控制的。

                //Kuwahara Filter
                
              half4 texColor = mainTexColor;
              return texColor;
              //return float4(0,0,intensity,1);
                            
            }
            ENDHLSL
        }
    }
}
