Shader "Shader/Shader_001UVAnimation-Move"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("MainColor", Color) = (1,1,1,1)
        _SunRoundColor("SunRoundColor", Color) = (1,1,0,1)
        _SunRoundFactor("SunRoundFactor",float)=0.1
        
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
            float _SunRoundFactor;
            float4 _SunRoundColor;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                return o;
            }
            
            
            float IsInside(float2 clipPos,float radius,float2 center){
                //float2 dir = clipPos - float2(0.5f,0.5f);
                float dis = distance(clipPos,center);
                return step(radius,dis);
                //return dis;
            }
            
            //float4 _SinTime; // sin(t/8), sin(t/4), sin(t/2), sin(t)

 //画太阳光环
            float DrawSunCircle(float2 uv,float2 center,float size) {
                 uv = uv - center;
                 uv = uv / size;
                 //atan2返回点(x,y)与x轴的夹角，范围(-π,π]
                 //获取极坐标的θ角度
                 float degree = atan2(uv.y , uv.x ) + _Time.y * -0.1;
                 //uv向量离中心点距离
                 //获取极坐标的r=x2+y2开方
                 float len = length(uv);
                 //根据极坐标玫瑰线:r(θ)=a*sin(kθ)
                 //求得r;a为扩散幅度，k为花瓣数*0.5
                 float r = 0.2*abs(sin(degree*10.0));
                 //画花瓣
                 //保留r值小于到中心点距离的所有像素
                 float sunRound= smoothstep(r + 0.1 + _SunRoundFactor, r + _SunRoundFactor, len);
                 //return float4(1.0f,1.0f,1.0f,sunRound)*_SunRoundColor;
                 return sunRound;
            }
 
            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
                half4 texColor = tex2D(_MainTex, i.uv);
                half4 col = i.color;
                // apply fog
                //_Time.
                float y = saturate(fmod(_Time.y*1.5f,1));
                //float uy = abs(fmod(i.uv.x+_Time.y*0.01,y)*2.0f-y);               
                float uy =0;
                float2 center= float2(0.5f,0.5f);
                
                float2 dir = i.uv - float2(0.5f,0.5f);
                float2 newuv = i.uv-normalize(dir)*y;
                
                float isInside = IsInside(i.uv,y+uy,center);
                float sunCircle = DrawSunCircle(newuv,center,y);
                
                col.a = isInside+sunCircle;
                return col*texColor;
            }
            ENDHLSL
        }
    }
}
