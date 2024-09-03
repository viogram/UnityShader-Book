Shader "Custom/SS_GoodRay"
{
    Properties
    {
        _MainTex("Base (RGB)", 2D) = "white" {}
		_BlurTex("Blur", 2D) = "white"{}
    }
    SubShader
    {
        ZTest Always
        ZWrite Off
        Cull Off

        CGINCLUDE

        #define RADIAL_SAMPLE_COUNT 6
	    #include "UnityCG.cginc"

        sampler2D _MainTex;
	    float4 _MainTex_TexelSize;
	    sampler2D _BlurTex;
	    float4 _BlurTex_TexelSize;
	    float4 _ViewPortLightPos;
	
	    float4 _offsets;
	    float4 _ColorThreshold; //高亮部分阈值
	    float4 _LightColor; //光颜色
	    float _LightFactor; //光强度
	    float _PowFactor; //提取高亮结果Pow系数，用于适当降低颜色过亮的情况
	    float _LightRadius; //光源范围

        struct v2fExtractBright{
            float4 pos:SV_POSITION;
            float2 uv:TEXCOORD0;
        };

        v2fExtractBright vertExtractBright(appdata_img v){
            v2fExtractBright o;
            o.pos=UnityObjectToClipPos(v.vertex);
            o.uv=v.texcoord;
            #if UNITY_UV_STARTS_AT_TOP
		    if (_MainTex_TexelSize.y < 0)
			    o.uv.y = 1 - o.uv.y;
		    #endif	
		    return o;
        }

        fixed luminance(fixed4 color){
            return 0.2125*color.r+0.7154*color.g+0.0721*color.b;
        }

        fixed4 fragExtractBright(v2fExtractBright i):SV_Target{
            fixed4 color=tex2D(_MainTex,i.uv);
            float distFromLight=length(_ViewPortLightPos.xy-i.uv);
            float distControl=saturate(_LightRadius-distFromLight);

            float4 thresholdColor=saturate(color-_ColorThreshold)*distControl;
            float luminanceColor=luminance(thresholdColor);
            luminanceColor=pow(luminanceColor,_PowFactor);
            return fixed4(luminanceColor,luminanceColor,luminanceColor,1);
        }

        struct v2fRadialBlur{
            float4 pos:SV_POSITION;
            float2 uv:TEXCOORD0;
            float2 blurOffset:TEXCOORD1;
        };

        v2fRadialBlur vertRadialBlur(appdata_img v){
            v2fRadialBlur o;
            o.pos=UnityObjectToClipPos(v.vertex);
            o.uv=v.texcoord;

            o.blurOffset=_offsets.x*(_ViewPortLightPos-o.uv);
            return o;
        }

        fixed4 fragRadialBlur(v2fRadialBlur i):SV_Target{
            half4 color = half4(0,0,0,0);
		    //通过迭代，将采样得到的RGB值累加
		    for(int j = 0; j < RADIAL_SAMPLE_COUNT; j++)   
		    {	
			    color += tex2D(_MainTex, i.uv.xy);
			    i.uv.xy += i.blurOffset; 	
		    }
		    //最后除以迭代次数
		    return color / RADIAL_SAMPLE_COUNT;
        }

        struct v2fGodRay{
            float4 pos : SV_POSITION;
		    float2 uv  : TEXCOORD0;
		    float2 uv1 : TEXCOORD1;
        };

        v2fGodRay vertGodRay(appdata_img v){
            v2fGodRay o;
            o.pos=UnityObjectToClipPos(v.vertex);
            o.uv=v.texcoord;
            o.uv1.xy = o.uv.xy;
		    #if UNITY_UV_STARTS_AT_TOP
		    if (_MainTex_TexelSize.y < 0)
			    o.uv.y = 1 - o.uv.y;
		    #endif	
		    return o;
        }

        fixed4 fragGodRay(v2fGodRay i):SV_Target{
            fixed4 ori=tex2D(_MainTex, i.uv1);
            fixed4 blur=tex2D(_BlurTex, i.uv);
            return ori+_LightFactor*blur*_LightColor;
        }

        ENDCG

        //提取高亮部分
        Pass{
            CGPROGRAM
            #pragma vertex vertExtractBright
            #pragma fragment fragExtractBright
            ENDCG
        }
        //径向模糊
        Pass{
            CGPROGRAM
            #pragma vertex vertRadialBlur
            #pragma fragment fragRadialBlur
            ENDCG
        }
        //混合
        Pass{
            CGPROGRAM
            #pragma vertex vertGodRay
            #pragma fragment fragGodRay
            ENDCG
        }
    }
}
