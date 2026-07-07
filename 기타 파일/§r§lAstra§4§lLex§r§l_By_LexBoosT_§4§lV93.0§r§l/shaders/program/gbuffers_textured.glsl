/*#############################################
#    _   ___ _____ ___    _   _    _____  __  #
#   /_\ / __|_   _| _ \  /_\ | |  | __\ \/ /  #
#  / _ \\__ \ | | |   / / _ \| |__| _| >  <   #
# /_/ \_\___/ |_| |_|_\/_/ \_\____|___/_/\_\  #
#											  #
#############################################*/

//Settings//////////////////Settings///////////////////Settings///////////////////Settings//

//#define DEBUG_TEXTURED

#include "/lib/util/functions.glsl"

#include "/settings/globalSettings.glsl"

//Varying////////////////////Varying////////////////////Varying////////////////////Varying//

#if !defined OUTLINE_TRIPWIRE
varying float isTripwire;
#endif

varying vec2 texCoord, lmCoord;
varying vec3 sunVec, upVec, uSunVec, eastVec, normal;
varying vec4 color;

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

	//Uniforms//

	#if AA > 1
		uniform int frameCounter;
		uniform float viewWidth,viewHeight;
	#endif

	#if MOUVEMENT_CAM > 0
		uniform float frameTimeCounter;
		uniform float onGroundSmooth;
	#endif
	uniform vec3 cameraPosition;

	uniform mat4 gbufferModelViewInverse;

	//Attributes//
	attribute vec4 mc_Entity;

	//Includes//
	#if AA > 1
	#include "/lib/util/jitter.glsl"
	#endif

	#ifdef WORLD_CURVATURE
	#include "/lib/vertex/worldCurvature.glsl"
	#endif

	//Program//
	void main(){
		texCoord=(gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

		lmCoord  = GetLightMapCoordinates();

		normal=normalize(gl_NormalMatrix * gl_Normal);

		color=gl_Color;

		upVec = normalize(gbufferModelView[1].xyz);
		eastVec = normalize(gbufferModelView[0].xyz);
		uSunVec = GetuSunVec();
		sunVec = GetSunVec(uSunVec);

		#ifdef WORLD_CURVATURE
		vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
			 position.y -= WorldCurvature(position.xz);
			gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
		#else
			gl_Position = ftransform();
		#endif

		#if !defined OUTLINE_TRIPWIRE
			isTripwire = 0.0;
		#endif

		/*
		Tripwire
		*/

		if (mc_Entity.x == 11008){
		#ifdef INVISIBLE_TRIPWIRE
			color.a = 0.0;
		#else
			color.a = 1.0;
		#endif
		}

		/*
		Skulk
		*/

		#if !defined OUTLINE_TRIPWIRE
		if (mc_Entity.x == 11008)
				lmCoord.x *= 0.9, isTripwire = 1.0, color.a;
		#else
		if (mc_Entity.x == 11008)
				lmCoord.x *= 0.9, color.a;
		#endif

		#if MOUVEMENT_CAM > 0
			gl_Position += vec4(0.03 * sin(frameTimeCounter * 3.0 * SPEED_MOOVE), 0.015 * cos(frameTimeCounter * 4.0 * SPEED_MOOVE), 0.0, 0.0) * gl_ProjectionMatrix * onGroundSmooth;
		#endif

		#if AA > 1
			gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
		#endif

		gl_Position.z -= 0.000002;
	}

#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

	//Uniforms//
	uniform int frameCounter;
	uniform int isEyeInWater;
	uniform int heldItemId;
	uniform int heldItemId2;

	uniform int heldBlockLightValue;
	uniform int heldBlockLightValue2;

	uniform float far, near;
	uniform float frameTimeCounter;
	uniform float blindFactor, darknessFactor, nightVision;
	uniform float rainStrength;
	uniform float rainFactor;
	uniform float screenBrightness;
	uniform float viewWidth, viewHeight;

	#ifdef UNDERGROUND_SKY
	uniform float isEyeInCave;
	#endif

	uniform ivec2 eyeBrightnessSmooth;

	uniform ivec2 atlasSize;

	uniform sampler2D noisetex;

	uniform vec3 cameraPosition;

	uniform vec3 skyColor;
	uniform vec3 fogColor;

	uniform mat4 gbufferProjectionInverse;
	uniform mat4 gbufferModelViewInverse;
	uniform mat4 shadowProjection;
	uniform mat4 shadowModelView;

	uniform sampler2D texture;

	#if MC_VERSION >= 11700
		uniform ivec4 blendFunc;
	#endif

	#if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
		uniform float darknessLightFactor;
	#endif

	//Common Variables//
	float eBS              =eyeBrightnessSmooth.y / 240.0;
	float sunVisibility    =clamp00125(dot( sunVec,upVec) + 0.0625) * 8.0;
	float moonVisibility   =clamp00125(dot( -sunVec,upVec) + 0.0625) * 8.0;
	float screenBrightness2=clamp01(screenBrightness);

	#ifdef OVERWORLD
		vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
	#else
		vec3 lightVec = sunVec;
	#endif

	//Includes//
	#if (defined NETHER || defined END)
		#include "/lib/color/lightColor.glsl"
	#endif

	#include "/lib/color/blocklightColor.glsl"
	#include "/lib/color/dimensionColor.glsl"
	#include "/lib/color/skyColor.glsl"
	#include "/lib/color/waterColor.glsl"
	#include "/lib/util/dither.glsl"
	#include "/lib/atmospherics/waterFog.glsl"
	#include "/lib/util/spaceConversion.glsl"
	#include "/lib/atmospherics/sky.glsl"
	#include "/lib/atmospherics/fog.glsl"
	#include "/lib/lighting/forwardLighting.glsl"

	#if (defined WATER_CAUSTICS && defined OVERWORLD)
	#include "/lib/lighting/caustics.glsl"
	#endif

	#if AA > 1
	#include "/lib/util/jitter.glsl"
	#endif

	//Program//
	void main(){
		vec4 albedo = vec4(0.0);
		vec4 albedoT = texture2D(texture, texCoord);
			 albedo = albedoT * color;
		vec3 vlAlbedo = vec3(1.0);
		float emission = 0.0;
		bool coloredHandlight = true;

		if (albedo.a > 0.0){
			vec2 lightmap=clampVec2_01(lmCoord);

			vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
			#if AA > 1
				vec3 viewPos = ScreenToView(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
			#else
				vec3 viewPos = ScreenToView(screenPos);
			#endif

			vec3  worldPos =ViewToPlayer(viewPos);
			float lViewPos =length(viewPos);

			#if MC_VERSION >= 11700
				if (blendFunc == ivec4(770, 1, 1, 0)) {
					albedo.a = albedoT.a * color.a * 0.2;
					lightmap = vec2(1.0);
				}
			#endif

			albedo.rgb = pow(albedo.rgb, vec3(2.2));

			#ifdef WHITE_WORLD
				#ifdef TEXTURESW
					albedo.rgb = vec3(0.5);
				#endif
			#endif

			#ifdef BLACK_WORLD
				#ifdef TEXTURESW
					albedo.rgb = vec3(0.0);
				#endif
			#endif

			float NoL            = 1.0;
			float NoU            = clampInv11(dot(normal, upVec));
			float NoE            = clampInv11(dot(normal, eastVec));
			float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
			      vanillaDiffuse*= vanillaDiffuse;

			if (atlasSize.x < 900.0) {

				float lAlbedo = length(albedo.rgb);

				#if defined(PURPLE_PARTICLES_EMISSIVE)
				/*
				Grayscale Particles
				*/
				if (max(abs(albedoT.r - albedoT.b), abs(albedoT.b - albedoT.g)) < 0.0001) {

					/*
					Ender Particle / Crying Obsidian Drop
					*/
					if (lAlbedo > 0.5 && color.g < 0.5 && color.b > color.r * 1.1 && color.r > 0.3)
					emission = max(pow2(albedo.r), 0.1);

				}
				#endif

				if (color.a < 0.99 && lAlbedo < 1.0) // Campfire Smoke, World Border
					albedo.a *= 0.5;

				if (lAlbedo > 0.5 && color.g > 0.5) // Sneeze
					albedo.a *= 2.5;

				#if RED_PARTICLES_EMISSIVE == 1
					/*
					Redstone Particles / Heart Particles
					*/
					if ((color.g + color.b < 0.5) && color.r > (color.g + color.b))
						lightmap = vec2(0.75), albedo.r *= max(pow2(albedo.r), 1.0), emission = max(pow2(albedo.r), 0.1);
				#elif RED_PARTICLES_EMISSIVE == 0
					/*
					Redstone Particles
					*/
					if (lAlbedo > 0.5 && color.g < 0.5 && color.r > (color.g + color.b) * 3.0)
					lightmap = vec2(0.75), emission = max(pow2(albedo.r), 0.1);
				#else
				#endif
				coloredHandlight = false;
			}

			vec3 shadow = vec3(0.0);

			GetLighting(albedo.rgb, shadow, viewPos, worldPos, lightmap, 1.0, NoL, 1.0,
			1.0, clamp01(emission), 0.0, false, true, coloredHandlight, true);

			albedo.rgb *= 1.25;

			#if defined(FOG)
			vlAlbedo = mix(vec3(1.0), albedo.rgb, sqrt1(albedo.a)) * (1.0 - pow(albedo.a, 64.0));
			if (atlasSize.x > 5.0) {
				albedo.rgb = Fog(albedo.rgb, viewPos);
			}
			#endif

			#if (defined WATER_CAUSTICS && defined OVERWORLD)
				#include "/lib/lighting/causticsCall.glsl"
			#endif

		}else discard;

		/* RENDERTARGETS: 0,1,7 */
		#ifdef DEBUG_TEXTURED
            gl_FragData[0]=vec4(0.0353, 1.0, 0.0, 0.75);
		#else
			gl_FragData[0] = vec4(albedo);
		#endif

		gl_FragData[1] = vec4(vlAlbedo, 1.0);
		gl_FragData[2] = vec4(1.0, 1.0, 1.0, 1.0);

		#if !defined OUTLINE_TRIPWIRE
		/* RENDERTARGETS: 0,1,7,8 */
		gl_FragData[3] = vec4(0.0, isTripwire, 0.0, 1.0);
		#endif
	}

#endif