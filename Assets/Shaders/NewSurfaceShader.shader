Shader "Custom/NewSurfaceShader"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Range ("Range", Range(0,20))=5
    }
    SubShader
    {
        Pass{
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex; 
            float4 _MainTex_ST;   
            float _Range;

            struct a2v{
                float4 vertex:POSITION;
                float4 texcoord:TEXCOORD0; 
            };
            struct v2f{
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD0;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.uv=TRANSFORM_TEX(v.texcoord,_MainTex); 
                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                fixed4 pixel=tex2D(_MainTex,i.uv);
                pixel += (ddx(pixel)+ddy(pixel))*_Range;
                return fixed4(pixel.rgb,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
