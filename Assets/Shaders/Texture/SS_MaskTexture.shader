Shader "Custom/SS_MaskTexture"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _Specular ("Specular", Color) =(1,1,1,1)
        _Gloss ("Gloss", Range(8,256))=20
        _MainTex("Main Tex",2D)="white" {}
        _BumpMap("Normal Map",2D)="bump"{}
        _BumpScale("Bump Scale",float)=1.0
        _SpecularMask("Specular Mask",2D)="white"{}   //高光反射遮罩纹理
        _SpecularScale("Specular Scale",float)=1.0    //遮罩影响度系数
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
            float4 _MainTex_ST;   //主纹理、法线纹理、遮罩纹理同时使用一个纹理属性  
            sampler2D _BumpMap;
            float _BumpScale;
            sampler2D _SpecularMask;
            float _SpecularScale;

            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float4 tangent:TANGENT; 
                float4 texcoord:TEXCOORD0; 
            };
            struct v2f{
                float4 pos:SV_POSITION;
                float2 uv:TEXCOOR1;
                float3 lightDir:TEXCOORD2;
                float3 viewDir:TEXCOORD3;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.uv=v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                float3 binormal=cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
                float3x3 rotation=float3x3(v.tangent.xyz, binormal, v.normal);

                o.lightDir=normalize(mul(rotation, ObjSpaceLightDir(v.vertex)));
                o.viewDir=normalize(mul(rotation,ObjSpaceViewDir(v.vertex)));

               return o;
            }

            fixed4 frag(v2f i):SV_Target{
                fixed4 packedNormal=tex2D(_BumpMap,i.uv);
                fixed3 tangentNormal;
                tangentNormal=UnpackNormal(packedNormal);
                tangentNormal.xy*=_BumpScale;
                tangentNormal.z=sqrt(1.0-saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                fixed3 albedo=tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse=_LightColor0.rgb * albedo * saturate(dot(i.lightDir,tangentNormal));
                
                float3 halfDir=normalize(i.lightDir+i.viewDir);
                //获得遮罩纹素
                fixed specularMask=tex2D(_SpecularMask,i.uv).r * _SpecularScale;
                //计算使用遮罩的高光反射
                fixed3 specular=_LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir,tangentNormal)),_Gloss) * specularMask;
                
                fixed3 color=ambient+diffuse+specular;
                return fixed4(color,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
