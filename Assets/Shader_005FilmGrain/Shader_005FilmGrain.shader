Shader "Shader/Shader_005FilmGrain"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("MainColor", Color) = (1,1,1,1)
        _amount("amount",float )= 0.1
        
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
            //用量控制胶片颗粒的明显程度。打开它，拍雪景。            
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
            

 
            half4 frag (v2f input) : SV_Target
            {
                // sample the texture
                //
                  float toRadians = 3.14 / 180;
                  //这段代码计算了调整数量所需的随机强度。
                  float2 suv = input.uv*_ScreenParams.xy;
                  float tadiuInput = (suv.x+suv.y*_Time.y)*toRadians;
                  float randomIntensity = frac(100*
                    sin(tadiuInput)
                  );

              float4 color = tex2D(_MainTex, input.uv.xy);
              color.rgb += _amount*randomIntensity;
              half4 texColor = color;
              return texColor;
                            
            }
            ENDHLSL
        }
    }
}
