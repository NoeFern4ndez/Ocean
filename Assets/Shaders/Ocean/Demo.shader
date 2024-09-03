Shader "Custom/Demo"
{
    Properties
    { 
        // Visual properties
        // Colors
        _Color ("Color", Color) = (1,1,1,1) 
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Color) = (1, 1, 1, 1) 
        _Shininess ("Shininess", Float) = 32

        // Light properties
        _LightDir ("Light Direction", Vector) = (0, 1, 0)
        _Intensity ("Light Intensity", Float) = 1

        // Textures
        _WaterTex ("Water Texture", 2D) = "" {}
        _EnviroTexCube ("Environment", Cube) = "" {}
        _refractRatio ("Refract Ratio", Float) = 1.5
        _EnviroIntensity ("Environment Intensity", Range(0.0,1.0)) = 0.5

        // Wave properties Wi(x,y,t) = Ai * sin(Di.dot(x,y) + t * Fi)
        _subWaves ("Sub Waves", Int) = 10
        //
        _waveLength ("Wave Length", Float) = 1
        _waveAmplitude ("Wave Amplitude", Float) = 0.1
        _waveSpeed ("Wave Speed", Float) = 1
        _waveDirection ("Wave Direction", Vector) = (1, 0, 1)
        // 
        _waveLength2 ("Wave Length 2", Float) = 1
        _waveAmplitude2 ("Wave Amplitude 2", Float) = 0.1
        _waveSpeed2 ("Wave Speed 2", Float) = 1
        _waveDirection2 ("Wave Direction 2", Vector) = (1, 0, 1)
        // 
        _waveLength3 ("Wave Length 3", Float) = 1
        _waveAmplitude3 ("Wave Amplitude 3", Float) = 0.1
        _waveSpeed3 ("Wave Speed 3", Float) = 1
        _waveDirection3 ("Wave Direction 3", Vector) = (1, 0, 1)
        // 
        _waveLength4 ("Wave Length 4", Float) = 1
        _waveAmplitude4 ("Wave Amplitude 4", Float) = 0.1
        _waveSpeed4 ("Wave Speed 4", Float) = 1
        _waveDirection4 ("Wave Direction 4", Vector) = (1, 0, 1)
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

            // Visual properties
            float4 _Color;
            samplerCUBE _EnviroTexCube;
            sampler2D _WaterTex;
            float _refractRatio;
            float _Shininess;
            float4 _Specular;
            float4 _Diffuse;
            float3 _LightDir;
            float _Intensity;
            float _EnviroIntensity;
            // Wave properties
            int _subWaves;
            //
            float _waveLength;
            float _waveAmplitude;
            float _waveSpeed;
            float3 _waveDirection;
            // 
            float _waveLength2;
            float _waveAmplitude2;
            float _waveSpeed2;
            float3 _waveDirection2;
            //
            float _waveLength3;
            float _waveAmplitude3;
            float _waveSpeed3;
            float3 _waveDirection3;
            //
            float _waveLength4;
            float _waveAmplitude4;
            float _waveSpeed4;
            float3 _waveDirection4;

            struct MeshData
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float2 uv : TEXCOORD0;
                float vFresnel : TEXCOORD2;
                float3 vReflect : TEXCOORD3;
                float3 vRefract : TEXCOORD4;
            };

            /* Iluminación Phong */
            // Función para calcular la iluminación Phong
            half4 CalculatePhongLight(float3 normal, float3 viewDir, float2 uv)
            {
                /* Ambient */
                float3 ambient = (_Color.rgb * tex2D(_WaterTex, uv)) * _Intensity;

                /* Diffuse */
                float3 lightDir = normalize(_LightDir);
                float diff = max(0, dot(normal, lightDir));
                float3 diffuse = _Diffuse.rgb * diff * _Intensity;

                /* Specular */
                float3 reflectDir = reflect(-lightDir, normal);
                float spec = pow(max(0, dot(viewDir, reflectDir)), _Shininess);
                float3 specular = _Specular.rgb * spec * _Intensity;

                /* Devolver color */
                return half4(ambient + diffuse + specular, 1);
            }

            // Función para calcular Fresnel
            float CalculateFresnel(float3 ecView, float3 ecNormal)
            {
                float normRatio = 1.0 / _refractRatio;
                float f = pow((1.0 - normRatio), 2) / pow((1.0 + normRatio), 2);
                float fresnel = f + (1.0 - f) * pow(1.0 - dot(normalize(-ecView), ecNormal), 5);
                return fresnel;
            }

            // Función para calcular la dirección refractada
            float3 CalculateRefractDirection(float3 ecView, float3 ecNormal)
            {
                return refract(ecView, ecNormal, 1.0 / _refractRatio);
            }

            // Función para calcular la dirección reflejada
            float3 CalculateReflectDirection(float3 ecView, float3 ecNormal)
            {
                return reflect(ecView, ecNormal);
            }

            // Function for noise generation
            float2 Hash(float2 p)
            {
                p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
                return -1.0 + 2.0 * frac(sin(p) * 43758.5453123);
            }

            float Noise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);

                float2 u = f * f * (3.0 - 2.0 * f);

                return lerp(
                    lerp(dot(Hash(i + float2(0.0, 0.0)), f - float2(0.0, 0.0)),
                         dot(Hash(i + float2(1.0, 0.0)), f - float2(1.0, 0.0)), u.x),
                    lerp(dot(Hash(i + float2(0.0, 1.0)), f - float2(0.0, 1.0)),
                         dot(Hash(i + float2(1.0, 1.0)), f - float2(1.0, 1.0)), u.x), u.y);
            }

            // Función para calcular las olas
            float CalculateWaveHeight(float4 position, float2 waveDirection, float waveLength, float waveAmplitude, float waveSpeed)
            {
                float frequency = 2 / waveLength;
                float phase = waveSpeed * 2 / waveLength;
                float waveHeight = 0.0;
                float freq_mult = 1.0;
                float ampli_mult = 1.0;
                float d = position.x * waveDirection.x + position.z * waveDirection.y;

                for(int i = 0; i < _subWaves; i++)
                {
                    frequency *= freq_mult;
                    waveAmplitude *= ampli_mult;
                    waveHeight += waveAmplitude * (exp(waveAmplitude  * sin(d * frequency + _Time * phase)) - 1);
                    freq_mult *= 1.18;
                    ampli_mult *= 0.82;
                    waveDirection = Noise(frequency);
                }
                
                return waveHeight;
            }
            

            // Función para calcular las derivadas de las olas
            float3 CalculateWaveDerivative(float4 position, float2 waveDirection, float waveLength, float waveAmplitude, float waveSpeed)
            {
                float frequency = 2 / waveLength;
                float phase = waveSpeed * 2 / waveLength;
                float2 waveDerivative = (0,0);
                float freq_mult = 1.0;
                float ampli_mult = 1.0;
                float d = position.x * waveDirection.x + position.z * waveDirection.y;

                for(int i = 0; i < _subWaves; i++)
                {
                    frequency *= freq_mult;
                    waveAmplitude *= ampli_mult;
                    waveDerivative.x += frequency * waveAmplitude * (exp(sin(d * frequency + _Time * phase)) - 1) * waveDirection.x * cos(d * frequency + _Time * phase);
                    waveDerivative.y += frequency * waveAmplitude * (exp(sin(d * frequency + _Time * phase)) - 1) * waveDirection.y * cos(d * frequency + _Time * phase);
                    freq_mult *= 1.18;
                    ampli_mult *= 0.82;
                    waveDirection = Noise(frequency );
                }

                
                return float3(waveDerivative.x, waveDerivative.y, 0);
            }

            // // Function for FBM generation
            // float FBM(float2 p)
            // {
            //     float value = 0.0;
            //     float amplitude = 0.5;
            //     float frequency = 1.0;

            //     for (int i = 0; i < _subWaves; ++i)
            //     {
            //         value += amplitude * Noise(p * frequency);
            //         frequency *= 1.12;
            //         amplitude *= 0.88;
            //     }

            //     return value;
            // }

            v2f vert(MeshData IN)
            {
                v2f OUT;
                float4 position = IN.vertex;
                float3 normal = IN.normal;

                // Altura de la ola
                float2 derivative = (0,0);
                float2 waveDirection = normalize(_waveDirection.xy);
                float2 waveDirection2 = normalize(_waveDirection2.xy);
                float2 waveDirection3 = normalize(_waveDirection3.xy);
                float2 waveDirection4 = normalize(_waveDirection4.xy);

                position.y += CalculateWaveHeight(position, waveDirection, _waveLength, _waveAmplitude, _waveSpeed);
                derivative += CalculateWaveDerivative(position, waveDirection, _waveLength, _waveAmplitude, _waveSpeed);     
                position.y += CalculateWaveHeight(position, waveDirection2 + derivative, _waveLength2, _waveAmplitude2, _waveSpeed2);
                derivative += CalculateWaveDerivative(position, waveDirection2, _waveLength2, _waveAmplitude2, _waveSpeed2);
                position.y += CalculateWaveHeight(position, waveDirection3 + derivative, _waveLength3, _waveAmplitude3, _waveSpeed3);
                derivative += CalculateWaveDerivative(position, waveDirection3, _waveLength3, _waveAmplitude3, _waveSpeed3);                   
                position.y += CalculateWaveHeight(position, waveDirection4 + derivative , _waveLength4, _waveAmplitude4, _waveSpeed4);
                derivative += CalculateWaveDerivative(position, waveDirection4, _waveLength4, _waveAmplitude4, _waveSpeed4);
                
                // nueva normal tras el desplazamiento de la ola
                float3 tangent = normalize(float3(1, 0, derivative.x));
                float3 binormal = normalize(float3(0, 1, derivative.y));
                normal = normalize(cross(tangent, binormal));

                // Fresnel y direcciones de reflexión/refracción
                float3 ecNormal = normalize(UnityObjectToWorldNormal(normal));
                float3 ecView = mul(unity_ObjectToWorld, IN.vertex).xyz - _WorldSpaceCameraPos;
                OUT.vFresnel = CalculateFresnel(ecView, ecNormal);
                OUT.vReflect = CalculateReflectDirection(ecView, ecNormal);
                OUT.vRefract = CalculateRefractDirection(ecView, ecNormal);

                OUT.vertex = UnityObjectToClipPos(position);
                OUT.normal = ecNormal;
                OUT.uv = IN.uv;

                return OUT;
            }

            half4 frag(v2f IN) : SV_Target
            {
                half4 fresnelColor = lerp(texCUBE(_EnviroTexCube, IN.vRefract), texCUBE(_EnviroTexCube, IN.vReflect), IN.vFresnel);
                half4 Phong = CalculatePhongLight(IN.normal, normalize(IN.vRefract - _WorldSpaceCameraPos), IN.uv);
                return lerp(Phong, fresnelColor, _EnviroIntensity);
            }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
