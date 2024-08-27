Shader "Custom/Jacobi"
{
    Properties
    { 
        _uX ("Velocity Texture", 2D) = "" {} // Ax = b 
        _uB ("Diffused Texture", 2D) = "" {} // Ax = b
        _uAlpha ("Diffusion factor", Float) = 1.0 // α
        _uBeta ("Correction factor", Float) = 4.0 // β
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

            sampler2D _uX;
            sampler2D _uB;
            float _uAlpha;
            float _uBeta;
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
                half3 xL = tex2D(_uX, IN.vLeft).rgb; // Se corresponde con x_{i-1,j}^{k} (la vecina de la izquierda)
                half3 xR = tex2D(_uX, IN.vRight).rgb; // Se corresponde con x_{i+1,j}^{k} (la vecina de la derecha)
                half3 xT = tex2D(_uX, IN.vTop).rgb; // Se corresponde con x_{i,j+1}^{k} (la vecina de arriba)
                half3 xB = tex2D(_uX, IN.vBottom).rgb; // Se corresponde con x_{i,j-1}^{k} (la vecina de abajo)
                half3 bC = tex2D(_uB, IN.vCoords).rgb; // Se corresponde con b_{i,j}^{k} (el valor de b en la posición actual)

                // x_{i,j}^{k+1} = (x_{i-1,j}^{k} + x_{i+1,j}^{k} + x_{i,j-1}^{k} + x_{i,j+1}^{k} + αb_{i,j}) / β
                half3 jacobi = (xL + xR + xB + xT + (_uAlpha * bC)) / _uBeta; 
                
                return half4(jacobi, 1.0);
            }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
