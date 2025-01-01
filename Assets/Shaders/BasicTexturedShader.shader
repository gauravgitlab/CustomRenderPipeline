Shader "Custom/BasicTexturedShader"
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
                float2 uv : TEXCOORD0; // Add UVs for texture coordinates
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0; // Pass UVs to fragment shader
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;      // Unity provides this for tiling (x, y) and offset (z, w)

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex); 
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Sample texture using UVs
                return tex2D(_MainTex, i.uv);
            }
            ENDCG
        }
    }
}