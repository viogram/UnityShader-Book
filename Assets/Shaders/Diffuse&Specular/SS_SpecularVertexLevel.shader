Shader "Custom/SS_SpecularVertexLevel"
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
            //该标签定义了该Pass在Unity光照流水线中的角色，有了它才能使用一些内置的光照变量
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Diffuse;   //漫反射材质属性
            fixed4 _Specular;  //高光反射属性
            float _Gloss;  //光泽度
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

                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
                float3 worldNormal=normalize(mul((float3x3)unity_ObjectToWorld,v.normal));
                float3 worldLight=normalize(_WorldSpaceLightPos0.xyz);   
                //计算反射方向,reflect函数的入射方向要求是有光源指向交点处，所以要把世界光取反
                float3 reflectLight=normalize(reflect(-worldLight,worldNormal));
                //计算观察方向
                float3 viewDir=normalize(_WorldSpaceCameraPos.xyz-mul(unity_ObjectToWorld,v.vertex).xyz);

                fixed3 diffuse=_LightColor0.rgb * _Diffuse.rbg * saturate(dot(worldLight,worldNormal));
                fixed3 specular=_LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectLight,viewDir)),_Gloss);
                o.color=ambient+diffuse+specular;

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
