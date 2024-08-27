Shader "Custom/Force Application"
{
    Properties
    { 
        _uC ("Fluid Texture", 2D) = "" {}  // campo al que aplicar la fuerza (o color en el caso de la tinta)
        _uForceLocation ("Force Location", Vector) = (0.5, 0.5, 0.0, 0.0) // Posición de la fuerza
        _uForce ("Force", Vector) = (0.0, 0.0, 0.0, 0.0) // Fuerza a aplicar (o color en el caso de la tinta)
        _uRadius ("Radius", Float) = 0.1 // Radio de la fuerza
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

            sampler2D _uC;
            float4 _uForceLocation;
            float4 _uForce;
            float _uRadius;
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
                // f = F * exp(-||x - x_{click}||^2 / r^2)
                half3 f = _uForce.rgb * exp(-dot(_uForceLocation.xy - IN.vCoords, _uForceLocation.xy - IN.vCoords) / (_uRadius)); 
                half3 color = tex2D(_uC, IN.vCoords).rgb;
                return half4(color + f, 1.0);
            }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
