
Shader "Shader/Shader_009Bloom"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FogColor ("FogColor", Color) = (1,1,1,1)
        _bloomSize("BloomSize",Vector )= (5.0,3.0,0.4,1.0)
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
            #pragma multi_compile _ GRAY CLIP
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
            //这些参数控制外观和感觉。x决定了效果的模糊程度。y将模糊的画面展开。z控制哪些片段被照亮。w控制输出多少bloom。
            
            float4 _bloomSize;
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

            //颜色转换为灰度           
            float node_rgbtobw(float4 color)
            {
              float3 factors = float3(0.2126, 0.7152, 0.0722);
              float outval = dot(color.rgb, factors);
              return outval;
            }
             
            half4 frag (v2f input) : SV_Target
            {

              float4 mainTexColor = tex2D(_MainTex, input.uv.xy);
              int size = int(_bloomSize.x);
              if (size<=0)
              {
                  return mainTexColor;
              }
                float threshold = _bloomSize.z;
                float amount = _bloomSize.w;

                float4 color=0;
                
                float4 bloomColor =0;
                int count = 0;
                float value=0;

                #ifdef CLIP
                value = max(mainTexColor.r,max(mainTexColor.g,mainTexColor.b));
                if (value<threshold)
                {
                    mainTexColor = float4(0.0f,0.0f,0.0f,1.0f);
                }
                return mainTexColor;
                #endif

                #ifdef GRAY
                value = max(mainTexColor.r,max(mainTexColor.g,mainTexColor.b));
                // if (value<threshold)
                // {
                //     mainTexColor = float4(0.0f,0.0f,0.0f,1.0f);
                // }
                return float4(value,value,value,1.0);
                #endif

                  for(int i=-size;i<size;i++)
                    {
                        for(int j=-size;j<size;j++)
                        {
                            bloomColor = tex2D(_MainTex, input.uv.xy+ _bloomSize.y* float2(i,j)/_ScreenParams.xy);
                            value = max(bloomColor.r,max(bloomColor.g,bloomColor.b));
                            if (value<threshold)
                            {
                                bloomColor = 0;
                            }else{
                                color += bloomColor;
                                count+=1;
                            }
                        }
                    }
                if(count>0){
                   color = color/count;
                }
                  half4 texColor = lerp(0,color,amount);
                  return texColor;
                            
            }
            ENDHLSL
        }
    }
}
