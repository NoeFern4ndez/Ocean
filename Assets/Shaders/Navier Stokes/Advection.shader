Shader "Custom/Advection"
{
    Properties
    { 
        _uV ("Velocity Texture", 2D) = "" {} // Campo de velocidades 
        _uX ("Advected Texture", 2D) = "" {} // Campo a advectar
        _uTimeStep ("Time Step", Float) = 0.1 // Δt
        _uDissipation ("Dissipation", Float) = 0.99 // Disipación
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
            sampler2D _uX;
            float _uTimeStep;
            float _uDissipation;
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
                half3 velocity = tex2D(_uV, IN.vCoords).xyz;
                half2 pos = IN.vCoords - _uTimeStep * velocity.xy; // q(x, t + Δt) = q(x - Δt * v(x, t), t) 

                return tex2D(_uX, pos) * _uDissipation;
            }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
