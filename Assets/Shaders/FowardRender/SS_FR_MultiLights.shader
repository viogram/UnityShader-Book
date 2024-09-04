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
                //环境光，只计算一次
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
                //_WorldSpaceLightPos0.xyz是该Pass处理的光源的位置。对于平行光，w分量为0;其他光源，w分量为1
                float3 worldLight=normalize(_WorldSpaceLightPos0.xyz);   
                
                float3 viewDir=normalize(_WorldSpaceCameraPos.xyz-i.worldPos);
                float3 halfDir=normalize(worldLight+viewDir);
                //_LightColor0已是强度和颜色相乘后的结果
                fixed3 diffuse=_LightColor0.rgb * _Diffuse.rbg * saturate(dot(worldLight,i.worldNormal));
                fixed3 specular=_LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir,i.worldNormal)),_Gloss);
                //平行光的衰减始终为1
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
            #include "AutoLight.cginc"  //该头文件定义了unity_WorldToLight

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
                //判断光源类型。如果当前处理的是平行光，那么渲染引擎会定义USING_DIRECTIONAL_LIGHT
                #ifdef USING_DIRECTIONAL_LIGHT
                    worldLight=normalize(_WorldSpaceLightPos0.xyz);
                    atten=1;
                #else
                    worldLight=normalize(_WorldSpaceLightPos0.xyz-i.worldPos);
                    //unity_WorldToLight是从世界空间到光源空间的变换矩阵，得到的坐标向量的模的范围会在[0,1]，超出1则说明不在光照范围内
                    float3 lightCoord=mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
                    //_LightTexture0是衰减纹理。纹理坐标[0,0]表面与光源重合位置的点的衰减值
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
