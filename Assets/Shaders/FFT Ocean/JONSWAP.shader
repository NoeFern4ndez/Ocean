Shader "Custom/JONSWAP"
{
    Properties
    { 
        _gamma("Gamma", Float) = 3.3
        _alpha("Alpha", Float) = 0.0081
        _g("Gravity", Float) = 9.81
        _wp("Peak frequency", Float) = 1
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

            float _gamma;
            float _alpha;
            float _g;
            float _wp;
            float _seed;

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

            // Genera números aleatorios gaussianos basados en la semilla
            float2 generateGaussianRandomNumber(float seed)
            {
                float u1 = frac(sin(seed) * 43758.5453);
                float u2 = frac(sin(seed + 1.0) * 43758.5453);
                
                float R = sqrt(-2.0 * log(u1));
                float theta = 2.0 * PI * u2;
                return float2(R * cos(theta), R * sin(theta));
            }

            // Espectro JONSWAP
            float JONSWAP(float w, float alpha, float gamma, float g, float wp)
            {
                float sigma = step(w, wp) * 0.09 + step(wp, w) * 0.07;
                float r = exp(-(pow(w - wp, 2)) / (2 * sigma * sigma * wp * wp));

                float w5 = pow(w, 5);
                float wfrac4 = pow(wp / w, 4);
                
                return alpha * g * g / w5 * exp(-0.74 * wfrac4) * pow(gamma, r);
            }

            v2f vert(MeshData IN)
            {
                v2f OUT;
                OUT.vertex = UnityObjectToClipPos(IN.vertex);
                OUT.uv = IN.uv;
                return OUT;
            }
            
            /*
                JONSWAP:
                    -Spectrum texture: h0 = 1 / sqrt(2) * (Xr + iXi) * sqrt(S(w))
                    -Xr, Xi: Gaussian random numbers
                    -S(w): JONSWAP spectrum
                    
                    - S(w) = alpha * g^2 / w^5 * exp(-5/4 * (wp / w)^4) * gamma^r 
                        - r = exp(-1/2 * (w - wp)^2 / sigma^2)
                        - sigma: 0.07 for fully developed sea (w <= wp), 0.09 for developing sea (w > wp)
                        - w = 2 * pi * f
                        - wp = 22 * (g / (U10 * F))^1/3
                        - U10: Wind speed at 10m above sea level
                        - F: Fetch (distance of open water over which the wind blows)
                        - gamma = 3.3
                        - alpha = 0.076 * (U10^2 / (F * g))^0.22

                    Output: texture where R channel is the real part and G channel is the imaginary part
                    -Distance from the center of the texture is the frequency
                    -Value of the R and G channels is the amplitude of the wave
                    -Direction of the wave is the angle of the pixel to the center of the texture
            */
            half4 frag(v2f IN) : SV_Target
            {
                float2 uv = IN.uv;
                float2 center = float2(0.5, 0.5);
                float2 dir = uv - center;
                float distance = length(dir);

                float w = distance * 2 * PI; // w = 2 * pi * f

                // Xr, Xi => Números aleatorios gaussianos
                float2 gauss = generateGaussianRandomNumber(_seed + distance);
                float Xr = gauss.x;
                float Xi = gauss.y;
                
                float S = JONSWAP(w, _alpha, _gamma, _g, _wp); // S(w) => Espectro JONSWAP

                // h0: 1 / sqrt(2) * (Xr + iXi) * sqrt(S)
                float2 h0 = float2(Xr, Xi) * sqrt(S) / sqrt(2);

                return half4(h0.x, h0.y, 0, 1);
            }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
