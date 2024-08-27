Shader "Custom/Boundary Conditions"
{
    Properties
    { 
        _uC ("Fluid Texture", 2D) = "" {} // Campo al que aplicar las condiciones de contorno
        _BoundarySize ("Boundary Size", Float) = 0.1 // Tamaño de las "paredes"
        _uTexelSize ("Texel Size", Float) = 0.1 // Tamaño de texel
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc" 

            sampler2D _uC;
            float _BoundarySize;
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
                half4 c = tex2D(_uC, IN.vCoords);
                //float dist = _uTexelSize * _BoundarySize;
                float dist = _BoundarySize;
                c.x = step(dist, IN.vCoords.x) * step(IN.vCoords.x, 1.0 - dist) * c.x; // Si x < dist o x > 1.0 - dist, c.x = 0
                c.y = step(dist, IN.vCoords.y) * step(IN.vCoords.y, 1.0 - dist) * c.y; // Si y < dist o y > 1.0 - dist, c.y = 0
                
                return c;
            }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
