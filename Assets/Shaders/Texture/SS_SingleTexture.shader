Shader "Custom/SS_SingleTexture"
{
   Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _Specular ("Specular", Color) =(1,1,1,1)
        _Gloss ("Gloss", Range(8,256))=20
        _MainTex("Main Tex",2D)="white" {}
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
            fixed4 _Specular;  //高光反射属性
            float _Gloss;  //光泽度
            sampler2D _MainTex;  //纹理
            float4 _MainTex_ST;   //纹理属性，_MainTex_ST.xy存储了平铺（缩放），_MainTex_ST.zw存储了偏移（平移）

            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float4 texcoord:TEXCOORD0; //第一组纹理坐标
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
                o.uv=v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                //o.uv=TRANSFORM_TEX(v.texcoord,_MainTex); 

                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                //漫反射材质属性
                fixed3 albedo=tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                float3 worldLight=normalize(_WorldSpaceLightPos0.xyz);   
                //计算观察方向
                float3 viewDir=normalize(_WorldSpaceCameraPos.xyz-i.worldPos);
                //计算半程向量
                float3 halfDir=normalize(worldLight+viewDir);

                fixed3 diffuse=_LightColor0.rgb * albedo * saturate(dot(worldLight,i.worldNormal));
                fixed3 specular=_LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir,i.worldNormal)),_Gloss);
                fixed3 color=ambient+diffuse+specular;
                return fixed4(color,1.0);
            }

            ENDCG
        }
    }
    FallBack "Specular"
}
