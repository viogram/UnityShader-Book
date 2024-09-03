Shader "Custom/SS_AlphaTest"
{
     Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _Specular ("Specular", Color) =(1,1,1,1)
        _Gloss ("Gloss", Range(8,256))=20
        _MainTex("Main Tex",2D)="white" {}
        _Cutoff("Alpha Cutoff",Range(0,1))=0.5
    }
    SubShader
    {
        Tags{"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
        Pass
        {
            //该标签定义了该Pass在Unity光照流水线中的角色，有了它才能使用一些内置的光照变量
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;   
            fixed4 _Specular;  
            float _Gloss; 
            sampler2D _MainTex;  
            float4 _MainTex_ST;  
            fixed _Cutoff;

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
                SHADOW_COORDS(4)
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
                fixed4 texColor=tex2D(_MainTex,i.uv);
                //透明度测试，void clip(x),如果参数的任何一个分量是负数，那么片元着色器会舍弃输出颜色
                clip(texColor.a-_Cutoff);

                fixed3 albedo=texColor.rgb * _Color.rgb;
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                float3 worldLight=normalize(UnityWorldSpaceLightDir(i.worldPos));   

                float3 viewDir=normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 halfDir=normalize(worldLight+viewDir);

                fixed3 diffuse=_LightColor0.rgb * albedo * saturate(dot(worldLight,i.worldNormal));
                fixed3 specular=_LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir,i.worldNormal)),_Gloss);

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos)
                fixed3 color=ambient+(diffuse+specular)*atten;
                return fixed4(color,1.0);
            }

            ENDCG
        }
    }
    FallBack "Transparent/Cutout/VertexLit"
}
