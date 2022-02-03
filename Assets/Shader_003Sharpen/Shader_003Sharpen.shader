Shader "Shader/Shader_003Sharpen"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("MainColor", Color) = (1,1,1,1)
        _amount("amount",float )= 0.8
        
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
            float _amount;
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

              float neighborWeigth = _amount * -1;
              float centerWeigth   = _amount * 4 + 1;
              float sx = i.uv.x*_ScreenParams.x;
              float sy = i.uv.y*_ScreenParams.y;
              
              float4 color = tex2D(_MainTex, float2(sx+0,sy+1)/_ScreenParams.xy)*neighborWeigth
              + tex2D(_MainTex, float2(sx+0,sy-1)/_ScreenParams.xy)*neighborWeigth
              + tex2D(_MainTex, float2(sx+1,sy+0)/_ScreenParams.xy)*neighborWeigth
              + tex2D(_MainTex, float2(sx-1,sy+0)/_ScreenParams.xy)*neighborWeigth
              + tex2D(_MainTex, float2(sx+0,sy+0)/_ScreenParams.xy)*centerWeigth;
              
              
  
              half4 texColor = color;
              return texColor;
                            
            }
            ENDHLSL
        }
    }
}
