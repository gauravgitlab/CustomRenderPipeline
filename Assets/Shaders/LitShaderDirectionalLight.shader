// this shader works with one directional light only
Shader "Custom/LitShaderDirectionalLight"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}  // Texture
        _Color ("Base Color", Color) = (1, 1, 1, 1)  // Base Color
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
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;   // Vertex normals for lighting
                float2 uv : TEXCOORD0;   // Texture UVs
            };

            struct v2f
            {
                float4 pos : SV_POSITION; // Position in screen space
                float2 uv : TEXCOORD0;   // Pass UVs to fragment shader
                float3 normal : NORMAL;  // Pass normals to fragment shader
                float3 worldPos : TEXCOORD1; // Pass world position
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // Transform normal to world space for lighting
                o.normal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));

                // Calculate world position for view-dependent effects (e.g., specular)
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Sample the texture
                fixed4 texColor = tex2D(_MainTex, i.uv);

                // Ambient lighting
                float3 ambient = 0.2 * _Color.rgb;

                // Get the main directional light's properties
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);  // Directional light direction
                float3 lightColor = _LightColor0.rgb;                  // Directional light color

                // Diffuse lighting (Lambertian reflection)
                float3 normal = normalize(i.normal);
                float diffuseFactor = max(dot(normal, lightDir), 0.0);
                float3 diffuse = diffuseFactor * lightColor;

                // Specular lighting (Blinn-Phong reflection)
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                float3 halfDir = normalize(lightDir + viewDir);
                float specularFactor = pow(max(dot(normal, halfDir), 0.0), 16.0); // Shininess = 16
                float3 specular = specularFactor * lightColor;

                // Combine lighting
                float3 lighting = ambient + diffuse + specular;

                // Apply lighting to the texture color and base color
                fixed4 finalColor = fixed4(texColor.rgb * _Color.rgb * lighting, texColor.a);
                return finalColor;
            }
            ENDCG
        }
    }
}