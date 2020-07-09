// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "Unlit/SobelFilter"
{
	Properties 
	{
	    [HideInInspector]_MainTex ("Base (RGB)", 2D) = "white" {}
		_PixelDensity ("Pixel Density", float) = 10
        _Power ("Power", float) = 50
		_PosterizationCount ("Count", int) = 8
	}
	SubShader 
	{
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		Pass
		{

            Blend SrcAlpha OneMinusSrcAlpha
            
            ZWrite On

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            
            TEXTURE2D(_DepthTex);
            SAMPLER(sampler_DepthTex);

            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            TEXTURE2D(_CameraColorTexture);
            SAMPLER(sampler_CameraColorTexture);
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            float _PixelDensity;
            int _PosterizationCount;
            float _Power;
            
            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv        : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            float SampleDepth(float2 uv)
            {
                return SAMPLE_DEPTH_TEXTURE(_DepthTex, sampler_DepthTex, uv);
            }
            
            float2 sobel (float2 uv) 
            {
                float2 delta = float2(_PixelDensity / _ScreenParams.x, _PixelDensity / _ScreenParams.y);

                float up = SampleDepth(uv + float2(0.0, 1.0) * delta);
                float down = SampleDepth(uv + float2(0.0, -1.0) * delta);
                float left = SampleDepth(uv + float2(1.0, 0.0) * delta);
                float right = SampleDepth(uv + float2(-1.0, 0.0) * delta);
                float centre = SampleDepth(uv);

                float depth = max(max(up, down), max(left, right));
                return float2(clamp(up - centre, 0, 1) + clamp(down - centre, 0, 1) + clamp(left - centre, 0, 1) + clamp(right - centre, 0, 1), depth);
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertexInput.positionCS;
                output.uv = input.uv;
                
                return output;
            }
            
            half4 frag (Varyings input, out float depth : SV_Depth) : SV_Target 
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                float2 sobelData = sobel(input.uv);
                float s = pow(abs(1 - saturate(sobelData.x)), _Power);
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                half4 d = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, input.uv);
                float x = ceil(SampleDepth(input.uv) - d.x);

                //col.a = x;
                col = pow(abs(col), 0.4545);
                float3 c = RgbToHsv(col);
                c.z = round(c.z * _PosterizationCount) / _PosterizationCount;
                col = float4(HsvToRgb(c), col.a);
                col = pow(abs(col), 2.2);


                
                s = floor(s+0.2);
                
                s = lerp(1.0, s, ceil(sobelData.y - d.x));
                depth = lerp(sobelData.y, SampleDepth(input.uv), s);
                col.rgb *= s;
                col.a += 1 - s;

                
                return col;
            }
            
			#pragma vertex vert
			#pragma fragment frag
			
			ENDHLSL
		}
        
	} 
	FallBack "Diffuse"
}
