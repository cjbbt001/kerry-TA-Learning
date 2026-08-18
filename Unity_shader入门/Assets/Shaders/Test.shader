// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "CS02/Test"
{
	Properties
	{
		_MainColor("MainColor",Color)=(1,1,1,1)
		_MainTex("Texture",2D) = "white" {}
		_Debug("Debug",Range(0,1)) = 0
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode("CullMode", float) = 2
		_Noise("Noise",2D) = "" {}
		_Cutout("Cutout",Range(-1,1)) = 0.0
		_Speed("Speed",Vector) = (.34, .85, .92, 1)

		}

	SubShader
	{
		Tags{"RenderType"="Opaque" "DisableBatching"="True"}

		Pass
		{
			Cull [_CullMode]
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;

				half2 texcoord0 : TEXCOORD0;
				half2 texcoord1 : TEXCOORD1;
				half2 texcoord2 : TEXCOORD2;

				half4 color : COLOR;
				half3 normal : NORMAL;
				half4 tangent : TANGENT;

				};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float3 pos_local : TEXCOORD2; 
				};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Debug;
			float _Cutout;
			float4 _Speed;
			sampler2D _Noise;
			float4 _Noise_ST;
			float4 _MainColor;

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.texcoord0 * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord0 * _Noise_ST.xy + _Noise_ST.zw;
				o.normal = v.normal;
				o.pos_local = v.vertex.xyz;
				return o;
				}

			half4 frag (v2f i) : SV_Target
			{
				half gradient = tex2D(_MainTex,i.uv.xy + _Time.y * 0.1f * _Speed.xy).r*(1.0-i.uv.y);
				half noise = 1.0-tex2D(_Noise,i.uv.zw+_Time.y*0.1f*_Speed.zw).r;
				clip(gradient-noise-_Cutout);
				return _MainColor;
				}


			ENDCG
		}
		
	}
}
