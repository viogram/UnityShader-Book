Shader "Custom/S_ScrollingBackground"
{
    Properties
    {
        _MainTex ("Base Layer", 2D) = "white" {}
        _DetailTex("2nd Layer", 2D) = "white" {}
        _ScrollX("Base Layer Scroll Speed",Float)=1
        _Scroll2X("2nd Layer Scroll Speed",Float)=1
        _Multiplier("Layer Multiplier",Float)=1  //控制纹理整体亮度
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
            };

            sampler2D _MainTex;
			sampler2D _DetailTex;
			float4 _MainTex_ST;
			float4 _DetailTex_ST;
			float _ScrollX;
			float _Scroll2X;
			float _Multiplier;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex)+frac(float2(_ScrollX,0)*_Time.y);
                o.uv2 = TRANSFORM_TEX(v.texcoord, _DetailTex)+frac(float2(_Scroll2X,0)*_Time.y);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.uv.y=1-i.uv.y;
                i.uv2.y=1-i.uv2.y;
                fixed4 baseLayer=tex2D(_MainTex,i.uv);
                fixed4 secondLayer=tex2D(_DetailTex,i.uv2);
                fixed4 col=lerp(baseLayer,secondLayer,secondLayer.a);
                col.rgb*=_Multiplier;
                
                return col;
            }
            ENDCG
        }
    }
    FallBack "VertexLit"
}
