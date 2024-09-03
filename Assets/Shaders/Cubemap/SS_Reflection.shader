Shader "Custom/SS_Reflection"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _ReflectColor ("Reflection Color", Color)=(1,1,1,1)
        _ReflectAmount("Reflect Amount", Range(0,1))=1
        _Cubemap("Reflection Cubemap", Cube)="_Skybox"{}
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
            fixed4 _ReflectColor;
            fixed _ReflectAmount;
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
                float3 worldRefl:TEXCOORD3;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                o.worldNormal=normalize(UnityObjectToWorldNormal(v.normal));
                o.worldViewDir=normalize(UnityWorldSpaceViewDir(o.worldPos));
                //计算在世界空间中的反射方向
                o.worldRefl=reflect(-o.worldViewDir,o.worldNormal);

                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                fixed3 worldLightDir=normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse=_LightColor0.rgb*_Color.rgb*saturate(dot(worldLightDir, i.worldViewDir));
                fixed3 reflection=texCUBE(_Cubemap,i.worldRefl).rgb*_ReflectColor.rgb;
                
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                fixed3 color=ambient+lerp(diffuse,reflection,_ReflectAmount)*atten;

                return fixed4(color,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
