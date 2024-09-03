Shader "Custom/SS_Dissolve"
{
    Properties
    {
        _BurnAmount ("Burn Amount",Range(0.0,1.0))=0.0   //消融程度
        _LineWidth ("Line Width", Range(0.0,0.2))=0.1   //烧焦效果的线宽
        _MainTex ("Albedo (RGB)", 2D) = "white" {}   
        _BumpMap ("Bump Map", 2D)="bump"{}
        _BurnFirstColor ("Burn First Color",Color)=(1,0,0,1)   //烧焦效果的里边界颜色
        _BurnSecondColor ("Burn Second Colo",Color)=(1,0,0,1)  //烧焦效果的外边界颜色
        _BurnMap ("Burn Map",2D)="white"{}   //噪声纹理
    }
    SubShader
    {
        Pass{
            Tags{"LightMode"="ForwardBase"}
            //关闭面片剔除，因为消融会使模型内部裸露，只渲染正面会得到错误结果
            Cull Off
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed _BurnAmount;
            fixed _LineWidth;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            fixed4 _BurnFirstColor;
            fixed4 _BurnSecondColor;
            sampler2D _BurnMap;
            float4 _BurnMap_ST;

            struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
			}; 

            struct v2f{
                float4 pos:SV_POSITION;
                float2 uvMainTex:TEXCOORD0;
                float2 uvBumpMap:TEXCOORD1;
                float2 uvBurnMap:TEXCOORD2;
                float3 worldPos:TEXCOORD3;
                float3 lightDir:TEXCOORD4;
                SHADOW_COORDS(5)
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.uvMainTex=TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uvBumpMap=TRANSFORM_TEX(v.texcoord,_BumpMap);
                o.uvBurnMap=TRANSFORM_TEX(v.texcoord,_BurnMap);
                
                TANGENT_SPACE_ROTATION;
                o.lightDir=mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                TRANSFER_SHADOW(o);
                return o;
            }
            
            fixed4 frag(v2f i):SV_Target{
                fixed3 burn=tex2D(_BurnMap,i.uvBurnMap).rgb;
                clip(burn.r-_BurnAmount);
                fixed3 tangentLightDir=normalize(i.lightDir);
                fixed3 tangentNormal=UnpackNormal(tex2D(_BumpMap,i.uvBumpMap));

                fixed3 albedo=tex2D(_MainTex,i.uvMainTex).rgb;
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
                fixed3 diffuse=_LightColor0.rgb*albedo*max(0,dot(tangentLightDir,tangentNormal));
                
                fixed t=1-smoothstep(0.0,_LineWidth,burn.r-_BurnAmount);
                fixed3 burnColor=lerp(_BurnFirstColor,_BurnSecondColor,t);
                burnColor=pow(burnColor,5);

                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                fixed3 finalColor=lerp(ambient+diffuse*atten,burnColor,t*step(0.0001,_BurnAmount));
                return fixed4(finalColor,1);
            }

            ENDCG
        }

        Pass {
			Tags { "LightMode" = "ShadowCaster" }
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#include "UnityCG.cginc"
			
			fixed _BurnAmount;
			sampler2D _BurnMap;
			float4 _BurnMap_ST;
			
			struct v2f {
				V2F_SHADOW_CASTER;
				float2 uvBurnMap : TEXCOORD1;
			};
			
			v2f vert(appdata_base v) {
				v2f o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);	
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;
				clip(burn.r - _BurnAmount);
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
    }
    FallBack "Diffuse"
}
