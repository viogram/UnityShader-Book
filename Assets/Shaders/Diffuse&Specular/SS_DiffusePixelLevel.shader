Shader "Custom/SS_DiffusePixelLevel"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1,1,1,1)
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
            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
            };
            struct v2f{
                float4 pos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                //unity_ObjectToWorld��һ��������/����ʸ����ģ�Ϳռ�任������ռ�ľ���
                o.worldNormal=normalize(mul((float3x3)unity_ObjectToWorld,v.normal));
                
                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                //��û�����
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
                //_WorldSpaceLightPos0��ʾ�����Դ����
                float3 worldLight=normalize(_WorldSpaceLightPos0.xyz);   
                //_LightColor0��Unity���ñ�������ʾ��Դ����ɫ��ǿ�ȣ�saturate(x)�������԰�x��ȡ��[0,1]��Χ��
                fixed3 diffuse=_LightColor0.rgb * _Diffuse * saturate(dot(worldLight,i.worldNormal));
                
                fixed3 color=ambient+diffuse;
                return fixed4(color,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
