Shader "Shader/Shader_004Dilation"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("MainColor", Color) = (1,1,1,1)
        size("size",int )= 4
        separation("separation",float )= 1
        minThreshold("minThreshold",float )= 0.1
        maxThreshold("maxThreshold",float )= 0.3
        
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
            //大小和分离参数控制图像如何膨胀。更大的尺寸将以性能为代价增加膨胀。更大的分离会以质量为代价增加膨胀。minThreshold和maxThreshold参数控制图像的哪些部分被放大。
            
            int size;
            float separation;
            float minThreshold;
            float maxThreshold;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                return o;
            }
            
            //颜色转换为灰度           
            void node_rgbtobw(float4 color, out float outval)
            {
              float3 factors = float3(0.2126, 0.7152, 0.0722);
              outval = dot(color.rgb, factors);
            }

 
            half4 frag (v2f input) : SV_Target
            {
                // sample the texture
                //
                
              float4 color = tex2D(_MainTex, input.uv.xy);
              //循环通过一个按大小排列的窗口，以当前片段位置为中心。在循环过程中，根据周围的灰度值找到最亮的颜色。
              float  mx = 0.0f;
              float4  cmx = color;
            
              for (int i = -size; i <= size; ++i) {
                for (int j = -size; j <= size; ++j) {
                  // ...
                  // ...
                  // For a rectangular shape.
                  //if (false);            
                  // For a diamond shape;
                  //if (!(abs(i) <= size - abs(j))) { continue; }            
                  // For a circular shape.
                  if (!(distance(float2(i, j), float2(0, 0)) <= size)) { continue; }
                                                 
                  float4 c = tex2D(_MainTex,input.uv.xy + (float2(i,j)/_ScreenParams.xy) * separation);
                  float gray = 0;
                  node_rgbtobw(c,gray);
                  if (gray>mx){
                      mx = gray;
                      cmx = c;
                  }
                }
              }
                                         
  
              half4 texColor = lerp(color,cmx,smoothstep(minThreshold,maxThreshold,mx));
              return texColor;
                            
            }
            ENDHLSL
        }
    }
}
