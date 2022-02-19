
Shader "Shader/Shader_012ChromaticAberration"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        redOffset("redOffset",float )= 0.009
        greenOffset("greenOffset",float )= 0.006
        blueOffset("blueOffset",float )= -0.006
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
            float redOffset;
            float greenOffset;
            float blueOffset;
            float3 mouseFocusPoint;
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



            half4 frag (v2f input) : SV_Target
            {

               float4 mainTexColor = tex2D(_MainTex, input.uv.xy);
               
               
               float2 direction = input.uv - mouseFocusPoint.xy-input.uv*(1-mouseFocusPoint.z);
               
               float4 fragColor;
                fragColor.r  = tex2D(_MainTex, input.uv + (direction * (redOffset  ))).r;
                fragColor.g  = tex2D(_MainTex, input.uv + (direction * (greenOffset))).g;
                fragColor.ba = tex2D(_MainTex, input.uv + (direction * (blueOffset ))).ba;
               
               return fragColor;

            }
            ENDHLSL
        }
    }
}
