Shader "Custom/Initial_Spectrum"
{
    Properties
    {
        // General parameters
        _N ("Grid Size", Int) = 256 // Square grid N = M, Lx = Lz
        _L ("Grid Length", Int) = 1000 
        // JONSWAP parameters
        _gamma("Gamma", Float) = 3.3
        _alpha("Alpha", Float) = 0.0081
        _g("Gravity", Float) = 9.81
        _wp("Peak frequency", Float) = 1
        _depth("Water Depth", Float) = 200
        _angle("Wind Angle", Float) = 0 // In degrees
        // Gaussian parameters
        _seed("Seed", Float) = 1
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

            int _N;
            int _L;
            float _gamma;
            float _alpha;
            float _g;
            float _wp;
            float _seed;
            float _depth;
            float _angle;

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

            // Gaussian random number generation
            float2 generateGaussianRandomNumber(float seed)
            {
                float u1 = max(0.0001, frac(sin(seed) * 43758.5453)); 
                float u2 = frac(sin(seed + 1.0) * 43758.5453);
                float R = sqrt(-2.0 * log(u1));
                float theta = 2.0 * PI * u2;
                return float2(R * cos(theta), R * sin(theta));
            }

            // Texel MARSEN ARSLOE (TMA) correction of JONSWAP: ref: https://dl.acm.org/doi/pdf/10.1145/2791261.2791267
            float TMACorrection(float omega, float g, float depth)
            {
                float omegaH = omega * sqrt(depth / g);
                if (omegaH <= 1)
                    return 0.5 * omegaH * omegaH;
                if (omegaH < 2)
                    return 1.0 - 0.5 * (2.0 - omegaH) * (2.0 - omegaH);
                return 1;
            }

            // JONSWAP spectrum (with TMA correction)
            float JONSWAP(float w, float alpha, float gamma, float g, float wp, float depth)
            {
                float sigma = step(w, wp) * 0.07 + (1 - step(w, wp)) * 0.09;
                float r = exp(-(w - wp) * (w - wp) / (2 * sigma * sigma * wp * wp));

                float S = alpha * g * g / pow(w, 5) * exp(-1.25 * pow(wp / w, 4)) * pow(gamma, r);
                return S * TMACorrection(w, g, depth);
            }

            /*
                D(theta, w) = beta / (2 * tahn(beta * π)) * sech(beta * theta)^2

                    beta = 2.61 * (w / wp)^(1.3) for 0.56 < w/wp < 0.95
                    beta = 2.28 * (w / wp)^(-1.3) for 0.95 <= w/wp < 1.6
                    beta = 10^epsilon for w/wp >= 1.6 

                    epsilon = −0.4 + 0.8393 exp[−0.567 ln((ω/ωp)^2)]
            */
            float DonelanBanner(float theta, float w, float wp)
            {
                float wdiv = w / wp;
                float epsilon = -0.4 + 0.8393 * exp(-0.567 * log(wdiv * wdiv));
                float beta = pow(10, epsilon);

                if (wdiv < 0.95)
                    beta = 2.61 * pow(abs(wdiv), 1.3);
                if (wdiv < 1.6)
                    beta = 2.28 * pow(abs(wdiv), -1.3);

                float sech = 1 / cosh(beta * theta);

                return beta / (2 * tanh(beta * PI)) * sech * sech;
            }

            v2f vert(MeshData IN)
            {
                v2f OUT;
                OUT.vertex = UnityObjectToClipPos(IN.vertex);
                OUT.uv = IN.uv;
                return OUT;
            }
            
            /*
                h0 = 1/sqrt(2) * (Xr + iXi) * sqrt(2* S(w) * D(theta, w) * dw(k)/dk * 1/k * Δkx * Δkz)
                h0*= h0.x, -h0.y
                output: (h0.x, h0.y, h0*.x, h0*.y)
            */
            half4 frag(v2f IN) : SV_Target
            {
                float2 uv = IN.uv;

                // k(kx, kz) = (2πn/L) where -N/2 <= n <= N/2
                float deltaK = 2 * PI / _L;
                int nx = int(uv.x * _N - _N / 2);
                int nz = int(uv.y * _N - _N / 2);
                float2 k = float2(nx, nz) * deltaK;
                float kmag = length(k);

                // w(k) = sqrt(g * |k| * tanh(|k| * d))
                float w = sqrt(_g * kmag * tanh(kmag * _depth));
                // dw(k)/dk = sqrt(g * tanh(|k| * d)) * (1 + |k| / (1 + |k| * d)) / (2 * |k|)
                float wder = _g * (_depth * kmag / (cos(kmag * _depth) * cos(kmag * _depth)) + 1) / (2 * w);

                // D(theta, w): Donelan-Banner directional spreading. Ref: https://dl.acm.org/doi/pdf/10.1145/2791261.2791267
                float kangle = atan2(k.y, k.x);
                float theta = kangle - _angle * PI / 180; 
                float D = DonelanBanner(theta, w, _wp);

                // (Xr, iXi)
                float2 gauss = generateGaussianRandomNumber(_seed + kmag);
                float Xr = gauss.x;  
                float Xi = gauss.y;  

                // S(w): JONSWAP with TMA correction
                float S = JONSWAP(w, _alpha, _gamma, _g, _wp, _depth); 

                // (h0, h0*)
                float2 h0 = 1 / sqrt(2) * float2(Xr, Xi) * sqrt(2 * S * D * abs(wder) / kmag * deltaK * deltaK);
                float2 h0Conjugate = float2(-h0.x, -h0.y);

                return half4(h0.x, h0.y, h0Conjugate.x, h0Conjugate.y);
            }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
