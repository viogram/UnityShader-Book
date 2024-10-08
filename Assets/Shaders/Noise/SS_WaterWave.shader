Shader "Custom/SS_WaterWave"
{
    Properties
    {
        _Color ("Color", Color)=(0,0.15,0.115,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _WaveMap ("Wave Map", 2D) = "bump" {}
        _CubeMap ("Cube Map", Cube) = "_Skybox" {}
        _WaveXSpeed ("Wave Horizontal Speed",Range(-0.1,0.1))=0.01
        _WaveYSpeed ("Wave Vertical Speed",Range(-0.1,0.1))=0.01
        _Distortion("Distortion", Range(0,100))=10  
    }
    SubShader
    {
        //设置Queue来确保水面在所有不透明物体之后渲染，设置RenderType来确保使用着色器替换时的正确渲染
        Tags{"Queue"="Transparent" "RenderType"="Opaque"}
        //抓取屏幕图像
        GrabPass{"_RefractionTex"}

        Pass{
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM

            #include "UnityCG.cginc"
			#include "Lighting.cginc"
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _WaveMap;
			float4 _WaveMap_ST;
			samplerCUBE _CubeMap;
			fixed _WaveXSpeed;
			fixed _WaveYSpeed;
			float _Distortion;	
			sampler2D _RefractionTex;
			float4 _RefractionTex_TexelSize;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT; 
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float2 uv_tex : TEXCOORD1;
                float2 uv_normal : TEXCOORD2;
				float4 TtoW0 : TEXCOORD3;  
				float4 TtoW1 : TEXCOORD4;  
				float4 TtoW2 : TEXCOORD5; 
			};

			v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                //获取屏幕图像的采样坐标，坐标不一定是归一化的
                o.scrPos=ComputeGrabScreenPos(o.pos);
                o.uv_tex=TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv_normal=TRANSFORM_TEX(v.texcoord,_WaveMap);

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
                float2 speed=_Time.y*float2(_WaveXSpeed,_WaveYSpeed);
                fixed3 bump1=UnpackNormal(tex2D(_WaveMap,i.uv_normal+speed)).rgb;
                fixed3 bump2=UnpackNormal(tex2D(_WaveMap,i.uv_normal-speed)).rgb;
                fixed3 bump=normalize(bump1+bump2);
                //计算在切线空间下的偏移来模拟折射
                float2 offset=bump.xy*_Distortion*_RefractionTex_TexelSize.xy;
                i.scrPos.xy+=offset;
                //对scrPos作透视除法得到真正的屏幕坐标
                fixed3 refrColor=tex2D(_RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;
                bump=normalize(fixed3(dot(i.TtoW0.xyz, bump), 
                                               dot(i.TtoW1.xyz, bump), 
                                               dot(i.TtoW2.xyz, bump)));
                
                float3 worldPos=float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                float3 viewDir=normalize(UnityWorldSpaceViewDir(worldPos));
                
                float3 reflDir=reflect(-viewDir,bump);
                fixed4 texColor=tex2D(_MainTex,i.uv_tex);
                fixed3 reflColor=texCUBE(_CubeMap,reflDir).rgb * texColor.rgb * _Color.rgb;

                fixed fresnel=pow(1-saturate(dot(viewDir,bump)),4);
                return fixed4(lerp(reflColor,refrColor,fresnel),1);
            }
            ENDCG
        }

    }
    FallBack "Diffuse"
}
