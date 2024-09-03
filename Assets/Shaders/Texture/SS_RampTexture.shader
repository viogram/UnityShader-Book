Shader "Custom/SS_RampTexture"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _Specular ("Specular", Color) =(1,1,1,1)
        _Gloss ("Gloss", Range(8,256))=20
        _RampTex("Ramp Tex",2D)="white" {}
    }
    SubShader
    {
        Pass
        {
            //该标签定义了该Pass在Unity光照流水线中的角色，有了它才能使用一些内置的光照变量
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;   
            fixed4 _Specular;  
            float _Gloss;  
            sampler2D _RampTex;  
            float4 _RampTex_ST;   

            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float4 texcoord:TEXCOORD0;
            };
            struct v2f{
                float4 pos:SV_POSITION;
                float3 worldNormal:TEXCOORD1;
                float3 worldPos:TEXCOORD2;
                float2 uv:TEXCOORD3;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.worldNormal=normalize(mul((float3x3)unity_ObjectToWorld,v.normal));
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv=TRANSFORM_TEX(v.texcoord,_RampTex); 

                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                float3 worldLight=normalize(UnityWorldSpaceLightDir(i.worldPos));   
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                fixed halfLambert=0.5*dot(i.worldNormal, worldLight)+0.5;
                fixed3 diffuseColor=tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb * _Color.rgb;

                float3 viewDir=normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 halfDir=normalize(worldLight+viewDir);

                fixed3 diffuse=_LightColor0.rgb * diffuseColor;
                fixed3 specular=_LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir,i.worldNormal)),_Gloss);
                fixed3 color=ambient+diffuse+specular;
                return fixed4(color,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
