Shader "Shader/Shader_002Pixelization"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("MainColor", Color) = (1,1,1,1)
        _pixelSize("pixelSize",float )= 5
        
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
            CBUFFER_START(UnityPerMaterial) // Required to be compatible with SRP Batcher
            float4 _MainTex_ST;
            float4 _Color;
            float _pixelSize;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                return o;
            }
            
          
 
            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
              float x = fmod((i.uv.x*_ScreenParams.x) , (_pixelSize));
              float y = fmod((i.uv.y*_ScreenParams.y) , (_pixelSize));
            
              x = floor(_pixelSize / 2.0) - x;
              y = floor(_pixelSize / 2.0) - y;
            
              x = i.uv.x + x/_ScreenParams.x;
              y = i.uv.y + y/_ScreenParams.y;
              half4 texColor = tex2D(_MainTex, float2(x,y));
              return texColor;
                            
            }
            ENDHLSL
        }
    }
}
