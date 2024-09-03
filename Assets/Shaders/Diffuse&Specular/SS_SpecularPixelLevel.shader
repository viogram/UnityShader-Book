Shader "Custom/SS_SpecularPixelLevel"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1,1,1,1)
        _Specular ("Specular", Color) =(1,1,1,1)
        _Gloss ("Gloss", Range(8,256))=20
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

            fixed4 _Diffuse;   //�������������
            fixed4 _Specular;  //�߹ⷴ������
            float _Gloss;  //�����
            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
            };
            struct v2f{
                float4 pos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.worldNormal=normalize(mul((float3x3)unity_ObjectToWorld,v.normal));
                o.worldPos=normalize(mul(unity_ObjectToWorld,v.vertex).xyz);
                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
                float3 worldLight=normalize(_WorldSpaceLightPos0.xyz);   
                
                //����۲췽��
                float3 viewDir=normalize(_WorldSpaceCameraPos.xyz-i.worldPos);
                //����������
                float3 halfDir=normalize(worldLight+viewDir);

                fixed3 diffuse=_LightColor0.rgb * _Diffuse.rbg * saturate(dot(worldLight,i.worldNormal));
                fixed3 specular=_LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir,i.worldNormal)),_Gloss);
                fixed3 color=ambient+diffuse+specular;
                return fixed4(color,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
