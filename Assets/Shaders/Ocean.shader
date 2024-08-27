Shader "Custom/Ocean"
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
        _waveFrequency ("Wave Frequency", Float) = 1
        _waveAmplitude ("Wave Amplitude", Float) = 0.1
        _wavePhase ("Wave Phase", Float) = 1
        _waveDirection ("Wave Direction", Vector) = (1, 0, 1)
        // 
        _waveFrequency2 ("Wave Frequency 2", Float) = 1
        _waveAmplitude2 ("Wave Amplitude 2", Float) = 0.1
        _wavePhase2 ("Wave Phase 2", Float) = 1
        _waveDirection2 ("Wave Direction 2", Vector) = (1, 0, 1)
        // 
        _waveFrequency3 ("Wave Frequency 3", Float) = 1
        _waveAmplitude3 ("Wave Amplitude 3", Float) = 0.1
        _wavePhase3 ("Wave Phase 3", Float) = 1
        _waveDirection3 ("Wave Direction 3", Vector) = (1, 0, 1)
        // 
        _waveFrequency4 ("Wave Frequency 4", Float) = 1
        _waveAmplitude4 ("Wave Amplitude 4", Float) = 0.1
        _wavePhase4 ("Wave Phase 4", Float) = 1
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
            #include "UnityStandardBRDF.cginc"         

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
            float _waveFrequency;
            float _waveAmplitude;
            float _wavePhase;
            float3 _waveDirection;
            // 
            float _waveFrequency2;
            float _waveAmplitude2;
            float _wavePhase2;
            float3 _waveDirection2;
            //
            float _waveFrequency3;
            float _waveAmplitude3;
            float _wavePhase3;
            float3 _waveDirection3;
            //
            float _waveFrequency4;
            float _waveAmplitude4;
            float _wavePhase4;
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
            half4 CalculatePhongLight(float3 normal, float3 viewDir, float2 uv, float3 position)
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

                /* Scatter  
                https://gpuopen.com/gdc-presentations/2019/gdc-2019-agtd6-interactive-water-simulation-in-atlas.pdf
                */;
				// float3 scatterColor = _Diffuse.rgb;
				
				// float k1 = max(0, position.y) * pow(DotClamped(lightDir, -viewDir), 4.0f) * pow(0.5f - 0.5f * dot(normal, lightDir), 3.0f);
				// float k2 = pow(DotClamped(viewDir, normal), 2.0f);
				// float k3 = DotClamped(viewDir, normal);
				// float k4 = 2;

                
				// float3 scatter = (k1 + k2) * scatterColor * specular ;
				// scatter += k3 * scatterColor * specular + k4 * ambient * specular;

                /* Devolver color */
                return half4(ambient + diffuse + specular, 1);
                // return half4(scatter, 1);
                //return half4(diffuse, 1);
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
            // Based on Morgan McGuire @morgan3d
            // https://www.shadertoy.com/view/4dS3Wd
            float Random(float2 n) 
            {
                return frac(sin(dot(n, float2(12.9898, 78.233))) * 43758.5453);
            }

        float Noise(float2 st) 
        {
            float2 i = floor(st);
            float2 f = frac(st);

            // Cuatro esquinas en 2D de un tile
            float a = Random(i);
            float b = Random(i + float2(1.0, 0.0));
            float c = Random(i + float2(0.0, 1.0));
            float d = Random(i + float2(1.0, 1.0));

            float2 u = f * f * (3.0 - 2.0 * f);

            return lerp(a, b, u.x) +
                (c - a) * u.y * (1.0 - u.x) +
                (d - b) * u.x * u.y;
        }


            // Función para calcular las olas
            float CalculateWaveHeight(float4 position, float2 waveDirection, float waveFrequency, float waveAmplitude, float wavePhase)
            {
                float frequency = waveFrequency;
                float phase = wavePhase;
                float waveHeight = 0.0;
                float freq_mult = 1.2;
                float ampli_mult = 0.8;
                float d = position.x * waveDirection.x + position.z * waveDirection.y;

                for(int i = 0; i < _subWaves; i++)
                {
                    waveHeight += waveAmplitude * (exp(sin(d * frequency + _Time * phase)) - 1);
                    frequency *= freq_mult;
                    waveAmplitude *= ampli_mult;
                    //d = Noise(waveDirection.x) * position.xz + Noise(waveDirection.y) * position.xz;
                }
                
                return waveHeight;
            }
            

            // Función para calcular las derivadas de las olas
            float3 CalculateWaveDerivative(float4 position, float2 waveDirection, float waveFrequency, float waveAmplitude, float wavePhase)
            {
                float frequency = waveFrequency;
                float phase = wavePhase;
                float2 waveDerivative = (0,0);
                float freq_mult = 1.2;
                float ampli_mult = 0.8;
                float d = position.x * waveDirection.x + position.z * waveDirection.y;

                for(int i = 0; i < _subWaves; i++)
                {
                    waveDerivative.x += frequency * waveAmplitude * (exp(sin(d * frequency + _Time * phase)) - 1) * waveDirection.x * cos(d * frequency + _Time * phase);
                    waveDerivative.y += frequency * waveAmplitude * (exp(sin(d * frequency + _Time * phase)) - 1) * waveDirection.y * cos(d * frequency + _Time * phase);
                    frequency *= freq_mult;
                    waveAmplitude *= ampli_mult;
                    //d = Noise(waveDirection.x) * position.xz + Noise(waveDirection.y) * position.xz;
                }

                
                return float3(waveDerivative.x, waveDerivative.y, 0);
            }

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

                position.y += CalculateWaveHeight(position, waveDirection, _waveFrequency, _waveAmplitude, _wavePhase);
                derivative += CalculateWaveDerivative(position, waveDirection, _waveFrequency, _waveAmplitude, _wavePhase);     
                position.y += CalculateWaveHeight(position, waveDirection2 + derivative, _waveFrequency2, _waveAmplitude2, _wavePhase2);
                derivative += CalculateWaveDerivative(position, waveDirection2, _waveFrequency2, _waveAmplitude2, _wavePhase2);
                position.y += CalculateWaveHeight(position, waveDirection3 + derivative, _waveFrequency3, _waveAmplitude3, _wavePhase3);
                derivative += CalculateWaveDerivative(position, waveDirection3, _waveFrequency3, _waveAmplitude3, _wavePhase3);                   
                position.y += CalculateWaveHeight(position, waveDirection4 + derivative , _waveFrequency4, _waveAmplitude4, _wavePhase4);
                derivative += CalculateWaveDerivative(position, waveDirection4, _waveFrequency4, _waveAmplitude4, _wavePhase4);

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
                half4 Phong = CalculatePhongLight(IN.normal, normalize(IN.vRefract - _WorldSpaceCameraPos), IN.uv, IN.vertex.xyz);
                
                return Phong + fresnelColor * _EnviroIntensity;
            }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
