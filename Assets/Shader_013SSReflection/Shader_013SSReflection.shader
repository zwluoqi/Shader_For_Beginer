
Shader "Shader/Shader_013SSReflection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        maxDistance ("maxDistance", float) = 15
        resolution ("resolution", float) = 0.3
        steps ("steps", float) = 10
        thickness ("thickness", float) = 0.5
        roughness ("roughness", float) = 0.5
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
            
            Stencil
            {
                Ref 64        
//                ReadMask    4
//                WriteMask   1
                Comp        Equal
                Pass        Replace
                Fail        Keep
                ZFail       Keep
            }
            
            HLSLPROGRAM
            #pragma enable_d3d11_debug_symbols

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ CAMERA_VERTEX WORLD_VERTEX CAMERA_NORMAL HIT_PASS NORMAL_UV
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
            CBUFFER_START(UnityPerMaterial) // Required to be compatible with SRP Batcher
            float4 _MainTex_ST;
          float maxDistance;
          float resolution;
          float steps ;
          float thickness;
          float roughness;
            CBUFFER_END
            
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                //vertex
                o.screenPos = ComputeScreenPos(o.vertex);//o.vertex????????????????????????

                return o;
            }


            float RayMarch(float3 viewPos,float3 viewNormal,
                float p_maxDistance,
                float p_resolution,
                float p_steps ,
                float p_thickness ,
                out float2 hituv)
            {
                
              float3 unitPositionFrom = normalize(viewPos);
                //????????????
              float3 pivot = normalize(reflect(unitPositionFrom,viewNormal));

              

                //?????????????????????
              float4 startView = float4(viewPos.xyz + (pivot *           0), 1);
              float4 endView   = float4(viewPos.xyz + (pivot * p_maxDistance), 1);

                  // ...
                //?????????????????????????????????????????????
                float4 startFrag      = startView;
               // Project to screen space.
               startFrag      = mul(unity_CameraProjection,startFrag);
               startFrag = ComputeScreenPos(startFrag);
               // Perform the perspective divide.
               startFrag.xyz /= startFrag.w;
               // Convert the screen-space XY coordinates to UV coordinates.
               startFrag.x = 1- startFrag.x;
               // Convert the UV coordinates to fragment/pixel coordnates.
               startFrag.xy  *= _ScreenParams.xy;

               float4 endFrag      = endView;
               // Project to screen space.
               endFrag      = mul(unity_CameraProjection,endFrag);
               endFrag = ComputeScreenPos(endFrag);
               // Perform the perspective divide.
               endFrag.xyz /= endFrag.w;
               // Convert the screen-space XY coordinates to UV coordinates.
               endFrag.x = 1- endFrag.x;
               // Convert the UV coordinates to fragment/pixel coordnates.
               endFrag.xy  *= _ScreenParams.xy;              


               //????????????????????????
                float deltaX    = endFrag.x - startFrag.x;
                float deltaY    = endFrag.y - startFrag.y;
                //?????????????????????????????????
                float useX = abs(deltaX)>=abs(deltaY)?1:0;
                float delta     = lerp(abs(deltaY), abs(deltaX), useX) * clamp(p_resolution, 0, 1);
                float2  increment = float2(deltaX, deltaY) / max(delta, 0.001);


                //?????????????????????
                float search0 = 0;
                float search1 = 0;

                //????????????????????????
                float hit0 =0.0f;
                float hit1 =0.0f;

                //?????????????????????
                float viewDistance = startView.z;
                float depth        = thickness;

                float2 frag = startFrag.xy;
                float2 uv = frag/_ScreenParams.xy;
                //framebuff??????
                float4 viewPathPos;

              for (int i = 0; i < int(400); ++i) {
                  frag      += increment;
                  uv.xy      = frag / _ScreenParams.xy;
                  float deviceDepth = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, uv.xy,0);
                  float3 colorWorldPos = ComputeWorldSpacePosition(uv.xy, deviceDepth, UNITY_MATRIX_I_VP);
                  viewPathPos = mul(unity_WorldToCamera, float4(colorWorldPos, 1.0)); //TransformWorldToView(UNITY_MATRIX_V,float4(colorWorldPos,1.0));  

                  //?????????????????????
                  search1 = lerp((frag.y-startFrag.y)/deltaY,(frag.x-startFrag.x)/deltaX,useX);
                  //??????????????????????????????
                  viewDistance = (startView.z*endView.z)/lerp(endView.z,startView.z,search1);

                  depth        = viewDistance - viewPathPos.z;
                  //??????????????????????????????framebuff????????????????????????????????????
                  if(depth>0 && depth<p_thickness)
                  {
                      hit0=1;
                      break;
                  }else
                  {
                      //???????????????????????????
                      search0=search1;
                  }
              }
              hituv = uv;
              float visibility = (hit0);

              //??????????????????????????????,???????????????
                 search1 = search0 + ((search1 - search0) / 2);
                int iter_steps = int(p_steps*hit0);
                for (int i = 0; i < iter_steps; ++i) {
                    frag      = lerp(startFrag.xy, endFrag.xy, search1);
                    uv.xy      = frag / _ScreenParams.xy;
                    float deviceDepth = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, uv.xy,0);
                    float3 colorWorldPos = ComputeWorldSpacePosition(uv.xy, deviceDepth, UNITY_MATRIX_I_VP);
                    viewPathPos = mul(unity_WorldToCamera, float4(colorWorldPos, 1.0)); //TransformWorldToView(UNITY_MATRIX_V,float4(colorWorldPos,1.0));  
                
                    //??????????????????????????????
                    viewDistance = (startView.z*endView.z)/lerp(endView.z,startView.z,search1);
                
                    depth        = viewDistance - viewPathPos.z;
                
                    //??????????????????????????????framebuff????????????????????????????????????
                    if(depth>0 && depth<p_thickness)
                    {
                        hit1=1;
                        //??????,??????hit0???search0
                        search1 = search0 + ((search1 - search0) / 2);
                    }else
                    {
                        //??????,??????hit0???search1
                        float temp = search1;
                        search1 = search1 + ((search1 - search0) / 2);
                        search0 = temp;
                    }
                }
                hituv = uv;
                visibility = (hit1);
                float alphaFactor = viewPathPos.w;
                float hitDepthFactor = (1-clamp(depth/p_thickness,0,1));
                float reflectFactor = (1-max(dot(-unitPositionFrom,pivot),0));
                float distanceFactor = (1-clamp(length(viewPathPos.xyz-viewPos)/maxDistance,0,1));
                float uvFactor =      (uv.x < 0 || uv.x > 1 ? 0 : 1) * (uv.y < 0 || uv.y > 1 ? 0 : 1);
                visibility *= alphaFactor*hitDepthFactor*reflectFactor*distanceFactor*uvFactor;

            
              return visibility;
            }
            
            half4 frag (v2f input) : SV_Target
            {

              float4 ndcPos = (input.screenPos / input.screenPos.w);
              #ifdef NORMAL_UV
                return float4(ndcPos.xy,0.0,1.0);    
              #endif


              float deviceDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, ndcPos.xy);
              float3 colorWorldPos = ComputeWorldSpacePosition(ndcPos.xy, deviceDepth, UNITY_MATRIX_I_VP);
              float4 viewPos = mul(unity_WorldToCamera, float4(colorWorldPos, 1.0)); //TransformWorldToView(UNITY_MATRIX_V,float4(colorWorldPos,1.0));
        

              
              #ifdef CAMERA_VERTEX
              return float4(viewPos.xyz,1.0);
              #endif
              
                            
              #ifdef WORLD_VERTEX
              return float4(colorWorldPos.xyz,1.0);
              #endif
              
              float3 normalView = normalize(SampleSceneNormals(ndcPos.xy));
           
              #ifdef CAMERA_NORMAL
              return float4(normalView,1.0);
              #endif



              float2 hituv;
              float rayHit = RayMarch(viewPos,normalView,
                maxDistance,
                resolution,
                steps ,
                thickness,
                hituv);
                #ifdef HIT_PASS
                if(rayHit>0){
                    return float4(rayHit,0.0,0.0,1.0);
                }else
                {
                    return float4(0.0,0.0,0.0,1.0);
                }
                #endif

                float4 rayHitColor = tex2D(_MainTex, hituv)*rayHit;
                float4 sourceTexColor  = tex2D(_MainTex, ndcPos.xy);
                float4 mainTexColor = lerp(rayHitColor,sourceTexColor,clamp(roughness,0,1));

                return float4(mainTexColor);    
            }
            ENDHLSL
        }
    }
}
