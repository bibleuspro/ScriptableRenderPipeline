// ------------------------------------------
// Only directional light is supported for lit particles
// No shadow
// No distortion
Shader "LightweightPipeline/Particles/Standard (Simple Lighting)"
{
    Properties
    {
        _MainTex("Albedo", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)

        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        _Shininess("Shininess", Range(0.01, 1.0)) = 1.0
        _GlossMapScale("Smoothness Factor", Range(0.0, 1.0)) = 1.0

        _Glossiness("Glossiness", Range(0.0, 1.0)) = 0.5
        [Enum(Specular Alpha,0,Albedo Alpha,1)] _SmoothnessTextureChannel("Smoothness texture channel", Float) = 0

        [HideInInspector] _SpecSource("Specular Color Source", Float) = 0.0
        _SpecColor("Specular", Color) = (1.0, 1.0, 1.0)
        _SpecGlossMap("Specular", 2D) = "white" {}
        [HideInInspector] _GlossinessSource("Glossiness Source", Float) = 0.0
        [ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
        [ToggleOff] _GlossyReflections("Glossy Reflections", Float) = 1.0

        [HideInInspector] _BumpScale("Scale", Float) = 1.0
        [NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}

        _EmissionColor("Color", Color) = (0,0,0)
        _EmissionMap("Emission", 2D) = "white" {}

        _SoftParticlesNearFadeDistance("Soft Particles Near Fade", Float) = 0.0
        _SoftParticlesFarFadeDistance("Soft Particles Far Fade", Float) = 1.0
        _CameraNearFadeDistance("Camera Near Fade", Float) = 1.0
        _CameraFarFadeDistance("Camera Far Fade", Float) = 2.0

        // Hidden properties
        [HideInInspector] _Mode("__mode", Float) = 0.0
        [HideInInspector] _FlipbookMode("__flipbookmode", Float) = 0.0
        [HideInInspector] _LightingEnabled("__lightingenabled", Float) = 1.0
        [HideInInspector] _EmissionEnabled("__emissionenabled", Float) = 0.0
        [HideInInspector] _BlendOp("__blendop", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0
        [HideInInspector] _SoftParticlesEnabled("__softparticlesenabled", Float) = 0.0
        [HideInInspector] _CameraFadingEnabled("__camerafadingenabled", Float) = 0.0
        [HideInInspector] _SoftParticleFadeParams("__softparticlefadeparams", Vector) = (0,0,0,0)
        [HideInInspector] _CameraFadeParams("__camerafadeparams", Vector) = (0,0,0,0)
    }

    SubShader
    {
        Tags{"RenderType" = "Opaque" "IgnoreProjector" = "True" "PreviewType" = "Plane" "PerformanceChecks" = "False" "RenderPipeline" = "LightweightPipeline"}

        BlendOp[_BlendOp]
        Blend[_SrcBlend][_DstBlend]
        ZWrite[_ZWrite]
        Cull[_Cull]

        Pass
        {
            Tags {"LightMode" = "LightweightForward"}
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma vertex ParticlesLitVertex
            #pragma fragment ParticlesLitFragment
            #pragma multi_compile __ SOFTPARTICLES_ON
            #pragma target 2.0

            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON _ALPHAMODULATE_ON
            #pragma shader_feature _ _SPECGLOSSMAP _SPECULAR_COLOR
            #pragma shader_feature _ _GLOSSINESS_FROM_BASE_ALPHA
            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _EMISSION
            #pragma shader_feature _FADING_ON
            #pragma shader_feature _REQUIRE_UV2

            #define NO_SHADOWS 1

            #include "LWRP/ShaderLibrary/Particles.hlsl"
            #include "LWRP/ShaderLibrary/Lighting.hlsl"

            VertexOutputLit ParticlesLitVertex(appdata_particles v)
            {
                VertexOutputLit o;

                OUTPUT_NORMAL(v, o);

                o.color = v.color * _Color;
                o.posWS.xyz = TransformObjectToWorld(v.vertex.xyz).xyz;
                o.posWS.w = ComputeFogFactor(o.clipPos.z);
                o.clipPos = TransformWorldToHClip(o.posWS.xyz);
                o.viewDirShininess.xyz = VertexViewDirWS(GetCameraPositionWS() - o.posWS.xyz);
                o.viewDirShininess.w = _Shininess * 128.0h;
                vertTexcoord(v, o);
                vertFading(o, o.posWS, o.clipPos);
                return o;
            }

            half4 ParticlesLitFragment(VertexOutputLit IN) : SV_Target
            {
                half4 albedo = Albedo(IN);
                half alpha = AlphaBlendAndTest(albedo.a);
                half3 diffuse = AlphaModulate(albedo.rgb, alpha);
                half3 normalTS = NormalTS(IN);
                half3 emission = Emission(IN);
                half4 specularGloss = SpecularGloss(IN, albedo.a);
                half shininess = IN.viewDirShininess.w;

                InputData inputData;
                InitializeInputData(IN, normalTS, inputData);

                half4 color = LightweightFragmentBlinnPhong(inputData, diffuse, specularGloss, shininess, emission, alpha);

                ApplyFog(color.rgb, inputData.fogCoord);
                return color;
            }

            ENDHLSL
        }
    }

    Fallback "LightweightPipeline/Particles/Standard Unlit"
    CustomEditor "LightweightStandardParticlesShaderGUI"
}