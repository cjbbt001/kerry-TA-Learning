Shader "Unlit/Scan_code"
{
    Properties
    {
        _MainTex           ("Main Texture", 2D) = "white" {}
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
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" }
        Blend SrcAlpha One
        ZWrite Off
        Cull Back

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv     : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv        : TEXCOORD0;
                float3 normalWS  : TEXCOORD1;
                float3 posWS     : TEXCOORD2;
                float3 pivotWS   : TEXCOORD3;
                float4 vertex    : SV_POSITION;
            };

            // --- Properties ---
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

                // 世界空间法线
                o.normalWS = UnityObjectToWorldNormal(v.normal);

                // 世界空间顶点坐标
                o.posWS = mul(unity_ObjectToWorld, v.vertex).xyz;

                // 轴点世界坐标：模型原点 (0,0,0,1) → 世界空间
                o.pivotWS = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // ========== 1. 边缘光（Rim/Fresnel） ==========

                half3 normalWS = normalize(i.normalWS);
                half3 viewDir  = normalize(_WorldSpaceCameraPos.xyz - i.posWS);

                // NdotV
                half ndotv = saturate(dot(normalWS, viewDir));

                // Fresnel 因子
                half fresnel = 1.0 - ndotv;
                half rimFactor = smoothstep(_RimMin, _RimMax, fresnel);

                // 从 _MainTex 的 R 通道提取高光细节
                half4 mainTex = tex2D(_MainTex, i.uv);
                half emission = pow(mainTex.r, _Texpower);

                // 合并 Fresnel + 细节，限制到 0~1
                half finalRimFactor = saturate(emission + rimFactor);

                // 内外两层颜色插值
                half3 rimColor = lerp(_InnerColor.rgb, _RimColor.rgb * _RimIntensity, finalRimFactor);
                half rimAlpha  = finalRimFactor;

                // ========== 2. 扫光（Scan Flow） ==========

                // 相对 UV：世界坐标 - 轴点坐标（防物体移动漂移）
                float2 relUV = (i.posWS - i.pivotWS).xy;

                // UV 动画：Tiling + Time × Speed
                float2 flowUV = relUV * _Tiling + _Time.y * _Speed;

                // 采样扫光贴图
                half4 scanTex = tex2D(_Scan, flowUV);
                half3 scanColor = scanTex.rgb * _ScanIntensity;
                half  scanAlpha = scanTex.a   * _ScanIntensity;

                // ========== 3. 最终合成 ==========

                half3 finalColor = rimColor + scanColor;
                half  finalAlpha = saturate(rimAlpha + scanAlpha + _InnerAlpha);

                return half4(finalColor, finalAlpha);
            }
            ENDCG
        }
    }
}
