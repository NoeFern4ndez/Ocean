Shader "Custom/Gradient Substraction"
{
    Properties
    { 
        _uW ("Velocity Texture", 2D) = "" {} // Campo de velocidades
        _uP ("Pressure Texture", 2D) = "" {} // Campo de presiones
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
            sampler2D _uP;
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
                half pL = tex2D(_uP, IN.vLeft).x; // Se corresponde con p_{i-1,j}^{k}.x (la vecina de la izquierda)
                half pR = tex2D(_uP, IN.vRight).x; // Se corresponde con p_{i+1,j}^{k}.x (la vecina de la derecha)
                half pT = tex2D(_uP, IN.vTop).y; // Se corresponde con p_{i,j+1}^{k}.y (la vecina de arriba)
                half pB = tex2D(_uP, IN.vBottom).y; // Se corresponde con p_{i,j-1}^{k}.y (la vecina de abajo)

                // ∇p = (p_{i+1,j} - p_{i-1,j}, p_{i,j+1} - p_{i,j-1}) / 2
                half2 gradient = half2(pR - pL, pT - pB) / (2 * _uTexelSize) ;
                half4 color = tex2D(_uW, IN.vCoords);
                color.xy -= gradient;

                return color;
            }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
