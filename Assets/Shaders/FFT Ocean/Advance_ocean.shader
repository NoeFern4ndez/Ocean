Shader "Custom/Advance_ocean"
{
    Properties
    { 
        _h0 ("Initial Spectrum", 2D) = "" {}      // Espectro inicial
        _FrameTime ("Time", float) = 0.0               // Tiempo actual
        _Gravity ("Gravity", float) = 9.81        // Gravedad
        _N ("Grid Size", float) = 256.0           // Tamaño de la cuadrícula (256x256, por ejemplo)
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

            sampler2D _h0;    // Espectro inicial (h0.xy = real e imaginario, h0.zw = conjugado)
            float _FrameTime;      // Tiempo actual
            float _Gravity;   // Gravedad
            float _N;         // Tamaño de la cuadrícula (ej: 256)

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

            // Función para multiplicación compleja
            float2 ComplexMult(float2 a, float2 b) {
                return float2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
            }

            // Función que representa la fórmula de Euler (e^(ix) = cos(x) + i*sin(x))
            float2 EulerFormula(float phase) {
                return float2(cos(phase), sin(phase));
            }

            // Vertex Shader: Mantiene los UVs y la posición de vértices
            v2f vert(MeshData IN)
            {
                v2f OUT;
                OUT.vertex = UnityObjectToClipPos(IN.vertex);
                OUT.uv = IN.uv;
                return OUT;
            }

            // Fragment Shader: Calcula el espectro evolucionado
            half4 frag(v2f IN) : SV_Target
            {
                float halfN = _N / 2.0f;

                // Cargar los valores iniciales del espectro a partir de las UV
                float4 initialSpectrum = tex2D(_h0, IN.uv);   // h0.xy = real e imaginario, h0.zw = conjugado

                float2 h0 = initialSpectrum.xy;     // Parte real e imaginaria del espectro inicial
                float2 h0conj = initialSpectrum.zw; // Parte conjugada

                // Calcular el vector de onda K a partir de las UV
                float2 K = (IN.uv * _N - halfN) * 2.0f * PI / _N;
                float kMag = length(K);  // Magnitud del vector de onda

                // Evitar problemas de división por cero para ondas estáticas
                if (kMag < 0.0001f) {
                    return half4(0, 0, 0, 1);  // No calcular si el número de onda es casi cero
                }

                // Relación de dispersión ω(k) = sqrt(g * |k|)
                float w_k = sqrt(_Gravity * kMag);

                // Fase de avance temporal usando ω(k) * t
                float phase = w_k * _FrameTime;

                // Calcular e^(i*phase) y e^(-i*phase)
                float2 eip = EulerFormula(phase);     // e^(i * phase)
                float2 einp = float2(eip.x, -eip.y);  // e^(-i * phase) = conjugado de eip

                // Evolución temporal del espectro usando la fórmula de Euler
                float2 hT = ComplexMult(h0, eip) + ComplexMult(h0conj, einp);

                // Convertir el espectro evolucionado en color (esto es para depuración/visualización)
                return half4(hT.x, hT.y, 0, 1);
            }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
