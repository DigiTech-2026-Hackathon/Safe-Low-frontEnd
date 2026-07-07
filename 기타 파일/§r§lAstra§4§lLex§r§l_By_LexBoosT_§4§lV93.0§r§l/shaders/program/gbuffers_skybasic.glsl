/*#############################################
#    _   ___ _____ ___    _   _    _____  __  #
#   /_\ / __|_   _| _ \  /_\ | |  | __\ \/ /  #
#  / _ \\__ \ | | |   / / _ \| |__| _| >  <   #
# /_/ \_\___/ |_| |_|_\/_/ \_\____|___/_/\_\  #
#											  #
#############################################*/

//Settings//////////////////Settings///////////////////Settings///////////////////Settings//

//#define DEBUG_SKYBASIC

#include "/lib/util/functions.glsl"

#include "/settings/globalSettings.glsl"

//Varying////////////////////Varying////////////////////Varying////////////////////Varying//
varying vec3 sunVec, upVec, uSunVec;

#if (defined OVERWORLD && ! defined NETHER && ! defined END)
varying mat3 moonRotMatrix;
#endif

#if ((defined OVERWORLD && ! defined NETHER && ! defined END)&&(defined PLANET ||defined PLANET2))
	varying mat3 planetRotMatrix;
#endif

#if ((defined OVERWORLD && ! defined NETHER && ! defined END)&& defined NEBULA)
	varying mat3 nebulaRotMatrix;
#endif

#if ((defined OVERWORLD && ! defined NETHER && ! defined END)&& defined GALAXY)
	varying mat3 galaxyRotMatrix;
#endif

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

	//Uniforms//
	uniform int frameCounter;

	//Includes//

	#include "/lib/util/moonrot.glsl"

	//Program//
	void main(){

		uSunVec = GetuSunVec();
		sunVec = GetSunVec(uSunVec);

		#if (defined OVERWORLD && !defined NETHER && !defined END)
			moonRotMatrix = getMoonRotMatrix(uSunVec);
		#endif

		#if ((defined OVERWORLD && !defined NETHER && !defined END) && (defined PLANET || defined PLANET2))
			planetRotMatrix = rotmat(PLANET_ROTX, PLANET_ROTY, PLANET_ROTZ);
		#endif

		#if ((defined OVERWORLD && !defined NETHER && !defined END) && defined NEBULA)
			nebulaRotMatrix = rotmat(NEBULA_ROTX, NEBULA_ROTY, NEBULA_ROTZ);
		#endif

		#if ((defined OVERWORLD && !defined NETHER && !defined END) && defined GALAXY)
			galaxyRotMatrix = rotmat(GALAXY_ROTX, GALAXY_ROTY, GALAXY_ROTZ);
		#endif

		upVec=normalize(gbufferModelView[1].xyz);

		gl_Position=ftransform();

		vec3 color = gl_Color.rgb;

	}

#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

	//Uniforms//
	uniform sampler2D noisetex;

	#if (defined PLANET ||defined PLANET2)
		uniform sampler2D colortex9;
	#endif

	#ifdef NEBULA
		uniform sampler2D colortex10;
	#endif

	#ifdef GALAXY
		uniform sampler2D colortex11;
	#endif

	uniform int frameCounter;
	uniform int isEyeInWater;
	uniform int moonPhase;
	#define UNIFORM_MOONPHASE

	uniform float blindFactor;
	uniform float frameTimeCounter;
	uniform float nightVision;
	uniform float rainStrength;
	uniform float rainFactor;

	#ifdef UNDERGROUND_SKY
	uniform float isEyeInCave;
	#endif

	uniform float screenBrightness;
	uniform float eyeAltitude;
	uniform float far;
	uniform float viewWidth, viewHeight;

	#ifndef WEATHER_PERBIOME
		uniform float isSnowy;
	#endif

	#if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
		uniform float darknessFactor;
	#endif

	uniform ivec2 eyeBrightnessSmooth;

	uniform mat4 gbufferModelView;
	uniform mat4 gbufferModelViewInverse;
	uniform mat4 gbufferProjectionInverse;
	uniform mat4 shadowProjection;
	uniform mat4 shadowModelView;


	uniform vec3 moonPosition;
	uniform vec3 cameraPosition;
	uniform vec3 skyColor;
	uniform vec3 fogColor;

	//Common Variables//
	float eBS              =eyeBrightnessSmooth.y / 240.0;
	float sunVisibility    =clamp00125(dot( sunVec,upVec) + 0.0625) * 8.0;
	float moonVisibility   =clamp00125(dot( -sunVec,upVec) + 0.0625) * 8.0;
	float screenBrightness2=clamp01(screenBrightness);

	vec3 lightVec = sunVec * (1.0 - 2.0 * float(timeAngle > 0.5325 && timeAngle < 0.9675));

	//Common Functions//

	float GetNoise(vec2 pos){
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.54953);
	}

	vec3 RoundSunMoon(vec3 nwpos, vec3 sunColor, vec3 moonColor, float NdotU, float VoL){

		const float sunSize = SUNSIZE * 0.333;

		float isMoon = float(VoL < 0.0);

		#ifdef REAL_SUNSIZE
			float sun = pow(abs(VoL), SUNSIZE * isMoon + sunSize * (1 - isMoon));
		#else
			float sun = pow(abs(VoL), SUNSIZE * isMoon + SUNSIZE * (1 - isMoon));
		#endif

		if (isMoon > 0.0) {
			if (moonPhase >= 1) {
				float moonPhaseOffset =float(!(moonPhase == 4));
				if    (moonPhase > 4) moonPhaseOffset *= -1.0;

				vec3 rawSunVec2       =normalize(vec3(0.0, -1.0, 0.0) + vec3(0.02, 0.0, 0.0) * moonPhaseOffset);
				float moonPhaseVoL    =dot(nwpos, normalize(rawSunVec2.xyz));
				      moonPhaseVoL    =pow(abs(moonPhaseVoL), SUNSIZE * 0.30);
				      sun             =mix(sun, 0.0, min(moonPhaseVoL * 3.0, 1.0));
			}
		}

		#ifdef HORIZON_SUN_MOON
			float horizonFactor = clamp01((NdotU + 0.0025) * 20.0);
			sun *= horizonFactor;
			moonColor *= 1.0 - sunVisibility;
			sunColor *= sunVisibility;
		#endif

		vec3 sunMoonCol=mix(moonColor * moonVisibility, sunColor * sunVisibility, float(VoL > 0.0));

		vec3 finalSunMoon=sun * sunMoonCol * 12.0;
		     finalSunMoon=pow(finalSunMoon, vec3(2.0 - min(finalSunMoon.r + finalSunMoon.g + finalSunMoon.b, SUN_MOON_FADING)));

			if (isMoon > 0.0) finalSunMoon = min(finalSunMoon, vec3(1.0));

		return finalSunMoon;
	}

	//Includes//

	#include "/lib/color/dimensionColor.glsl"
	#include "/lib/color/skyColor.glsl"
	#include "/lib/util/dither.glsl"

	#if (defined OVERWORLD && ! defined NETHER && ! defined END)
	#include "/lib/atmospherics/lunar.glsl"
	#endif

	#include "/lib/atmospherics/sky.glsl"
	#include "/lib/util/spaceConversion.glsl"

	#ifdef OVERWORLD

		#if REALISTIC_CLOUDS == 1
		#include "/lib/atmospherics/ovclouds.glsl"
		#endif

		#ifdef STARS
		#include "/lib/atmospherics/stars.glsl"
		#endif

		#ifdef SHININGSTARS
		#include "/lib/atmospherics/shiningstars.glsl"
		#endif

		#ifdef AURORA
		#if AURORA_COLOR == 5
		#include "/lib/color/hue.glsl"
		#endif
			#include "/lib/atmospherics/aurora.glsl"
		#endif

		#ifdef SHOOTING_STARS
		#include "/lib/atmospherics/shootingstars.glsl"
		#endif

		#if (ROUND_SUN_MOON > 0 || defined SUN_RAYS)
		#include "/lib/color/sunmoonColor.glsl"
		#include "/lib/atmospherics/sunrays.glsl"
		#endif

		#ifdef CHILD_BIRD_DRAWING
		#include "/lib/atmospherics/skyBirds.glsl"
		#endif

		#if (defined PLANET || defined PLANET2 || defined NEBULA || defined GALAXY)
		#include "/lib/atmospherics/skyimage.glsl"
		#endif

		#ifdef SUNGLARE
		#include "/lib/atmospherics/sunGlare.glsl"
		#endif

	#endif

	//Program//
	void main(){
		vec3 albedo = vec3(1.0);

		vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
		vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
		viewPos /= viewPos.w;

		vec4 cloud = vec4(1.0);
		vec3 worldPos = ViewToPlayer(viewPos.xyz);

		vec3 nViewPos = normalize(viewPos.xyz);
		float NdotU = dot(nViewPos, upVec);

		float cloudMask = 0.0;

		float dither = InterleavedGradientNoise();

		#ifdef OVERWORLD

			#if REALISTIC_CLOUDS == 1
			cloud = DrawCloud(viewPos.xyz, dither, lightCol, ambientCol, 10);
			cloudMask = min((cloud.a / (CLOUD_OPACITY * 2.20)), 0.25) + (cloud.a / (CLOUD_OPACITY * 2.20)) * 0.5;
			#endif

			albedo = GetSkyColor(viewPos.xyz,false);

			vec4 wpos = gbufferModelViewInverse * viewPos;
			wpos /= wpos.w;
			float alt = normalize(wpos.xyz).y;
			wpos.xyz = getLunarCoord(wpos.xyz);

			#ifdef WHITE_WORLD
				#ifdef SKYW
					albedo.rgb = vec3(0.5);
				#endif
			#endif

			#ifdef BLACK_WORLD
				#ifdef SKYW
					albedo.rgb = vec3(0.0);
				#endif
			#endif

			#if ROUND_SUN_MOON > 0
				vec3 sunColor = sunCol.rgb;
				vec3 moonColor = moonCol.rgb;
				vec3 nwpos = normalize(wpos.xyz);
				float VoL = dot(nwpos,vec3(0.0,-1.0,0.0));
				
				vec3 roundSunMoon = RoundSunMoon(nwpos, sunColor, moonColor, NdotU, VoL);
				#if REALISTIC_CLOUDS == 1
					roundSunMoon *= Max0(1.0 - cloudMask * (rainFactor + 1.0)) * (1.0 - rainFactor);
				#else
					roundSunMoon *= 1.0 - max(rainFactor, rainFactor);
				#endif

					albedo.rgb += mix(roundSunMoon * MOON_I, roundSunMoon * SUN_I, sunVisibility) * ROUND_SUN_MOON_GLOBAL_STRENGTH_COLOR;
			#endif

			#if (ROUND_SUN_MOON > 0 && defined SUN_RAYS)
				albedo.rgb = sunRays(albedo.rgb, worldPos, NdotU);
			#endif

			#if HORIZON_MIRROR_REFLECTION == 1
			float altfade = clamp01(alt/0.4 - 0.1);
			#else
			float altfade = clamp01(alt/0.4);
			#endif

			float altfadeShiningStar = alt/0.6 - 0.2;

			vec4 starcolor = vec4(albedo, 1.0);

			vec3 shiningStarColor = albedo.rgb;

			#ifdef NEBULA
				starcolor.rgb = drawNebulaImage(starcolor.rgb, vec2(0.2 * NEBULA_SIZE_X, 0.2 * NEBULA_SIZE_Y), wpos.xyz, colortex10, NEBULA_OPACITY);
			#endif

			#ifdef STARS
				vec3 starsAlbedo = starcolor.rgb;
				DrawStars(starsAlbedo.rgb, viewPos.xyz);
				starcolor.rgb = mix(starcolor.rgb, starsAlbedo, clamp01(1.0 - cloudMask * CLOUD_OPACITY * 2.2));
			#endif

			#ifdef SHININGSTARS
				if(alt > 0.0){
					vec3 shiningStarColor = DrawConstellations(starcolor.rgb, wpos.xyz, dither, 10.0);
					starcolor.rgb = mix(starcolor.rgb, shiningStarColor.rgb, altfadeShiningStar);
				}
			#endif

			#if (defined PLANET || defined PLANET2)
			starcolor.rgb = drawPlanetImage(starcolor.rgb,albedo.rgb, vec2(0.2 * PLANET_SIZE_X, 0.2 * PLANET_SIZE_Y), wpos.xyz, colortex9, PLANET_OPACITY);
			#endif

			#ifdef GALAXY
			if (moonVisibility > 0.0){
			starcolor.rgb = drawGalaxyImage(starcolor.rgb, vec2(0.2 * GALAXY_SIZE_X, 0.2 * GALAXY_SIZE_Y), wpos.xyz, colortex11, clamp01(1.0 - cloudMask * GALAXY_OPACITY * 2000.20));
			}
			#endif


			albedo.rgb = mix(albedo.rgb, clamp01(starcolor.rgb), (1.0-rainFactor) * altfade * clamp01(1.0 - cloudMask * CLOUD_OPACITY * 2.20));

			#ifdef AURORA
				if (moonVisibility > 0.0){

					albedo.rgb += clamp01((1.0 - cloudMask * CLOUD_OPACITY * 2.20) * DrawAurora(viewPos.xyz, dither, 30));
				}
			#endif

			#ifdef SHOOTING_STARS
				for (int i = 0; i < NUM_SHOOTING_STARS; i++) {
					float size = 1.0 + (i * 0.2);
					albedo.rgb = mix(albedo.rgb, DrawShootingStar(albedo.rgb, viewPos.xyz, size, dither), 1.0 - cloudMask);
				}
			#endif

			#if REALISTIC_CLOUDS == 1
				albedo.rgb = mix(albedo.rgb, cloud.rgb, cloud.a);
			#endif

			#ifdef SUNGLARE
				albedo.rgb  =SunGlare(albedo.rgb, nViewPos, lightColDay);
				albedo.rgb  =MoonGlare(albedo.rgb, nViewPos, lightColNight);
			#endif

			#ifdef CHILD_BIRD_DRAWING
				if (sunVisibility > 0.0){
					vec3 birdColor = albedo.rgb;
					#if NUMBER_OF_BIRDS == 1
					birdColor = drawBirdGroup(birdColor, worldPos, 1.27, 0.45, 1.0);
					birdColor = drawBirdGroup(birdColor, worldPos, - 0.81, 0.78, 1.5);
					#elif NUMBER_OF_BIRDS == 2
					birdColor = drawBirdGroup(birdColor, worldPos, 1.27, 0.45, 1.0);
					birdColor = drawBirdGroup(birdColor, worldPos, - 0.81, 0.78, 1.5);
					birdColor = drawBirdGroup(birdColor, worldPos, 0.97, 0.12, 0.8);
					#elif NUMBER_OF_BIRDS == 3
					birdColor = drawBirdGroup(birdColor, worldPos, 1.27, 0.45, 1.0);
					birdColor = drawBirdGroup(birdColor, worldPos, - 0.81, 0.78, 1.5);
					birdColor = drawBirdGroup(birdColor, worldPos, 0.97, 0.12, 0.8);
					birdColor = drawBirdGroup(birdColor, worldPos, - 1.14, 0.50, 1.1);
					#endif
					float sunsetFade = max(dayFactor + 0.1, (2.0 * sunVisibility));
					albedo.rgb =mix(albedo.rgb, birdColor, (1.0 - rainStrength) * sunsetFade);
				}
			#endif

			albedo.rgb *= 1.0 + nightVision;

			#ifdef CLASSIC_EXPOSURE
				albedo.rgb *= 4.0 - 3.0 * eBS;
			#endif

		#endif

		#ifdef UNDERGROUND_SKY
			albedo.rgb *= 1.0 - isEyeInCave;
		#endif

		#if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
			if (darknessFactor > 0.001) albedo.rgb = mix(albedo.rgb, darknessColor, darknessFactor);
		#endif

		/* RENDERTARGETS: 0 */
		#ifdef DEBUG_SKYBASIC
            gl_FragData[0]=vec4(1.0, 0.0, 0.5843, 0.75);
		#else
			gl_FragData[0] = vec4(albedo.rgb, 0.1);
		#endif

		#if (REALISTIC_CLOUDS == 1 && defined OVERWORLD)
		/* RENDERTARGETS: 0,4 */
		gl_FragData[1]=vec4(cloud.a, 0.0, 0.0, 0.0);
		#endif
	}

#endif