
Shader "Shader/Shader_006LUT"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _lookupTableTexture ("lookupTableTexture", 2D) = "white" {}
        _Color ("MainColor", Color) = (1,1,1,1)
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
            
            sampler2D _lookupTableTexture;
            CBUFFER_START(UnityPerMaterial) // Required to be compatible with SRP Batcher
            float4 _MainTex_ST;
            //float4 _lookupTableTexture_ST;
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
            
            //在开始之前，您需要找到一个中立的LUT映像。中性意味着它让片段颜色保持不变。LUT需要是256像素宽，16像素高，包含16个块，每个块是16 × 16像素。
 
            half4 frag (v2f input) : SV_Target
            {

              float4 color = tex2D(_MainTex, input.uv.xy);
              
              
                // ...
            
              float u  =  floor(color.b * 15.0) / 15.0 * 240.0;
                    u  = (floor(color.r * 15.0) / 15.0 *  15.0) + u;
                    u /= 255.0;
            
              float v  = ceil(color.g * 15.0);
                    v /= 15.0;
                    v  = 1.0 - v;

                float3 left = tex2D(_lookupTableTexture, float2(u, v)).rgb;
        
                  // ...
                  
                    // ...
                
                  u  =  ceil(color.b * 15.0) / 15.0 * 240.0;
                  u  = (ceil(color.r * 15.0) / 15.0 *  15.0) + u;
                  u /= 255.0;
                
                  v  = 1.0 - (ceil(color.g * 15.0) / 15.0);
                
                  float3 right = tex2D(_lookupTableTexture, float2(u, v)).rgb;
                
                  // ...
                  
                                // ...
            //不是每个频道都能完美地映射到16种可能性中的一种。
            //例如，0.5不能完美地映射。
            //在下界(floor)处，它映射到0.466666666666666667，在上界(ceil)处，它映射到0.53333333333333。
            //将其与0.4进行比较，0.4下界对应0.4，上界对应0.4。
            //对于那些没有完美映射的通道，您需要根据通道位于其上下边界之间的位置来混合左右两边。
            //对于0.5，它直接落在它们之间，使最终的颜色是一半左一半右的混合。
            //然而，对于0.132，混合物将是98%的右和2%的左，因为0.123乘以15.0的分数部分是0.98。
            
              color.r = lerp(left.r, right.r, frac(color.r * 15.0));
              color.g = lerp(left.g, right.g, frac(color.g * 15.0));
              color.b = lerp(left.b, right.b, frac(color.b * 15.0));
            
              // ...
              

              half4 texColor = color;
              return texColor;
                            
            }
            ENDHLSL
        }
    }
}
