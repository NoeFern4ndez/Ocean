Shader "Custom/Vorticity"
{
    Properties
    { 
        _uV ("Velocity Texture", 2D) = "" {} // Campo de velocidades
        _uVorticity ("Vorticity Texture", 2D) = "" {} // Campo de vorticidad
        _uTimeStep ("Time Step", Float) = 0.1 // Δt
        _uVFactor ("Vorticity Factor", Float) = 0.1 // Factor de vorticidad
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

            sampler2D _uV;
            sampler2D _uVorticity;
            float _uTimeStep;
            float _uVFactor;
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
                half vL = tex2D(_uVorticity, IN.vLeft).x; // Se corresponde con w_{i-1,j}^{k}.x (la vecina de la izquierda)
                half vR = tex2D(_uVorticity, IN.vRight).x; // Se corresponde con w_{i+1,j}^{k}.x (la vecina de la derecha)
                half vT = tex2D(_uVorticity, IN.vTop).y; // Se corresponde con w_{i,j+1}^{k}.y (la vecina de arriba)
                half vB = tex2D(_uVorticity, IN.vBottom).y; // Se corresponde con w_{i,j-1}^{k}.y (la vecina de abajo)
                half vC = tex2D(_uVorticity, IN.vCoords).x; // Se corresponde con b_{i,j} (el centro de la celda actual)
                half3 velocity = tex2D(_uV, IN.vCoords).xyz;

                half2 vorticity = half2(abs(vT) - abs(vB), abs(vR) - abs(vL)) / (2.0 * _uTexelSize); // vorticity =  η = ∇.|ω| = (|ω_{i,j+1}| - |ω_{i,j-1}|, |ω_{i+1,j}| - |ω_{i-1,j}|) / 2
                vorticity /= length(vorticity) + 0.0001; //  Ψ = η / ||η||

                // f_{vc} = ε(v_{i,j} * Ψ) * b_{i,j}
                vorticity *= _uVFactor * vC; // ω = εvΨb
                vorticity.y *= 1.0;  // ω = εvΨb
                velocity.xy += _uTimeStep * vorticity; // v^{n+1} = v^{n} + Δt * ω

                return half4(velocity, 1.0);
            }
            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
