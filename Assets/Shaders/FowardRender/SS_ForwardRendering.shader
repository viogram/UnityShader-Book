Shader "Custom/SS_ForwardRendering"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}
        _Specular ("Specular", Color) =(1,1,1,1)
        _Gloss ("Gloss", Range(8,256))=20
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}

        Pass{
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM

            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
            fixed4 _Specular; 
            float _Gloss;  

            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float4 texcoord:TEXCOORD0;
            };
            struct v2f{
                float4 pos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                float2 uv:TEXCOORD2;
                SHADOW_COORDS(3)
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.worldNormal=normalize(UnityObjectToWorldNormal(v.normal));
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);
                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                fixed3 albedo=tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;

                float3 worldLight=normalize(UnityWorldSpaceLightDir(i.worldPos));   
                
                float3 viewDir=normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 halfDir=normalize(worldLight+viewDir);

                fixed3 diffuse=_LightColor0.rgb * albedo * saturate(dot(worldLight,i.worldNormal));
                fixed3 specular=_LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir,i.worldNormal)),_Gloss);

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                fixed3 color=ambient+(diffuse+specular)*atten;

                return fixed4(color,1.0);
            }
            ENDCG
        }

        Pass{
            Tags{"LightMode"="ForwardAdd"}
            Blend One One

            CGPROGRAM

            #pragma multi_compile_fwdadd
             #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
            fixed4 _Specular; 
            float _Gloss;  

            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float4 texcoord:TEXCOORD0;
            };
            struct v2f{
                float4 pos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                float2 uv:TEXCOORD2;
                SHADOW_COORDS(3)
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.worldNormal=normalize(UnityObjectToWorldNormal(v.normal));
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);
                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                fixed3 albedo=tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                //UnityWorldSpaceLightDir近可用于前向渲染，输入世界空间的坐标，返回该点到光源的方向
                float3 worldLight=normalize(UnityWorldSpaceLightDir(i.worldPos));
                //UnityWorldSpaceViewDir输入世界空间的坐标，返回该点到摄像机的观察方向
                float3 viewDir=normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 halfDir=normalize(worldLight+viewDir);

                fixed3 diffuse=_LightColor0.rgb * albedo * saturate(dot(worldLight,i.worldNormal));
                fixed3 specular=_LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir,i.worldNormal)),_Gloss);

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                fixed3 color=(diffuse+specular)*atten;
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
