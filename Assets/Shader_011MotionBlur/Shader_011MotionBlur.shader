
Shader "Shader/Shader_011MotionBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            #pragma multi_compile _ CAMERA_VERTEX CLIP PRO_CLIP
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
               
            };

            sampler2D _MainTex;
            
            CBUFFER_START(UnityPerMaterial) // Required to be compatible with SRP Batcher
            float4 _MainTex_ST;
            //可调参数有尺寸和分离。大小控制沿着模糊方向取多少样本。增大大小会以牺牲性能为代价增加模糊的数量。分离控制样品沿着模糊方向的分散程度。越来越多的分离增加了模糊的数量，以准确性为代价。
            float4 _blurSize;
            //运动模糊技术通过比较前一帧的顶点位置和当前帧的顶点位置来确定模糊方向。
            uniform float4x4 previousView2WorldMat;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                //vertex
                o.screenPos = ComputeScreenPos(o.vertex);//o.vertex是裁剪空间的顶点


                return o;
            }

            float4 MotionBlur(float4 sourceColor,float2 uv,float dir)
            {
                    int size = int(_blurSize.x);
                  if (size<0)
                  {
                      return sourceColor;
                  }

                float4 color = 0;

                float2 direction = dir*_blurSize.y;
                float2  forward  = uv;
                float2  backward = uv;
                
                for (int i = 0; i < 2; ++i) {
                forward  += direction;
                backward -= direction;

                color +=
                  tex2D(_MainTex, forward);
                color +=
                  tex2D(_MainTex, backward);

              }
                color /= (2*size);
                return color;
            }

            half4 frag (v2f input) : SV_Target
            {

               float4 mainTexColor = tex2D(_MainTex, input.uv.xy);

                float4 ndcPos = (input.screenPos / input.screenPos.w);
                // return float4(ndcPos.xy,0.0,1.0);
                float deviceDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, ndcPos.xy);
                float3 cameraPos = ComputeViewSpacePosition(ndcPos.xy, deviceDepth, UNITY_MATRIX_I_P);
#ifdef CAMERA_VERTEX
                return float4(cameraPos,1.0f);
#endif

                float3 preCameraPos = mul(unity_WorldToCamera,float4( mul(previousView2WorldMat,float4(cameraPos,1.0f)).xyz,1.0) ).xyz;
#ifdef PRE_CAMERA_VERTEX
                return float4(preCameraPos,1.0f);
#endif

                  float4 clip      = mul(unity_CameraProjection , float4(cameraPos,1.0f));
                  clip = ComputeScreenPos(clip);
                  clip = clip/clip.w;
                
                  float4 pre_clip      = mul(unity_CameraProjection , float4(preCameraPos,1.0f));
                  pre_clip = ComputeScreenPos(pre_clip);
                  pre_clip = pre_clip/pre_clip.w;

                #ifdef CLIP
                return clip;
                #endif

                #ifdef PRO_CLIP
                return pre_clip;
                #endif

                float2 direction    = clip.xy - pre_clip.xy;
                if (length(direction) <= 0.001)
                {
                    return mainTexColor;
                }else
                {
                    return MotionBlur(mainTexColor,ndcPos.xy,direction);
                } 
            }
            ENDHLSL
        }
    }
}
