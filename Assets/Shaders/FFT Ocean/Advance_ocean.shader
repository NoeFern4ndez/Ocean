Shader "Custom/Advance_ocean"
{
    Properties
    {
        // General parameters
        _N ("Grid Size", Int) = 256 // Square grid N = M, Lx = Lz
        _L ("Grid Length", Int) = 1000 
        // Spectrum parameters
        _h0 ("Initial Spectrum", 2D) = "" {}    // Initial spectrum texture (and its conjugate)
        _g ("Gravity", float) = 9.81        
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

            sampler2D _h0;
            int _N;
            int _L;
            float _g;
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

            //  Complex multiplication: (a + bi) * (c + di) = (ac - bd) + (ad + bc)i
            float2 ComplexMult(float2 a, float2 b) 
            {
                return float2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
            }

            // Euler's formula: e^(i * phase) = cos(phase.r) + i * sin(phase.i)
            float2 EulerFormula(float2 phase) 
            {
                return float2(cos(phase.y), sin(phase.y)) * exp(phase.x);
            }

            // Vertex Shader: Maintains UVs and vertex position
            v2f vert(MeshData IN)
            {
                v2f OUT;
                OUT.vertex = UnityObjectToClipPos(IN.vertex);
                OUT.uv = IN.uv;
                return OUT;
            }

            /*
                h(k, t) = h0(k) * e^(i * ω(k) * t) + h0*(-k) * e^(-i * ω(k) * t)
            */
            half4 frag(v2f IN) : SV_Target
            {
                float2 uv = IN.uv;

                float4 initialSpectrum = tex2D(_h0, uv);   
                float2 h0 = initialSpectrum.xy;    
                float2 h0conj = initialSpectrum.zw;

                // k(kx, kz) = (2πn/L) where -N/2 <= n <= N/2
                float deltaK = 2 * PI / _L;
                int nx = int(uv.x * _N - _N / 2);
                int nz = int(uv.y * _N - _N / 2);
                float2 k = float2(nx, nz) * deltaK;
                float kmag = length(k);

                // w(k) = sqrt(g * |k| * tanh(|k| * d))
                float w = sqrt(_g * kmag); // * tanh(kmag * _depth));

                // phase = ω(k) * t
                float phase = w * _Time.y;

                // exp(i * phase) and exp(-i * phase)
                float2 eip = EulerFormula(float2(0, phase));
                float2 einp = float2(eip.x, -eip.y);

                // h(k, t) = h0(k) * e^(i * ω(k) * t) + h0*(-k) * e^(-i * ω(k) * t)
                float2 h = ComplexMult(h0, eip) + ComplexMult(h0conj, einp);

                return half4(h.x, h.y, 0, 1);
            }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
