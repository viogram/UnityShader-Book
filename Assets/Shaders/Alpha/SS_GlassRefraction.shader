Shader "Custom/SS_GlassRefraction"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
        _BumpMap ("Bump Map", 2D) = "bump" {}
        _CubeMap ("Cube Map", Cube) = "_Skybox" {}
        _Distortion("Distortion", Range(0,100))=10  //扭曲度
        _RefractionAmount("Refract Amout", Range(0,1))=1  //折射率，1只含折射，0只含反射
    }
    SubShader
    {
        Tags{"Queue"="Transparent" "RenderType"="Opaque"}
        
        //字符串的名称决定了抓取得到的屏幕图像会放入哪个纹理中
        GrabPass{"_RefractionTex"}

        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            //#include "Lighting.cginc"
            //#include "AutoLight.cginc"
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            samplerCUBE _CubeMap;
            float _Distortion;
            float _RefractionAmount;
            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize;

             struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float4 tangent:TANGENT; //注意切线是float4类型，因为需要w方向来确定副切线的方向
                float4 texcoord:TEXCOORD0; 
            };
            struct v2f{
                float4 pos:SV_POSITION;
                float4 scrPos:TEXCOORD0;
                float2 uv_tex:TEXCOORD1;
                float2 uv_normal:TEXCOORD2;
                float4 TtoW0:TEXCOORD3;
                float4 TtoW1:TEXCOORD4;
                float4 TtoW2:TEXCOORD5;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                //获取屏幕图像的采样坐标，坐标不一定是归一化的
                o.scrPos=ComputeGrabScreenPos(o.pos);
                o.uv_tex=TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv_normal=TRANSFORM_TEX(v.texcoord,_BumpMap);

                float3 worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                float3 worldNormal=UnityObjectToWorldNormal(v.normal);
                float3 worldTangent=UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldBinormal=cross(worldNormal, worldTangent) * v.tangent.w;

                o.TtoW0=float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1=float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2=float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

               return o;
            }

            fixed4 frag(v2f i):SV_Target{
                fixed4 packedNormal=tex2D(_BumpMap,i.uv_normal);
                fixed3 tangentNormal;
                tangentNormal=UnpackNormal(packedNormal);
                //计算在切线空间下的偏移来模拟折射
                float2 offset=tangentNormal.xy*_Distortion*_RefractionTex_TexelSize.xy;
                i.scrPos.xy+=offset;
                //对scrPos作透视除法得到真正的屏幕坐标
                fixed3 refrColor=tex2D(_RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;
                tangentNormal=normalize(fixed3(dot(i.TtoW0.xyz, tangentNormal), 
                                               dot(i.TtoW1.xyz, tangentNormal), 
                                               dot(i.TtoW2.xyz, tangentNormal)));
                
                float3 worldPos=float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                float3 viewDir=UnityWorldSpaceViewDir(worldPos);
                float3 reflDir=reflect(-viewDir,tangentNormal);
                fixed4 texColor=tex2D(_MainTex,i.uv_tex);
                fixed3 reflColor=texCUBE(_CubeMap,reflDir).rgb * texColor.rgb;
                
                return fixed4(lerp(reflColor,refrColor,_RefractionAmount),1);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
