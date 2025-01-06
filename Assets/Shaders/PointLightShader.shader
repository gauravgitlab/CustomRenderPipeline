Shader "Custom/PointLightShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="UniversalForward" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            // Point Light Parameters
            float4 _PointLightPosition; // xyz = position, w = unused
            float4 _PointLightColor;    // xyz = color, w = unused
            float _PointLightRange;     // Light range

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 baseColor = tex2D(_MainTex, i.uv);

                // light direction and distance
                float3 lightDir = _PointLightPosition.xyz - i.worldPos;
                float distance = length(lightDir);
                lightDir = normalize(lightDir);

                // attenuation ( based on distance and range )
                float attenuation = saturate(1.0 - (distance / _PointLightRange));

                // Lambertion diffuse lighting
                float NdotL = saturate(dot(float3(0, 1, 0), lightDir)); // Simple normal (up direction)
                float3 lighting = _PointLightColor.rgb * NdotL * attenuation;

                return float4(baseColor.rgb * lighting, baseColor.a);
            }
            ENDCG
        }
    }
}
