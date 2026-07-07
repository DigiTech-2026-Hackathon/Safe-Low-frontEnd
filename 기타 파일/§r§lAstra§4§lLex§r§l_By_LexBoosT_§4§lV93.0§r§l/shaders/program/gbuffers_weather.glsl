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
varying vec2 texCoord, lmCoord;
varying vec3 sunVec, upVec, uSunVec;
varying vec4 color;

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

	//Uniforms//
	#if NOUVELLE_PLUIE > 0
		uniform vec3 cameraPosition;
	#endif

	uniform mat4 gbufferModelViewInverse;
	uniform float frameTimeCounter;
	#if MOUVEMENT_CAM > 0
	uniform float onGroundSmooth;
	#endif

	#if NOUVELLE_PLUIE > 0
		uniform float biomeHasNoSnow;
	#endif

	#if AA > 1
	uniform float viewWidth,viewHeight;
	uniform int frameCounter;
	#include "/lib/util/jitter.glsl"
	#endif

	//Program//
	void main(){

		vec4 position=gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

		#if NOUVELLE_PLUIE > 0
			vec3 worldpos            =position.xyz + cameraPosition;
			bool istopv              =worldpos.y > cameraPosition.y + 5.0;
			float notColdSmooth 	 =biomeHasNoSnow;
			float frameTimeCounter2  =frameTimeCounter * 2.0;

			if  (!istopv)
				#if NOUVELLE_PLUIE == 1
					position.xz        += vec2(0.2, 0.2) + pow3(sin(frameTimeCounter2)) * vec2(0.1, 0.1) * notColdSmooth;
					position.xz        -=(vec2(0.3, 0.2) + pow3(sin(frameTimeCounter2)) * vec2(0.2, 0.1)) * 0.10 * notColdSmooth;
					position.xz        -=(vec2(0.4, 0.2) + pow3(sin(frameTimeCounter2)) * vec2(0.3, 0.1)) * 0.08 * notColdSmooth;
					position.xz        -=(vec2(0.5, 0.2) + pow3(sin(frameTimeCounter2)) * vec2(0.4, 0.1)) * 0.06 * notColdSmooth;
				#elif NOUVELLE_PLUIE == 2
					position.xz		   += vec2(3.5, 1.0) * notColdSmooth;
				#endif
		#endif

		texCoord=(gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

		lmCoord  = GetLightMapCoordinates();

		upVec = normalize(gbufferModelView[1].xyz);
		uSunVec = GetuSunVec();
		sunVec = GetSunVec(uSunVec);

		gl_Position=gl_ProjectionMatrix * gbufferModelView * position;

		color = gl_Color;

		#if MOUVEMENT_CAM > 0
			gl_Position += vec4(0.03 * sin(frameTimeCounter * 3.0 * SPEED_MOOVE), 0.015 * cos(frameTimeCounter * 4.0 * SPEED_MOOVE), 0.0, 0.0) * gl_ProjectionMatrix * onGroundSmooth;
		#endif

		#if AA > 1
			gl_Position.xy=TAAJitter(gl_Position.xy,gl_Position.w);
		#endif
	}

#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

	//Uniforms//
	#if AA > 1
	uniform int frameCounter;
	#endif

	uniform float rainFactor;
	uniform float nightVision;

	uniform float screenBrightness;
	uniform float viewWidth, viewHeight;

	#if (defined WEATHER_DYNAMIC_HAND_LIGHT && defined DYNAMIC_HAND_LIGHT && defined OVERWORLD)
	uniform int heldItemId, heldItemId2;
	uniform int heldBlockLightValue;
	uniform int heldBlockLightValue2;
	#include "/settings/color/handlightColorSettings.glsl"
	#include "/lib/lighting/colorLighting.glsl"
	#endif

	uniform mat4 gbufferModelViewInverse;
	uniform mat4 shadowProjection;
	uniform mat4 shadowModelView;

	uniform int moonPhase;
	#define UNIFORM_MOONPHASE

	uniform int isEyeInWater;

	uniform ivec2 eyeBrightnessSmooth;

	uniform mat4 gbufferProjectionInverse;

	uniform sampler2D texture;

	//Common Variables//
	float eBS              =eyeBrightnessSmooth.y / 240.0;
	float sunVisibility    =clamp00125(dot( sunVec,upVec) + 0.0625) * 8.0;
	float moonVisibility   =clamp00125(dot( -sunVec,upVec) + 0.0625) * 8.0;
	float screenBrightness2=clamp01(screenBrightness);

	//Includes//
	#include "/lib/color/lightColor.glsl"
	#include "/lib/color/blocklightColor.glsl"

	#if AA > 1
	#include "/lib/util/jitter.glsl"
	#endif

	#include "/lib/util/spaceConversion.glsl"

	//Program//
	void main(){
		#if (defined NETHER || defined END)
		discard;
		#endif

		vec4 albedo = texture2D(texture, texCoord.xy);
		vec2 lightmap = lmCoord;

		if (albedo.a < 0.1 || isEyeInWater == 3) discard;

			#if (defined WEATHER && defined OVERWORLD)
			 	albedo.a = texture2D(texture, texCoord).a;
				lightmap.x = Max0(lightmap.x * lightmap.y - 0.15);


			if (albedo.a > 0.0){
				vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);

				#if AA > 1
					vec3 viewPos = ScreenToView(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
				#else
					vec3 viewPos = ScreenToView(screenPos);
				#endif

				vec3 nViewPos		    =normalize(viewPos);
				vec3 worldPos           =ViewToPlayer(nViewPos);
				float lViewPos          =length(viewPos.xyz);
				float torchDist         =length(worldPos);
				float handTorchLightmap2=0.0;
				vec3  handLightCol      =vec3(0.1);

				#if defined WEATHER_DYNAMIC_HAND_LIGHT && defined DYNAMIC_HAND_LIGHT
					float heldLightValue = max(float(heldBlockLightValue), float(heldBlockLightValue2));
					float handlight = clamp((heldLightValue - 2.0 * lViewPos) * 0.04, 0.0, 0.9333);
					lightmap.x = max(lightmap.x, handlight);

					if (isLightHandled()){

					handTorchLightmap2 = clamp01(1.0 - ((DIST_DECLINE * 2.0 - DIST_MAX_LIGHT * 8.0) / (torchDist - DIST_MAX_LIGHT * 8.0))) * 0.33;

					#ifdef COLORED_DYNAMIC_HAND_LIGHT
						changeLightingColorByHand(handLightCol);
					#endif
					}
				#endif

				albedo.a *= 0.25 * rainFactor * length(albedo.rgb * 0.125) * float(albedo.a > 0.1);

				#if CUSTOM_RAIN_SNOW_COLORING == 1
					albedo.rgb *= (finalRainSnowCol.rgb + pow2(lightmap.x) * (blocklightCol * mix(5.0, 10.0, moonVisibility)) + ((pow2(handLightCol) * mix(3.0, 4.0, moonVisibility)) * handTorchLightmap2)) * (WEATHER_OPACITY * mix(2.0, 0.2, moonVisibility));
				#else
					albedo.rgb *= (ambientCol2 + pow2(lightmap.x) * (blocklightCol * mix(4.0, 2.0, moonVisibility)) + ((handLightCol * mix(1.0, 0.5, moonVisibility)) * handTorchLightmap2)) * WEATHER_OPACITY;
				#endif
			}
			#endif

		/* RENDERTARGETS: 0 */
		gl_FragData[0] = vec4(albedo);
	}

#endif