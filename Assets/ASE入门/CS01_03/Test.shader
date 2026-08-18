Shader "Unlit/Test"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Texpower          ("Texture Power", Float) = 5

        // Edge light (Rim)
        _RimMin            ("Rim Min", Range(-1, 1)) = 0
        _RimMax            ("Rim Max", Range(0, 2)) = 1
        _RimColor          ("Rim Color", Color) = (1, 1, 1, 1)
        _RimIntensity      ("Rim Intensity", Float) = 1
        _InnerColor        ("Inner Color", Color) = (0, 0, 0, 0)
        _InnerAlpha        ("Inner Alpha", Range(0, 1)) = 0.5

        // Scan flow
        _Scan              ("Scan Texture", 2D) = "white" {}
        _ScanIntensity     ("Scan Intensity", Float) = 0.5
        _Tiling            ("Tiling", Vector) = (0, 1, 0, 0)
        _Speed             ("Speed", Vector) = (0, 1, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
        LOD 100

        // Depth pre-pass
        Pass
        {
            ZWrite On
            ColorMask 0

            CGPROGRAM
            #pragma vertex vert_depth
            #pragma fragment frag_depth
            #include "UnityCG.cginc"

            struct appdata_depth
            {
                float4 vertex : POSITION;
            };

            struct v2f_depth
            {
                float4 vertex : SV_POSITION;
            };

            v2f_depth vert_depth (appdata_depth v)
            {
                v2f_depth o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag_depth (v2f_depth i) : SV_Target
            {
                return 0;
            }
            ENDCG
        }

        // Main pass
        Pass
        {
            ZWrite Off
            Blend SrcAlpha One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normalWorld : TEXCOORD1;
                float3 posWorld : TEXCOORD2;
                float3 pivotWorld : TEXCOORD3;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Texpower;

            float _RimMin;
            float _RimMax;
            float4 _RimColor;
            float _RimIntensity;
            float4 _InnerColor;
            float _InnerAlpha;

            sampler2D _Scan;
            float _ScanIntensity;
            float2 _Tiling;
            float2 _Speed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normalWorld = normalize(mul(float4(v.normal,0),unity_WorldToObject)).xyz;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.pivotWorld = mul(unity_ObjectToWorld,float4(0,0,0,1)).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half3 normalWorld = normalize(i.normalWorld);
                half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWorld);

                half NdotV = saturate(dot(normalWorld, viewDir));
                half fresnel = 1 - NdotV;
                fresnel = smoothstep(_RimMin, _RimMax, fresnel);
                half emiss = tex2D(_MainTex,i.uv).r;
                emiss = pow(emiss,_Texpower);

                half final_fresnel = saturate(emiss + fresnel);
                half final_rimalpha = final_fresnel;

                half3 final_rimcolor = lerp(_InnerColor.rgb, _RimColor.rgb * _RimIntensity, final_fresnel);
                half2 uv_flow = (i.posWorld - i.pivotWorld).xy *_Tiling +_Speed*_Time.y;
                half4 flow_rgba = tex2D(_Scan,uv_flow)*_ScanIntensity;

                half3 final_color = flow_rgba.xyz + final_rimcolor;
                half final_alpha = final_rimalpha + flow_rgba.a + _InnerAlpha;
                return float4(final_color,final_alpha);

                
            }
            ENDCG
        }
    }
}
