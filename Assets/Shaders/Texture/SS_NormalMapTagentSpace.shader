Shader "Custom/SS_NormalMapTagentSpace"
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
                float2 uv_tex:TEXCOOR0;
                float2 uv_normal:TEXCOOR1;
                float3 lightDir:TEXCOORD2;
                float3 viewDir:TEXCOORD3;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.uv_tex=TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv_normal=TRANSFORM_TEX(v.texcoord,_BumpMap);

                float3 binormal=normalize(cross(normalize(v.normal), normalize(v.tangent.xyz))) * v.tangent.w;
                //从模型空间变换到切线空间的矩阵
                float3x3 rotation=float3x3(v.tangent.xyz, binormal, v.normal);
               //ObjSpaceLightDir返回模型空间中从该点到光源的光照方向
               o.lightDir=normalize(mul(rotation, ObjSpaceLightDir(v.vertex)));
               //ObjSpaceViewDir返回模型空间中从该点到摄像机的观察方向
               o.viewDir=normalize(mul(rotation,ObjSpaceViewDir(v.vertex)));

               return o;
            }

            fixed4 frag(v2f i):SV_Target{
                fixed4 packedNormal=tex2D(_BumpMap,i.uv_normal);
                fixed3 tangentNormal;
                tangentNormal=UnpackNormal(packedNormal);
                tangentNormal.xy*=_BumpScale;
                tangentNormal.z=sqrt(1.0-saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                fixed3 albedo=tex2D(_MainTex,i.uv_tex).rgb * _Color.rgb;
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse=_LightColor0.rgb * albedo * saturate(dot(i.lightDir,tangentNormal));
                
                float3 halfDir=normalize(i.lightDir+i.viewDir);
                fixed3 specular=_LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir,tangentNormal)),_Gloss);
                
                fixed3 color=ambient+diffuse+specular;
                return fixed4(color,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
