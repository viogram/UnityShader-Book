// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/DiffuseVertexLevelShader"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1,1,1,1)
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

            fixed4 _Diffuse;   //漫反射材质属性
            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
            };
            struct v2f{
                float4 pos:SV_POSITION;
                fixed3 color:COLOR;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                //获得环境光
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
                //unity_ObjectToWorld是一个将顶点/方向矢量从模型空间变换到世界空间的矩阵
                float3 worldNormal=normalize(mul((float3x3)unity_ObjectToWorld,v.normal));
                //_WorldSpaceLightPos0表示世界光源方向
                float3 worldLight=normalize(_WorldSpaceLightPos0.xyz);   
                //_LightColor0是Unity内置变量，表示光源的颜色和强度；saturate(x)函数可以把x截取在[0,1]范围内
                fixed3 diffuse=_LightColor0.rgb * _Diffuse * saturate(dot(worldLight,worldNormal));
                
                o.color=ambient+diffuse;
                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                return fixed4(i.color,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
