Shader "Custom/Gen Vorticity"
{
    Properties
    { 
        _uW ("Velocity Texture", 2D) = "" {} // Campo de velocidades
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

            sampler2D _uW;
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
                half wL = tex2D(_uW, IN.vLeft).x; // Se corresponde con w_{i-1,j}^{k}.x (la vecina de la izquierda)
                half wR = tex2D(_uW, IN.vRight).x; // Se corresponde con w_{i+1,j}^{k}.x (la vecina de la derecha)
                half wT = tex2D(_uW, IN.vTop).y; // Se corresponde con w_{i,j+1}^{k}.y (la vecina de arriba)
                half wB = tex2D(_uW, IN.vBottom).y; // Se corresponde con w_{i,j-1}^{k}.y (la vecina de abajo)

                // vorticity = ∇.w = (v_{i+1,j} - v_{i-1,j} - v_{i,j+1} + v_{i,j-1}) / 2 
                float vorticity = (wT - wB - (wR - wL)) / (2.0 * _uTexelSize);
            
                return half4(vorticity, 0.0, 0.0, 1.0);
            }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
