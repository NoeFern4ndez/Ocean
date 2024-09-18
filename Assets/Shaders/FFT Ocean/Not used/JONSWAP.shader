Shader "Custom/JONSWAP"
{
    Properties
    { 
        _gamma("Gamma", Float) = 3.3
        _alpha("Alpha", Float) = 0.0081
        _g("Gravity", Float) = 9.81
        _wp("Peak frequency", Float) = 1
        _seed("Seed", Float) = 1
        _depth("Water Depth", Float) = 200
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #define PI 3.14159265359

            #include "UnityCG.cginc"

            float _gamma;
            float _alpha;
            float _g;
            float _wp;
            float _seed;
            float _depth;

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            // Generación de un número aleatorio gaussiano basado en una semilla
            float2 generateGaussianRandomNumber(float seed)
            {
                float u1 = max(0.0001, frac(sin(seed) * 43758.5453)); // Evitar valores muy cercanos a 0
                float u2 = frac(sin(seed + 1.0) * 43758.5453);
                float R = sqrt(-2.0 * log(u1));
                float theta = 2.0 * PI * u2;
                return float2(R * cos(theta), R * sin(theta));
            }


            // Corrección TMA para la profundidad del agua
            float TMACorrection(float omega, float g, float depth)
            {
                float omegaH = omega * sqrt(depth / g);
                if (omegaH <= 1)
                    return 0.5 * omegaH * omegaH;
                if (omegaH < 2)
                    return 1.0 - 0.5 * (2.0 - omegaH) * (2.0 - omegaH);
                return 1;
            }

            // Función espectral JONSWAP
            float JONSWAP(float w, float alpha, float gamma, float g, float wp, float depth)
            {
                float sigma = w <= wp ? 0.07 : 0.09;
                float r = exp(-(w - wp) * (w - wp) / (2 * sigma * sigma * wp * wp));

                float S = alpha * g * g / pow(w, 5) * exp(-1.25 * pow(wp / w, 4)) * pow(gamma, r);
                return S * TMACorrection(w, g, depth);
            }

            // Vertex Shader: Mantiene los UVs y la posición de vértices
            v2f vert(MeshData IN)
            {
                v2f OUT;
                OUT.vertex = UnityObjectToClipPos(IN.vertex);
                OUT.uv = IN.uv;
                return OUT;
            }
            
            // Fragment Shader: Genera el espectro JONSWAP con el conjugado
            half4 frag(v2f IN) : SV_Target
            {
                float2 uv = IN.uv;
                float2 center = float2(0.5, 0.5); // Centro de la cuadrícula de Fourier
                float2 dir = uv - center;         // Vector dirección
                float distance = length(dir);     // Magnitud de la frecuencia espacial

                // Frecuencia angular
                float w = sqrt(_g * distance * tanh(distance * _depth)); 

                // Ángulo de dirección de la ola
                float theta = atan2(dir.y, dir.x); 
                float directionalSpectrum = cos(theta) * cos(theta);  // Efecto direccional

                // Generación de un número gaussiano aleatorio para la parte real e imaginaria
                float2 gauss = generateGaussianRandomNumber(_seed + distance);
                float Xr = gauss.x;  // Parte real
                float Xi = gauss.y;  // Parte imaginaria

                // Espectro JONSWAP
                float S = JONSWAP(w, _alpha, _gamma, _g, _wp, _depth); 

                // Cálculo del espectro h0 (parte real e imaginaria) y su conjugado
                float2 h0 = float2(Xr, Xi) * sqrt(S * directionalSpectrum) / sqrt(2);
                float2 h0Conjugate = float2(h0.x, -h0.y);  // Conjugado de h0

                // Retornar h0.xy y su conjugado en .zw
                return half4(h0.x, h0.y, h0Conjugate.x, h0Conjugate.y);
            }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
