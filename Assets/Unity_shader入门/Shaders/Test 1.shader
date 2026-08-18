// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "CS02/Test1"
{
	Properties
	{
		_MainColor("MainColor",Color)=(1,1,1,1)
		_MainTex("Texture",2D) = "white" {}
		_Speed("Speed",Vector) = (.34, .85, .92, 1)
		_Emiss("Emiss",Float) = 1.0
		}

	SubShader
	{
		Tags{"Queue"="Transparent"}

		Pass {
			Cull Off 
			ZWrite On 
			ColorMask 0
			CGPROGRAM
			float4 _Color;
			#pragma vertex vert 
			#pragma fragment frag

			float4 vert(float4 vertexPos : POSITION) : SV_POSITION
			{
				return UnityObjectToClipPos(vertexPos);
			}

			float4 frag(void) : COLOR
			{
				return _Color;
			}
			ENDCG
		}

		Pass
		{
			ZWrite Off
			Blend SrcAlpha One
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				half2 texcoord0 : TEXCOORD0;
				half3 normal : NORMAL;

				};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float3 normal_world : TEXCOORD1;
				float3 pos_world : TEXCOORD2; 
				};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Speed;
			float4 _MainColor;
			float _Emiss;

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.texcoord0 * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 pos_world = mul(unity_ObjectToWorld, v.vertex);
				o.pos_world = pos_world.xyz;
				o.normal_world = normalize(mul(float4 (v.normal,0),unity_WorldToObject).xyz);
				return o;
				}

			half4 frag (v2f i) : SV_Target
			{
				float3 normal_world = normalize(i.normal_world);
				float3 view_world = normalize(_WorldSpaceCameraPos.xyz-i.pos_world);
				float NdotV = saturate(dot(normal_world,view_world));
				float alpha = saturate(_MainColor.a / NdotV);
				return float4(_MainColor.xyz * _Emiss,alpha);
				}


			ENDCG
		}
		
	}
}
