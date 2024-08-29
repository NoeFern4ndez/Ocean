Shader "Custom/Render"
{
    Properties
    { 
        _uC ("Fluid Texture", 2D) = "" {} // Campo a visualizar
        _colorFactor ("Color Factor", Float) = 1.0 // Multiplicador de color
        _uTexelSize ("Texel Size", Float) = 0.1 // Tamaño de texel
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        
        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc" 

            sampler2D _uC;
            float _colorFactor;
            float _uTexelSize;

            struct MeshData
            {
                float4 aPosition : POSITION;
                float3 aNormal : NORMAL;
                float2 aTexCoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vPosition : SV_POSITION;
                float3 vNormal : TEXCOORD1;
                float2 vCoords : TEXCOORD0;
                float2 vLeft : TEXCOORD2;
                float2 vRight : TEXCOORD3;
                float2 vTop : TEXCOORD4;
                float2 vBottom : TEXCOORD5;
            };

            v2f vert(MeshData IN)
            {
                v2f OUT;
                
                OUT.vCoords = IN.aTexCoord;
                OUT.vLeft = IN.aTexCoord - float2(_uTexelSize, 0.0);
                OUT.vRight = IN.aTexCoord + float2(_uTexelSize, 0.0);
                OUT.vTop = IN.aTexCoord + float2(0.0, _uTexelSize);
                OUT.vBottom = IN.aTexCoord - float2(0.0, _uTexelSize);
                
                OUT.vNormal = IN.aNormal;
                OUT.vPosition = UnityObjectToClipPos(IN.aPosition);

                return OUT;
            }

            half4 frag(v2f IN) : SV_Target
            {
                // Sample the color from the texture
                half4 color = tex2D(_uC, IN.vCoords);
                
                // Calculate smooth alpha based on color intensity
                float alpha = smoothstep(0.0, 0.2, length(color.rgb));
                color.a *= alpha;
                
                // Calculate distance from texture center to create edge fade
                float2 center = float2(0.5, 0.5); 
                float distance = length(IN.vCoords - center);
                float edgeFade = smoothstep(0.35, 0.55, distance); 
                
                color.a *= (1.0 - edgeFade);
                color.rgb *= _colorFactor;
                
                return color;
            }

            ENDHLSL
        }
    }
    FallBack "Transparent/Diffuse/VertexLit"
}

