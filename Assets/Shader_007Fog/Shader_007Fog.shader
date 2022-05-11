
Shader "Shader/Shader_007Fog"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FogColor ("FogColor", Color) = (1,1,1,1)
        _nearFar("NearFar",Vector )= (0.1,0.2,0,0)
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
            //为了计算雾，你需要它的颜色、近距离和远距离。
            float2 _nearFar;
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

            //利用屏幕空间坐标+深度值转成像素点对应的世界坐标
            float4 ConvertDepth2WorldPos(float2 uv,float depth,float4x4 viewProjectInverseMatrix){
	            float4 H = float4(uv,depth,1);
	            float4 D = mul(viewProjectInverseMatrix,H);
	            float4 worldPos =D/D.w;
	            return worldPos;
            }

             
            half4 frag (v2f input) : SV_Target
            {
              float4 ndcPos = (input.screenPos / input.screenPos.w);
              float4 mainTexColor = tex2D(_MainTex, input.uv.xy);

              float deviceDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, ndcPos.xy);
             //float3 colorWorldPos = ComputeWorldSpacePosition(ndcPos.xy, deviceDepth, UNITY_MATRIX_I_VP);

              float4 colorWorldPos = ConvertDepth2WorldPos(ndcPos.xy,deviceDepth,unity_MatrixInvVP);
              float4 cameraPos = mul(unity_WorldToCamera,colorWorldPos);

              float fogMin = 0.00;
              float fogMax = 1;

              float near = _nearFar.x;
              float far  = _nearFar.y;

              float intensity =
                clamp
                  ((cameraPos.z - near)
                    / (far        - near)
                  , fogMin
                  , fogMax
                  );

              float4 fragColor = float4(_FogColor.rgb, min(intensity, 1));

              //float4 fragColor = lerp(mainTexColor, _FogColor, min(intensity, 1));
                
              half4 texColor = fragColor;
              return texColor;
              //return float4(0,0,intensity,1);
                            
            }
            ENDHLSL
        }
    }
}
