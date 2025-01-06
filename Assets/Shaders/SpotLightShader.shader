Shader "Custom/SpotLightShader"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="UniversalForward" }
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
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            // Spot Light Data
            float4 _SpotLightPosition;
            float4 _SpotLightDirection;
            float4 _SpotLightColor;
            float _SpotLightAngle;
            float _SpotLightRange;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = normalize(UnityObjectToWorldNormal(v.normal));
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            float3 ApplySpotLight(float3 worldPos, float3 normal)
            {
                // Light direction from fragment to light source
                float3 lightDir = normalize(_SpotLightPosition.xyz - worldPos);

                // Angle between light direction and spot light's forward direction
                float angleCos = dot(lightDir, normalize(_SpotLightDirection.xyz));
                
                // Check if within spot light cone
                //if (angleCos > _SpotLightAngle) // inside the cone
                {
                     //return float4(0, 1, 0, 1); // green for inside the cone
                    
                    // Distance attenuation
                    float dist = length(_SpotLightPosition.xyz - worldPos);
                    float attenuation = saturate(1.0 - dist / _SpotLightRange);

                    // Diffuse lighting
                    float diff = max(0, dot(normal, lightDir));

                    // Final light contribution
                    return _SpotLightColor.rgb * diff * attenuation;
                }
                //else
                // {
                //     return float4(1, 0, 0, 1); // Red for outside the cone
                // }

                return 0;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 baseColor = tex2D(_MainTex, i.uv).rgb;

                // Lighting calculation
                float3 spotLight = ApplySpotLight(i.worldPos, normalize(i.normal));

                return float4(baseColor + spotLight, 1.0);
            }
            ENDCG
        }
    }
}
