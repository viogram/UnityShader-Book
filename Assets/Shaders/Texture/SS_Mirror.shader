Shader "Custom/SS_Mirror"
{
    Properties
    {
        _MainTex("Main Tex",2D)="white" {}
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;   

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
                o.uv=v.texcoord.xy;
                o.uv.x=1-o.uv.x;

                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                return tex2D(_MainTex,i.uv);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
