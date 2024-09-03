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
            //�ñ�ǩ�����˸�Pass��Unity������ˮ���еĽ�ɫ������������ʹ��һЩ���õĹ��ձ���
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;   
            fixed4 _Specular;  //�߹ⷴ������
            float _Gloss;  //�����
            sampler2D _MainTex;  //����
            float4 _MainTex_ST;   //�������ԣ�_MainTex_ST.xy�洢��ƽ�̣����ţ���_MainTex_ST.zw�洢��ƫ�ƣ�ƽ�ƣ�

            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float4 texcoord:TEXCOORD0; //��һ����������
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
                //�������������
                fixed3 albedo=tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                float3 worldLight=normalize(_WorldSpaceLightPos0.xyz);   
                //����۲췽��
                float3 viewDir=normalize(_WorldSpaceCameraPos.xyz-i.worldPos);
                //����������
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
