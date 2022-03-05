
Shader "Shader/Shader_009Bloom"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FogColor ("FogColor", Color) = (1,1,1,1)
        _bloomSize("BloomSize",Vector )= (5.0,3.0,0.4,1.0)
    }
    
    HLSLINCLUDE
    
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
               
            };
            
            
            sampler2D _MainTex;
            sampler2D _BlurTex;
            
            CBUFFER_START(UnityPerMaterial) // Required to be compatible with SRP Batcher
            float4 _MainTex_ST;
            float4 _FogColor;
            //这些参数控制外观和感觉。x决定了效果的模糊程度。y将模糊的画面展开。z控制哪些片段被照亮。w控制输出多少bloom。           
            float4 _bloomSize;
            CBUFFER_END
 ENDHLSL
   
    SubShader
    {
        Tags { "RenderType"="TransParent" "Queue" = "TransParent"}
        LOD 100
        
            ZWrite Off
            ZTest LEqual
            Cull Off
            
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ GRAY CLIP
            // make fog work
            // #pragma multi_compile_fog



            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;

                return o;
            }
            
            float GetMultiplier(float4 mainTexColor,float threshold){
                float ThresholdKnee = threshold*0.5;
                //y=((x-0.5T)^2)/(2T)
                //z = max(x-T,y)/x
                float brightness = Max3(mainTexColor.r, mainTexColor.g, mainTexColor.b);
                half softness = clamp(brightness - threshold + ThresholdKnee, 0.0, 2.0 * ThresholdKnee);                //[0-1]->[0-(1-0.5*T)]
                softness = (softness * softness) / (4.0 * ThresholdKnee + 1e-4);
                half multiplier = max(brightness - threshold, softness) / max(brightness, 1e-4);
                return multiplier;
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
                float ThresholdKnee = threshold*0.5;
                float amount = _bloomSize.w;

                float4 color=0;
                
                float4 bloomColor =0;
                int count = 0;
                float brightness=0;



                #ifdef GRAY
                brightness = Max3(mainTexColor.r, mainTexColor.g, mainTexColor.b);
                return float4(brightness,brightness,brightness,1.0);
                #endif
                
                #ifdef CLIP
                float multiplier = GetMultiplier(mainTexColor,threshold);
                mainTexColor *= multiplier;

                // Clamp colors to positive once in prefilter. Encode can have a sqrt, and sqrt(-x) == NaN. Up/Downsample passes would then spread the NaN.
                mainTexColor = max(mainTexColor, 0);
                return float4(mainTexColor.rgb,1.0);
                #endif

                  for(int i=-size;i<size;i++)
                    {
                        for(int j=-size;j<size;j++)
                        {
                            bloomColor = tex2D(_MainTex, input.uv.xy+ _bloomSize.y* float2(i,j)/_ScreenParams.xy);
                           float multiplier = GetMultiplier(bloomColor,threshold);
                            bloomColor *= multiplier;
            
                            // Clamp colors to positive once in prefilter. Encode can have a sqrt, and sqrt(-x) == NaN. Up/Downsample passes would then spread the NaN.
                            bloomColor = max(bloomColor, 0);
                            bloomColor.a = 1;
                                                       
                            color += bloomColor;
                            count+=1;
                        }
                    }
                    if(count>0){
                       color = color/count;
                    }
                  half4 texColor = lerp(0,color,amount);
                  #ifdef BLUR
                  return float4(texColor.rgb,1.0);
                  #endif 
                  return texColor;
                            
            }
            ENDHLSL
        }
        
        Pass{
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            
            #pragma vertex vertMix
            #pragma fragment fragMix
            #pragma multi_compile _ GRAY CLIP BLUR

            v2f vertMix (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;

                return o;
            }
            
             half4 fragMix (v2f input) : SV_Target
            {
              float4 mainTexColor = tex2D(_MainTex, input.uv.xy);
              float4 blurColor = tex2D(_BlurTex, input.uv.xy);
              #ifdef GRAY
              return float4(blurColor.rgb,1);
              #endif
              #ifdef CLIP
              return float4(blurColor.rgb,1);
              #endif
              #ifdef BLUR
              return float4(blurColor.rgb,1);
              #endif              
              
              return float4(mainTexColor.rgb + blurColor.rgb,1);
            }
            
            ENDHLSL
        }
    }
}
