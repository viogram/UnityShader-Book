// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/S_Billboard"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_VerticalBillboarding ("Vertical Restraints", Range(0, 1)) = 1   //约束垂直方向的程度
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}

        Pass
        {
           Tags { "LightMode"="ForwardBase" }
			
		    ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed _VerticalBillboarding;
			
            struct a2v {
	            float4 vertex : POSITION;
	            float4 texcoord : TEXCOORD0;
            };
			
            struct v2f {
	            float4 pos : SV_POSITION;
	            float2 uv : TEXCOORD0;
            };

            v2f vert (a2v v)
            {
                float3 center=float3(0,0,0);
                float3 viewer=mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz;

                float3 normalDir=viewer-center;
                normalDir.y*=_VerticalBillboarding;
                normalDir=normalize(normalDir);
                float3 upDir=abs(normalDir.y)>0.999 ? float3(0,0,1):float3(0,1,0);
                float3 rightDir=normalize(cross(upDir,normalDir));
                upDir=normalize(cross(normalDir,rightDir));
                float3 centerOffs=v.vertex.xyz-center;
                float3 localPos=center+rightDir*centerOffs.x+upDir*centerOffs.y+normalDir*centerOffs.z;

                v2f o;
                o.pos = UnityObjectToClipPos(fixed4(localPos,1));
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                col.rgb*=_Color;

                return col;
            }
            ENDCG
        }
    }
}
