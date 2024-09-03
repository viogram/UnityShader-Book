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
                float3 worldNormal:TEXCOORD0;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                //unity_ObjectToWorld是一个将顶点/方向矢量从模型空间变换到世界空间的矩阵
                o.worldNormal=normalize(mul((float3x3)unity_ObjectToWorld,v.normal));
                
                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                //获得环境光
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
                //_WorldSpaceLightPos0表示世界光源方向
                float3 worldLight=normalize(_WorldSpaceLightPos0.xyz);   
                //_LightColor0是Unity内置变量，表示光源的颜色和强度；saturate(x)函数可以把x截取在[0,1]范围内
                fixed3 diffuse=_LightColor0.rgb * _Diffuse * saturate(dot(worldLight,i.worldNormal));
                
                fixed3 color=ambient+diffuse;
                return fixed4(color,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
