
Shader "Shader/Shader_015DepthOfField"
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
            };
            
            Varyings FullscreenVert(Attributes input)
            {
                Varyings o;
                o.vertex = TransformObjectToHClip(input.vertex.xyz);
                o.uv = TRANSFORM_TEX(input.uv, _MainTex);
                o.color = input.color;
                return o;
            }
            
            half4 FragBlurH(Varyings input) : SV_Target
            {
                 //int size = int(_blurSize.x);
                 float sperate = _blurSize.y;
                 half4 c0 = tex2D(_MainTex, input.uv.xy+sperate*float2(-2,0)/_ScreenParams.xy);
                 half4 c1 = tex2D(_MainTex, input.uv.xy+sperate*float2(-1,0)/_ScreenParams.xy);
                 half4 c2 = tex2D(_MainTex, input.uv.xy);
                 half4 c3 = tex2D(_MainTex, input.uv.xy+sperate*float2(1,0)/_ScreenParams.xy);
                 half4 c4 = tex2D(_MainTex, input.uv.xy+sperate*float2(2,0)/_ScreenParams.xy);
                 return c0*0.1+c1*0.2+
                        c2*0.4+
                        c0*0.2+c1*0.1;

            }
            half4 FragBlurV(Varyings input) : SV_Target
            {
                 float sperate = _blurSize.y;
                 half4 c0 = tex2D(_MainTex, input.uv.xy+sperate*float2(0,-2)/_ScreenParams.xy);
                 half4 c1 = tex2D(_MainTex, input.uv.xy+sperate*float2(0,-1)/_ScreenParams.xy);
                 half4 c2 = tex2D(_MainTex, input.uv.xy);
                 half4 c3 = tex2D(_MainTex, input.uv.xy+sperate*float2(0,1)/_ScreenParams.xy);
                 half4 c4 = tex2D(_MainTex, input.uv.xy+sperate*float2(0,2)/_ScreenParams.xy);
                 return c0*0.1+c1*0.2+
                        c2*0.4+
                        c0*0.2+c1*0.1;
            }
                        
            half4 FragMix(Varyings input) : SV_Target
            {
               float deviceDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, input.uv.xy);
               float3 colorWorldPos = ComputeWorldSpacePosition(input.uv.xy, deviceDepth, UNITY_MATRIX_I_VP);
               float4 viewPos = mul(unity_WorldToCamera, float4(colorWorldPos, 1.0)); //TransformWorldToView(UNITY_MATRIX_V,float4(colorWorldPos,1.0));
               
               float mdeviceDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, mouseFocusPoint.xy);
               float3 mcolorWorldPos = ComputeWorldSpacePosition(mouseFocusPoint.xy, mdeviceDepth, UNITY_MATRIX_I_VP);
               float4 mviewPos = mul(unity_WorldToCamera, float4(mcolorWorldPos, 1.0)); //TransformWorldToView(UNITY_MATRIX_V,float4(colorWorldPos,1.0));
        
               float diff = abs(viewPos.z - mviewPos.z);
               //return half4(diff,diff,diff,1);

               float blur =
                smoothstep
                  ( minDistance
                  , maxDistance
                  , diff
                  )*mouseFocusPoint.z;
                //return half4(blur,blur,blur,1);
                half4 c1 = tex2D(_BlurTex, input.uv.xy);
                half4 c2 = tex2D(_MainTex, input.uv.xy);
                return lerp(c2,c1,blur);
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
        
        //1
        Pass
        {            
            HLSLPROGRAM
            #pragma vertex FullscreenVert
            #pragma fragment FragBlurH           
            ENDHLSL
        }
        
        //2
        Pass
        {            
            HLSLPROGRAM
            #pragma vertex FullscreenVert
            #pragma fragment FragBlurV           
            ENDHLSL
        }
        
        //3 mix
        Pass
        {            
            HLSLPROGRAM
            #pragma vertex FullscreenVert
            #pragma fragment FragMix           
            ENDHLSL
        }
    }
}
