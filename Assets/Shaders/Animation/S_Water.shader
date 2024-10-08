Shader "Unlit/S_Water"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
		_Magnitude ("Distortion Magnitude", Float) = 1  //水流波动幅度
 		_Frequency ("Distortion Frequency", Float) = 1  //水流波动频率
 		_InvWaveLength ("Distortion Inverse Wave Length", Float) = 10  //波长倒数
 		_Speed ("Speed", Float) = 0.5     //水流移动速度
    }
    SubShader
    {
        //关闭批处理，因为批处理会合并所有相关的模型，倒置模型各自的模型空间消失
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True" }
        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			float _Magnitude;
			float _Frequency;
			float _InvWaveLength;
			float _Speed;

            v2f vert (a2v v)
            {
                v2f o;

                float4 offset;
                offset.yzw=float3(0,0,0);
                offset.x=sin(_Frequency*_Time.y+v.vertex.x*_InvWaveLength+v.vertex.y*_InvWaveLength+v.vertex.z*_InvWaveLength)*_Magnitude;
                o.pos = UnityObjectToClipPos(v.vertex+offset);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv+=float2(0,_Time.y*_Speed);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col=tex2D(_MainTex,i.uv);
                col.rgb*=_Color.rgb;

                return col;
            }
            ENDCG
        }
    }
}
