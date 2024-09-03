Shader "Custom/SS_AlphaBlend"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _Specular ("Specular", Color) =(1,1,1,1)
        _Gloss ("Gloss", Range(8,256))=20
        _MainTex("Main Tex",2D)="white" {}
        _AlphaScale("Alpha Scale", Range(0,1))=1
    }
    SubShader
    {
        Tags{"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
       
        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;   
            fixed4 _Specular;  
            float _Gloss; 
            sampler2D _MainTex;  
            float4 _MainTex_ST;  
            fixed _AlphaScale;

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
                o.worldNormal=normalize(UnityObjectToWorldNormal(v.normal));
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv=TRANSFORM_TEX(v.texcoord,_MainTex); 

                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                fixed4 texColor=tex2D(_MainTex,i.uv);
                fixed3 albedo=texColor.rgb * _Color.rgb;
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                float3 worldLight=normalize(UnityWorldSpaceLightDir(i.worldPos));   

                float3 viewDir=normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 halfDir=normalize(worldLight+viewDir);

                fixed3 diffuse=_LightColor0.rgb * albedo * saturate(dot(worldLight,i.worldNormal));
                fixed3 specular=_LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir,i.worldNormal)),_Gloss);
                fixed3 color=ambient+diffuse+specular;
                return fixed4(color, texColor.a*_AlphaScale);
            }

            ENDCG
        }
    }
    FallBack "Transparent/VertexLit"
}
