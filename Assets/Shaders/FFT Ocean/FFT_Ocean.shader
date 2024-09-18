Shader "Custom/FFT_Ocean"
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

        // Wave textures
        _dispScale1 ("Displacement Scale 1", Float) = 1
        _dispScale2 ("Displacement Scale 2", Float) = 1
        _dispScale3 ("Displacement Scale 3", Float) = 1
        _dispScale4 ("Displacement Scale 4", Float) = 1

        _fftTexture1 ("FFT Texture 1", 2D) = "" {}
        _fftTexture2 ("FFT Texture 2", 2D) = "" {}
        _fftTexture3 ("FFT Texture 3", 2D) = "" {}
        _fftTexture4 ("FFT Texture 4", 2D) = "" {}

        _fftDerivative1 ("FFT Derivative 1", 2D) = "" {}
        _fftDerivative2 ("FFT Derivative 2", 2D) = "" {}
        _fftDerivative3 ("FFT Derivative 3", 2D) = "" {}
        _fftDerivative4 ("FFT Derivative 4", 2D) = "" {}

        
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
            // Wave textures
            sampler2D _fftTexture1;
            sampler2D _fftTexture2;
            sampler2D _fftTexture3;
            sampler2D _fftTexture4;

            sampler2D _fftDerivative1;
            sampler2D _fftDerivative2;
            sampler2D _fftDerivative3;
            sampler2D _fftDerivative4;

            float _dispScale1;
            float _dispScale2;
            float _dispScale3;
            float _dispScale4;


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
                float vReflect : TEXCOORD3;
                float vRefract : TEXCOORD4;
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
                float spec = pow(max(0, dot(viewDir, -reflectDir)), _Shininess);
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

            v2f vert(MeshData IN)
            {
                v2f OUT;
                float4 position = IN.vertex;
                float3 normal = IN.normal;
           
                   
                float4 displacement = tex2Dlod(_fftTexture1, float4(IN.uv, 0, 0)) * _dispScale1;
                // displacement += tex2Dlod(_fftTexture2, float4(IN.uv, 0, 0)) * _dispScale2;
                // displacement += tex2Dlod(_fftTexture3, float4(IN.uv, 0, 0)) * _dispScale3;
                // displacement += tex2Dlod(_fftTexture4, float4(IN.uv, 0, 0)) * _dispScale4;
                position.y += length(displacement.xy);

                // Fresnel y direcciones de reflexión/refracción
                float3 ecNormal = normalize(UnityObjectToWorldNormal(normal));
                float3 ecView = mul(unity_ObjectToWorld, IN.vertex).xyz - _WorldSpaceCameraPos;
                OUT.vFresnel = CalculateFresnel(ecView, ecNormal);
                OUT.vReflect = CalculateReflectDirection(ecView, ecNormal);
                OUT.vRefract = CalculateRefractDirection(ecView, ecNormal);

                //OUT.vertex = UnityObjectToClipPos(position);
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
