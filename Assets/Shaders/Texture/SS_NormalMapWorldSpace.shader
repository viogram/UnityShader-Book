// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/SS_NormalMapWorldSpace"
{
     Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _Specular ("Specular", Color) =(1,1,1,1)
        _Gloss ("Gloss", Range(8,256))=20
        _MainTex("Main Tex",2D)="white" {}
        _BumpMap("Normal Map",2D)="bump"{}
        _BumpScale("Bump Scale",float)=1.0
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
            sampler2D _MainTex;  
            float4 _MainTex_ST;   
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;

            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float4 tangent:TANGENT; //注意切线是float4类型，因为需要w方向来确定副切线的方向
                float4 texcoord:TEXCOORD0; 
            };
            struct v2f{
                float4 pos:SV_POSITION;
                float2 uv_tex:TEXCOORD0;
                float2 uv_normal:TEXCOORD1;
                float4 TtoW0:TEXCOORD2;
                float4 TtoW1:TEXCOORD3;
                float4 TtoW2:TEXCOORD4;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.uv_tex=TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv_normal=TRANSFORM_TEX(v.texcoord,_BumpMap);

                float3 worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                float3 worldNormal=UnityObjectToWorldNormal(v.normal);
                float3 worldTangent=UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldBinormal=cross(worldNormal, worldTangent) * v.tangent.w;

                o.TtoW0=float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1=float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2=float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

               return o;
            }

            fixed4 frag(v2f i):SV_Target{
                fixed4 packedNormal=tex2D(_BumpMap,i.uv_normal);
                fixed3 tangentNormal;
                tangentNormal=UnpackNormal(packedNormal);
                tangentNormal.xy*=_BumpScale;
                tangentNormal.z=sqrt(1.0-saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                tangentNormal=normalize(fixed3(dot(i.TtoW0.xyz, tangentNormal), 
                                               dot(i.TtoW1.xyz, tangentNormal), 
                                               dot(i.TtoW2.xyz, tangentNormal)));

                
                float3 worldPos=float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                float3 lightDir=UnityWorldSpaceLightDir(worldPos);
                float3 viewDir=UnityWorldSpaceViewDir(worldPos);

                fixed3 albedo=tex2D(_MainTex,i.uv_tex).rgb * _Color.rgb;
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse=_LightColor0.rgb * albedo * saturate(dot(lightDir,tangentNormal));
                
                float3 halfDir=normalize(lightDir+viewDir);
                fixed3 specular=_LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir,tangentNormal)),_Gloss);
                
                fixed3 color=ambient+diffuse+specular;
                return fixed4(color,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
