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
            //�ñ�ǩ�����˸�Pass��Unity������ˮ���еĽ�ɫ������������ʹ��һЩ���õĹ��ձ���
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
                float4 tangent:TANGENT; //ע��������float4���ͣ���Ϊ��Ҫw������ȷ�������ߵķ���
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
                //��ģ�Ϳռ�任�����߿ռ�ľ���
                float3x3 rotation=float3x3(v.tangent.xyz, binormal, v.normal);
               //ObjSpaceLightDir����ģ�Ϳռ��дӸõ㵽��Դ�Ĺ��շ���
               o.lightDir=normalize(mul(rotation, ObjSpaceLightDir(v.vertex)));
               //ObjSpaceViewDir����ģ�Ϳռ��дӸõ㵽������Ĺ۲췽��
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
