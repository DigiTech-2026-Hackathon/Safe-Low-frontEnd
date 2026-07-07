/*#############################################
#    _   ___ _____ ___    _   _    _____  __  #
#   /_\ / __|_   _| _ \  /_\ | |  | __\ \/ /  #
#  / _ \\__ \ | | |   / / _ \| |__| _| >  <   #
# /_/ \_\___/ |_| |_|_\/_/ \_\____|___/_/\_\  #
#											  #
#############################################*/

//Settings//////////////////Settings///////////////////Settings///////////////////Settings//

//#define DEBUG_SKYTEXTURED

#include "/lib/util/functions.glsl"

#include "/settings/globalSettings.glsl"

//Varying////////////////////Varying////////////////////Varying////////////////////Varying//

#if (defined END || (defined OVERWORLD && VANILLA_SKYBOX > 0))
varying vec2 texCoord;
varying vec3 sunVec, upVec, uSunVec;
varying vec4 color;
#endif

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

	//Uniforms//
	#if (defined OVERWORLD && VANILLA_SKYBOX > 0)
		#if AA > 1
			uniform int frameCounter;
			uniform float viewWidth, viewHeight;
			#include "/lib/util/jitter.glsl"
		#endif
	#endif

	//Program//
	void main(){
		#if (defined END || (defined OVERWORLD && VANILLA_SKYBOX > 0))
			texCoord=(gl_TextureMatrix[0]*gl_MultiTexCoord0).xy;

			color=gl_Color;

			gl_Position=ftransform();
		#endif

		#if (defined OVERWORLD && VANILLA_SKYBOX > 0)
			upVec = normalize(gbufferModelView[1].xyz);
			uSunVec = GetuSunVec();
			sunVec = GetSunVec(uSunVec);

			#if AA > 1
				gl_Position.xy=TAAJitter(gl_Position.xy, gl_Position.w);
			#endif
		#else
				#if !defined END
					vec4 color = vec4(0.0);
					gl_Position = color;
				#endif
		#endif
	}

#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

	//Uniforms//
	uniform sampler2D noisetex;
	uniform float nightVision;
	uniform float rainFactor;
	uniform float screenBrightness;
	uniform float viewWidth, viewHeight;

	#ifdef UNDERGROUND_SKY
	uniform float isEyeInCave;
	#endif

	uniform ivec2 eyeBrightnessSmooth;

	uniform mat4 gbufferProjectionInverse;

	uniform vec3 skyColor;
	uniform vec3 fogColor;

	uniform sampler2D texture;
	uniform sampler2D gaux1;

	uniform vec3 cameraPosition;

	uniform mat4 gbufferModelViewInverse;

	uniform int renderStage;

	#ifndef MC_RENDER_STAGE_SUN
	#define MC_RENDER_STAGE_SUN 1
	#endif

	#ifndef MC_RENDER_STAGE_MOON
	#define MC_RENDER_STAGE_MOON 1
	#endif

	//Common Variables//

	#if (defined OVERWORLD && VANILLA_SKYBOX > 0)
	float eBS              =eyeBrightnessSmooth.y / 240.0;
	float sunVisibility    =clamp00125(dot( sunVec,upVec) + 0.0625) * 8.0;
	float moonVisibility   =clamp00125(dot( -sunVec,upVec) + 0.0625) * 8.0;
	#endif

	float screenBrightness2  = clamp01(screenBrightness);

	//Includes//

	#if (defined OVERWORLD && VANILLA_SKYBOX > 0)
		#include "/lib/color/lightColor.glsl"
	#endif

	//Program//
	void main(){

		#if (defined OVERWORLD && VANILLA_SKYBOX > 0)
			vec4 albedo    =texture2D(texture, texCoord.xy);
			vec4 screenPos =vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
			vec4 viewPos   =gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
			     viewPos  /=viewPos.w;

			vec3 nViewPos = normalize(viewPos.xyz);

				#ifdef HORIZON_SUN_MOON
					float NdotU = dot(nViewPos, upVec);

					#if MC_VERSION >= 11700
						if (renderStage > 3)
					#endif
					albedo.a *= clamp01((NdotU + 0.02) * 10.0);
				#endif

				albedo *= color;

				albedo.rgb = pow(albedo.rgb, vec3(2.2 + sunVisibility * 2.2)) * (1.0 + sunVisibility * 4.0) * SKYBOX_BRIGHTNESS * albedo.a;

				#if REALISTIC_CLOUDS == 1
					if (albedo.a > 0.0) {
						float cloudAlpha = texture2D(gaux1, gl_FragCoord.xy / vec2(viewWidth, viewHeight)).r;
						float alphaMult = 1.0 - 0.6 * rainFactor;
						albedo.a *= 1.0 - cloudAlpha / (alphaMult * alphaMult);
					}
				#endif

				#if ROUND_SUN_MOON > 0
					if (renderStage == MC_RENDER_STAGE_SUN || renderStage == MC_RENDER_STAGE_MOON) {
						albedo *= 0.0;
					}
				#endif

				#ifdef UNDERGROUND_SKY
					albedo.rgb *= 1.0 - isEyeInCave;
				#endif
		#else

			vec4 albedo = vec4(0.0);

		#endif

		/* RENDERTARGETS: 0 */

		#ifdef DEBUG_SKYTEXTURED
            gl_FragData[0]=vec4(0.0667, 0.0, 1.0, 0.75);
		#else
			gl_FragData[0]=clampVec4_01(albedo);
		#endif
	}

#endif