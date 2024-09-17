Shader "Custom/Get_Height"
{
    Properties
    {
        // General parameters
        _N ("Grid Size", Int) = 256 // Square grid N = M, Lx = Lz
        _L ("Grid Length", Int) = 1000 
        _h ("Spectrum", 2D) = "" {}    
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

            sampler2D _h;
            int _N;
            int _L;

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

            // Euler's formula: e^(i * phase) = cos(phase) + i * sin(phase)
            float2 EulerFormula(float phase) 
            {
                return float2(cos(phase), sin(phase));
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
                h(x, t) = sum_{k} h(k, t) * exp(i * k * x)
            */
            half4 frag(v2f IN) : SV_Target
            {
                float2 uv = IN.uv;

                float4 displacement = float4(0, 0, 0, 1);
                
                float nx = int(uv.x * _N - _N / 2);
                float nz = int(uv.y * _N - _N / 2);
                float2 x = float2(nx * _L / _N, nz * _L / _N);

                for (int i = 0; i < _N; i++)
                {
                    for (int j = 0; j < _N; j++)
                    {
                        float ix = i * _N - _N / 2;
                        float iz = j * _N - _N / 2;
                        float2 k = float2(ix * 2 * PI / _L, iz * 2 * PI / _L);
                        normalize(k);
                        float2 h = tex2D(_h, k).xy;
                        float2 phase = dot(k, x);
                        if(h.x > 0 || h.y > 0)
                        {
                            displacement.xy += ComplexMult(h, EulerFormula(phase));
                        }
                    }
                }

                return half4(displacement);
            }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
