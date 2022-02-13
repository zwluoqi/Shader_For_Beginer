
Shader "Shader/Shader_010SSAO"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        radius ("radius", float) = 0.05
        bias ("bias", float) = 0.01
        magnitude ("magnitude", float) = 1.5
        contrast ("contrast", float) = 1.5
    }
    SubShader
    {
        Tags { "RenderType"="TransParent" "Queue" = "TransParent"}
        LOD 100

        Pass
        {
            //
            //SSAO着色器需要以下输入。
                //1.视图空间中的顶点位置向量。
                //2.视图空间中的顶点法向量。
                //3.切线空间中的向量样本。
                //4.切线空间中的噪声向量。
                //5.摄像机镜头的投影矩阵。
            
            
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual
            Cull Off
            
            HLSLPROGRAM
            #pragma enable_d3d11_debug_symbols

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ CAMERA_VERTEX CAMERA_NORMAL TANGENT_NOISE CAMERA_SAMPLE_VERTEX OCCLUSION  WORLD_VERTEX CAMERA_TANGENT
            // make fog work
            // #pragma multi_compile_fog

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
            
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
            #define SAMPLE_NUM 16
            #define SQRT_SAMPLE_NUM 4
            CBUFFER_START(UnityPerMaterial) // Required to be compatible with SRP Batcher
            float4 _MainTex_ST;
          float radius    = 1;
          float bias      = 0.01;
          float magnitude = 1.5;
          float contrast  = 1.5;
          float4 samples[SAMPLE_NUM];
          float4 noises[SAMPLE_NUM];
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

            //颜色转换为灰度           
            float node_rgbtobw(float4 color)
            {
              float3 factors = float3(0.2126, 0.7152, 0.0722);
              float outval = dot(color.rgb, factors);
              return outval;
            }

            //1.重建视空间位置
            //2.获取视空间法线
            //3.随机获取切线空间矩阵（切线空间-视空间）
            //4.1.随机采样N个半球方向，转换到视空间，得到采样视空间方向,根据半球半径和视空间位置，得到采样位置，
            //4.2.根据采样视空间位置，转换到屏幕空间UV，得到缓存中的视空间位置
            //4.3.比较采样位置与缓存位置得到遮挡关系
            //4.4.根据距离权重计算遮挡系数
            
            half4 frag (v2f input) : SV_Target
            {
              float4 ndcPos = (input.screenPos / input.screenPos.w);
              float4 mainTexColor = tex2D(_MainTex, input.uv.xy);

              float deviceDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, ndcPos.xy);

              float3 colorWorldPos = ComputeWorldSpacePosition(ndcPos.xy, deviceDepth, UNITY_MATRIX_I_VP);
              float4 cameraPos = mul(unity_WorldToCamera, float4(colorWorldPos, 1.0)); //TransformWorldToView(UNITY_MATRIX_V,float4(colorWorldPos,1.0));


            //float3 cameraPos = ComputeViewSpacePosition(ndcPos.xy, deviceDepth, unity_CameraInvProjection);
            //float4 colorWorldPos =mul(unity_CameraToWorld, float4(cameraPos, 1.0));
            
//unity_WorldToCamera
//UNITY_MATRIX_V 没有值,在研究源码为什么
//unity_MatrixV
              

              
              #ifdef CAMERA_VERTEX
              return float4(cameraPos.xyz,1.0);
              #endif
              
                            
              #ifdef WORLD_VERTEX
              return float4(colorWorldPos.xyz,1.0);
              #endif
              
              //float4 samplerNormal = SAMPLE_TEXTURE2D_X(_CameraNormalsTexture, sampler_CameraNormalsTexture, ndcPos.xy);              
              //float3 normalView = UnpackNormalOctRectEncode(samplerNormal.xy);
              
              float3 normalView = normalize(SampleSceneNormals(ndcPos.xy));
              

              uint  noiseX = uint(ndcPos.x*_ScreenParams.x - 0.5) % (SQRT_SAMPLE_NUM);
              uint  noiseY = uint(ndcPos.y*_ScreenParams.y - 0.5) % (SQRT_SAMPLE_NUM);
              float3 random = noises[noiseX + (noiseY * SQRT_SAMPLE_NUM)].xyz;
              #ifdef TANGENT_NOISE
              return float4(random,1.0);
              #endif
              
              
               // ...
              //random = float3(0.1,0.1,0);
              float3 tangent  = normalize(random - normalView * dot(random, normalView));
              float3 binormal = cross(normalView, tangent);
              //float3x3 tbn      = float3x3(tangent, binormal, normalView);
              float3 tbn_t1 = float3(tangent.x,binormal.x,normalView.x);
              float3 tbn_t2 = float3(tangent.y,binormal.y,normalView.y);
              float3 tbn_t3 = float3(tangent.z,binormal.z,normalView.z);
              //切线空间到视空间矩阵
              float3x3 tbn_t      = float3x3(tbn_t1, tbn_t2, tbn_t3);
              
              #ifdef CAMERA_NORMAL
              return float4(normalView,1.0);
              #endif

            #ifdef CAMERA_SAMPLE_VERTEX
            float3 samplePosition = mul(tbn_t,samples[0]);                                       
            samplePosition = cameraPos.xyz + samplePosition * radius;
            
            float4 offsetUV      = float4(samplePosition.xyz, 1.0);
            offsetUV      = mul(unity_CameraProjection,offsetUV);
            offsetUV = ComputeScreenPos(offsetUV);
            offsetUV /= offsetUV.w;
            #if defined(SHADER_API_D3D11)
            offsetUV.x = 1- offsetUV.x;//DX 额外处理，GL和Metal不用处理
            #endif

            float dd = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, offsetUV.xy);
            float3 cwp = ComputeWorldSpacePosition(offsetUV.xy, dd, UNITY_MATRIX_I_VP);
            float4 offsetPosition = mul(unity_WorldToCamera,float4(cwp,1.0));
            float occluded = 0;
            //采样位置是否被缓存位置挡住
            if (samplePosition.z - bias >= offsetPosition.z) { occluded = 0; } else { occluded = 1; }
            
            return float4(occluded.xxx,1.0);
            #endif
                
                
              float occlusion = SAMPLE_NUM;
            
              //视空间位置
              for (int i = 0; i < SAMPLE_NUM; ++i) {
                float3 samplePosition = mul(tbn_t , samples[i]);
                samplePosition = cameraPos.xyz + samplePosition * radius;
    
                
                float4 offsetUV      = float4(samplePosition.xyz, 1.0);
                offsetUV      = mul(unity_CameraProjection,offsetUV);
                offsetUV = ComputeScreenPos(offsetUV);
                offsetUV.xyz /= offsetUV.w;
                #if defined(SHADER_API_D3D11)
                offsetUV.x = 1- offsetUV.x;
                #endif
    
    
                float dd = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, offsetUV.xy);
                float3 cwp = ComputeWorldSpacePosition(offsetUV.xy, dd, UNITY_MATRIX_I_VP);
                float4 offsetPosition = mul(unity_WorldToCamera,float4(cwp,1.0));
               
                float occluded = 0;
                //采样位置是否被缓存位置挡住
                if (samplePosition.z - bias >= offsetPosition.z) { occluded = 1; } else { occluded = 0; }
                
                
                float intensity =
                  smoothstep
                    ( 0.0
                    , 1.0
                    ,   radius
                      / (samplePosition.z - offsetPosition.z)
                    );
                occluded *= intensity;
                
                
                occlusion -= occluded;
              }
            
            
             occlusion /= SAMPLE_NUM;
             return float4(occlusion.xxx,1.0);             
            }
            ENDHLSL
        }
    }
}
