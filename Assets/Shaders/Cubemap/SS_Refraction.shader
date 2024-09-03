Shader "Custom/SS_Refraction"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _RefractColor ("Refraction Color", Color)=(1,1,1,1)
        _RefractAmount("Refract Amount", Range(0,1))=1
        _RefractRatio ("Refraction Ration", Range(0,1))=0.5
        _Cubemap("Refraction Cubemap", Cube)="_Skybox"{}
    }
    SubShader
    {
        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            fixed4 _RefractColor;
            fixed _RefractAmount;
            fixed _RefractRatio;
            samplerCUBE _Cubemap;

            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
            };

            struct v2f{
                float4 pos:SV_POSITION;
                float3 worldPos:TEXCOORD0;
                float3 worldNormal:TEXCOORD1;
                float3 worldViewDir:TEXCOORD2;
                float3 worldRefr:TEXCOORD3;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                o.worldNormal=normalize(UnityObjectToWorldNormal(v.normal));
                o.worldViewDir=normalize(UnityWorldSpaceViewDir(o.worldPos));
                //计算在世界空间中的折射方向
                o.worldRefr=refract(-o.worldViewDir,o.worldNormal,_RefractRatio);

                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                fixed3 worldLightDir=normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse=_LightColor0.rgb*_Color.rgb*saturate(dot(worldLightDir, i.worldViewDir));
                fixed3 refraction=texCUBE(_Cubemap,i.worldRefr).rgb*_RefractColor.rgb;
                
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                fixed3 color=ambient+lerp(diffuse,refraction,_RefractAmount)*atten;

                return fixed4(color,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
