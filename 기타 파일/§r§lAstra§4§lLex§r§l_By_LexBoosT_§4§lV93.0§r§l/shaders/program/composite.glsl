/*#############################################
#    _   ___ _____ ___    _   _    _____  __  #
#   /_\ / __|_   _| _ \  /_\ | |  | __\ \/ /  #
#  / _ \\__ \ | | |   / / _ \| |__| _| >  <   #
# /_/ \_\___/ |_| |_|_\/_/ \_\____|___/_/\_\  #
#											  #
#############################################*/

//Settings//////////////////Settings///////////////////Settings///////////////////Settings//

#include "/lib/util/functions.glsl"

#include "/settings/globalSettings.glsl"

//Varying////////////////////Varying////////////////////Varying////////////////////Varying//
varying vec2 texCoord;
varying vec3 sunVec, upVec, uSunVec;

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

	//Includes//
	#if (defined LIGHT_SHAFT_END && defined END && defined ENDER_SMOKER_LIGHT_SHAFT) || (defined LIGHT_SHAFT && SMOKER_LIGHT_SHAFT_UNDERWATER == 1 && defined OVERWORLD) || (defined LIGHT_SHAFT_END && SMOKER_LIGHT_SHAFT_UNDERWATER == 1 && defined END)
	#include "/lib/util/moonrot.glsl"
	#endif

	//Program//
	void main(){
		texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

		gl_Position=ftransform();

		upVec = normalize(gbufferModelView[1].xyz);
		uSunVec = GetuSunVec();
		sunVec = GetSunVec(uSunVec);
	}

#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

	//Uniforms//
	uniform sampler2D colortex0;
	uniform sampler2D colortex1;

	#if REFRACTION > 0
	uniform sampler2D colortex14;
	#endif

	uniform sampler2D depthtex0;
	uniform sampler2D depthtex1;
	uniform sampler2D noisetex;

	#if !defined OUTLINE_TRIPWIRE
		uniform sampler2D colortex8;
	#endif

	uniform int frameCounter;
	uniform int isEyeInWater;

	#ifdef UNDERGROUND_SKY
	uniform float isEyeInCave;
	#endif

	uniform float blindFactor, darknessFactor, nightVision;
	uniform float far, near;
	uniform float frameTimeCounter;
	uniform float rainFactor;
	uniform float screenBrightness;
	uniform float viewWidth, viewHeight, aspectRatio;

	uniform ivec2 eyeBrightnessSmooth;

	uniform vec3 cameraPosition;

	uniform mat4 gbufferProjection, gbufferProjectionInverse;
	uniform mat4 gbufferModelView, gbufferModelViewInverse;
	uniform mat4 shadowModelView;
	uniform mat4 shadowProjection;

	uniform vec3 fogColor;

	#if ((defined OVERWORLD && defined LIGHT_SHAFT) || (defined END && defined LIGHT_SHAFT_END))
		uniform sampler2DShadow shadowtex0;
		uniform sampler2DShadow shadowtex1;
		uniform sampler2D shadowcolor0;

		const bool generateShadowMipmap = false;
		const bool generateShadowColorMipmap = false;

		const bool shadowcolor0Nearest = false;
		const vec4 shadowcolor0ClearColor = vec4(1.0, 1.0, 1.0, 1.0);
		const bool shadowcolor0Clear = true;

		const bool shadowtex0Mipmap = false;
		const bool shadowtex0Nearest = false;
		const bool shadowHardwareFiltering0 = true;

		const bool shadowtex1Mipmap = false;
		const bool shadowtex1Nearest = false;
		const bool shadowHardwareFiltering1 = true;
	#endif

	//Common Variables//
	float eBS               = eyeBrightnessSmooth.y / 240.0;
	float sunVisibility     = clamp00125(dot( sunVec, upVec) + 0.0625) * 8.0;
	float moonVisibility    = clamp00125(dot( -sunVec, upVec) + 0.0625) * 8.0;
	float screenBrightness2 = clamp01(screenBrightness);

	vec3 lightVec = sunVec * (1.0 - 2.0 * float(timeAngle > 0.5325 && timeAngle < 0.9675));

	//Common Functions//
	float GetLinearDepth(float depth) {
		return (2.0 * near) / (far + near - depth * (far - near));
	}

	#if ((defined OVERWORLD && defined LIGHT_SHAFT) || (defined END && defined LIGHT_SHAFT_END))
		float GetDepth(float depth) {
			return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
		}

		float GetDistX(float dist) {
			return (far * (dist - near)) / (dist * (far - near));
		}

		float BlueNoise(vec2 coord) {
    		return texelFetch(noisetex, ivec2(coord)% 64, 0).b;
		}
	#endif

	//Includes//
	#if (defined NETHER || defined END)
	#include "/lib/color/lightColor.glsl"
	#endif

	#include "/lib/color/dimensionColor.glsl"
	#include "/lib/color/waterColor.glsl"
	#include "/lib/util/dither.glsl"
	#include "/lib/atmospherics/waterFog.glsl"
	#include "/lib/util/spaceConversion.glsl"

	#if ((defined OVERWORLD && defined LIGHT_SHAFT) || (defined END && defined LIGHT_SHAFT_END))
	#include "/lib/atmospherics/volumetricLight.glsl"
	#endif

	#ifdef OUTLINE_ENABLED
	#include "/lib/color/skyColor.glsl"
	#include "/lib/color/blocklightColor.glsl"
	#include "/lib/outline/outlineOffset.glsl"
	#include "/lib/outline/outlineMask.glsl"
	#include "/lib/atmospherics/sky.glsl"
	#include "/lib/atmospherics/fog.glsl"
	#include "/lib/outline/blackOutline.glsl"
	#endif

	//Program//
	void main(){
		vec4  color      =texelFetch(colortex0, texelCoord, 0);
		vec3  translucent=texelFetch(colortex1, texelCoord, 0).rgb;
		vec3  worldPos   =vec3(0.0);
		vec3  vl         =vec3(0.0);
		float z0         =texelFetch(depthtex0, texelCoord, 0).r;
		float z1         =texelFetch(depthtex1, texelCoord, 0).r;
		bool water = false;

		if (translucent.b > 0.999 && z1 > z0) {
			water = true;
			translucent = vec3(1.0);
		}

		vec4 screenPos = vec4(texCoord.x, texCoord.y, z0, 1.0);
		vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
		viewPos /= viewPos.w;

		#if REFRACTION > 0

			if (z1 > z0) {

				vec3 distortion = texture2D(colortex14, texCoord).xyz;

				float fovScale = gbufferProjection[1][1] / 1.37;

				distortion.xy = distortion.xy * 2.0 - 1.0;

				distortion.xy *= vec2(1.0 / aspectRatio, 1.0) * fovScale / max(length(viewPos.xyz), 8.0);

				vec2 newCoord = texCoord + distortion.xy;

				float distortionMask = texture2D(colortex14, newCoord).b * distortion.b;

				if (distortionMask == 1.0 && z0 > 0.56) {

					z0 = texture2D(depthtex0, newCoord).r;
					z1 = texture2D(depthtex1, newCoord).r;

					color.rgb = texture2D(colortex0, newCoord).rgb;
				}

				screenPos = vec4(newCoord.x, newCoord.y, z0, 1.0);
				viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
				viewPos /= viewPos.w;
			}

		#endif

		#ifdef OUTLINE_ENABLED
			vec4 outerOutline=vec4(0.0), innerOutline = vec4(0.0);

			float outlineMask = GetOutlineMask();

			if (outlineMask > 0.5 || isEyeInWater > 0.5) {
				Outline(color.rgb, true, outerOutline, innerOutline);
			}

			#if PROMO_OUTLINE_EVERYWHERE > 0
				if(z1 > z0) color.rgb=mix(color.rgb, innerOutline.rgb, innerOutline.a);
			#endif
		#endif

		if (isEyeInWater == 1.0) {
			vec4 waterFog   =GetWaterFog(viewPos.xyz);
			     waterFog.a =mix(waterAlpha * 0.5, 1.0, waterFog.a);
			     color.rgb  =mix(sqrt(color.rgb), sqrt(waterFog.rgb), waterFog.a);
			     color.rgb *=color.rgb;
		}

		#if ((defined OVERWORLD && defined LIGHT_SHAFT) || (defined END && defined LIGHT_SHAFT_END))
			vec3  nViewPos = normalize(viewPos.xyz);
			vec3  vlAlbedo = translucent;

			float NdotVoL = dot(nViewPos, lightVec);
			float noise = 0.0;

		#if TEXTURED_DITHERING == 0
			noise = BlueNoise(gl_FragCoord.xy);
			noise = animateDither(noise);
		#else
			noise = InterleavedGradientNoise();
		#endif

			if    (isEyeInWater == 0 && water) vlAlbedo = vec3(0.0);
			float depth0                                = GetDepth(z0);
			float depth1                                = GetDepth(z1);
			vl = getVolumetricRays(depth0, depth1, vlAlbedo, noise, NdotVoL, vl);
		#endif

		#ifdef OUTLINE_ENABLED
			color.rgb = mix(color.rgb, outerOutline.rgb, outerOutline.a);
		#endif

		/* RENDERTARGETS: 0,1 */
		gl_FragData[0] = vec4(color);
		gl_FragData[1] = vec4(vl, 1.0);

	}

#endif