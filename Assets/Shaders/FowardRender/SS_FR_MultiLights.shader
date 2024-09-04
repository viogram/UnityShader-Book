Shader "Custom/SS_FR_MultiLights"
{
    Properties
    {
         _Diffuse ("Diffuse", Color) = (1,1,1,1)
        _Specular ("Specular", Color) =(1,1,1,1)
        _Gloss ("Gloss", Range(8,256))=20
    }
    SubShader
    {

        Pass{
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM

            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Diffuse;   
            fixed4 _Specular; 
            float _Gloss;  

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
                o.worldNormal=normalize(UnityObjectToWorldNormal(v.normal));
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                //�����⣬ֻ����һ��
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
                //_WorldSpaceLightPos0.xyz�Ǹ�Pass����Ĺ�Դ��λ�á�����ƽ�й⣬w����Ϊ0;������Դ��w����Ϊ1
                float3 worldLight=normalize(_WorldSpaceLightPos0.xyz);   
                
                float3 viewDir=normalize(_WorldSpaceCameraPos.xyz-i.worldPos);
                float3 halfDir=normalize(worldLight+viewDir);
                //_LightColor0����ǿ�Ⱥ���ɫ��˺�Ľ��
                fixed3 diffuse=_LightColor0.rgb * _Diffuse.rbg * saturate(dot(worldLight,i.worldNormal));
                fixed3 specular=_LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir,i.worldNormal)),_Gloss);
                //ƽ�й��˥��ʼ��Ϊ1
                fixed atten=1.0;
                fixed3 color=ambient+(diffuse+specular)*atten;
                return fixed4(color,1.0);
            }
            ENDCG
        }

        Pass{
            Tags{"LightMode"="ForwardAdd"}
            Blend One One

            CGPROGRAM

            #pragma multi_compile_fwdadd
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "AutoLight.cginc"  //��ͷ�ļ�������unity_WorldToLight

            fixed4 _Diffuse;   
            fixed4 _Specular; 
            float _Gloss;  

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
                o.worldNormal=normalize(UnityObjectToWorldNormal(v.normal));
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                float3 worldLight;   
                fixed atten;
                //�жϹ�Դ���͡������ǰ�������ƽ�й⣬��ô��Ⱦ����ᶨ��USING_DIRECTIONAL_LIGHT
                #ifdef USING_DIRECTIONAL_LIGHT
                    worldLight=normalize(_WorldSpaceLightPos0.xyz);
                    atten=1;
                #else
                    worldLight=normalize(_WorldSpaceLightPos0.xyz-i.worldPos);
                    //unity_WorldToLight�Ǵ�����ռ䵽��Դ�ռ�ı任���󣬵õ�������������ģ�ķ�Χ����[0,1]������1��˵�����ڹ��շ�Χ��
                    float3 lightCoord=mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
                    //_LightTexture0��˥��������������[0,0]�������Դ�غ�λ�õĵ��˥��ֵ
                    atten=tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                #endif

                float3 viewDir=normalize(_WorldSpaceCameraPos.xyz-i.worldPos);
                float3 halfDir=normalize(worldLight+viewDir);

                fixed3 diffuse=_LightColor0.rgb * _Diffuse.rbg * saturate(dot(worldLight,i.worldNormal));
                fixed3 specular=_LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir,i.worldNormal)),_Gloss);
  
                fixed3 color=(diffuse+specular)*atten;
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
}
