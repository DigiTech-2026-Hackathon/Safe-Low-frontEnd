/*#############################################
#    _   ___ _____ ___    _   _    _____  __  #
#   /_\ / __|_   _| _ \  /_\ | |  | __\ \/ /  #
#  / _ \\__ \ | | |   / / _ \| |__| _| >  <   #
# /_/ \_\___/ |_| |_|_\/_/ \_\____|___/_/\_\  #
#											  #
#############################################*/

//Settings//////////////////Settings///////////////////Settings///////////////////Settings//

//#define DEBUG_BASIC

#include "/lib/util/functions.glsl"

#include "/settings/globalSettings.glsl"

//Varying////////////////////Varying////////////////////Varying////////////////////Varying//
varying vec2 texCoord, lmCoord;
varying vec3 sunVec, upVec, uSunVec, eastVec, normal;
varying vec4 color;

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

	//Uniforms//

	#if defined GBUFFERS_LINE || AA > 1
	uniform float viewWidth, viewHeight;
	#endif

	#if defined GBUFFERS_LINE
	uniform float sneakSmooth;
	#endif

	#if MOUVEMENT_CAM > 0
	uniform float frameTimeCounter;
	uniform float onGroundSmooth;
	#endif

	uniform mat4 gbufferModelViewInverse;

	#if MC_VERSION >= 11700
		uniform int renderStage;
	#endif

	//Includes//
	#if AA > 1
		#include "/lib/util/jitter.glsl"
	#endif

	//Program//
	void main(){
		texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

		lmCoord  = GetLightMapCoordinates();

		normal=normalize(gl_NormalMatrix*gl_Normal);

		color=gl_Color;

		upVec = normalize(gbufferModelView[1].xyz);
		eastVec = normalize(gbufferModelView[0].xyz);
		uSunVec = GetuSunVec();
		sunVec = GetSunVec(uSunVec);

		#ifndef GBUFFERS_LINE

				gl_Position = ftransform();

			#if MOUVEMENT_CAM > 0
				gl_Position += vec4(0.03 * sin(frameTimeCounter * 3.0 * SPEED_MOOVE), 0.015 * cos(frameTimeCounter * 4.0 * SPEED_MOOVE), 0.0, 0.0) * gl_ProjectionMatrix * onGroundSmooth;
			#endif

		#else

			float lineWidth    = 3.0;
			vec2  screenSize   =vec2(viewWidth, viewHeight);

			float lineDepth    = THIRD_DIMENSION_SELECTION_BLOCK == 1 ? 0.2 : 1.0;

			float scaleValue   = THIRD_DIMENSION_SELECTION_BLOCK == 2 ? mix(1.0, 0.2, sneakSmooth) : lineDepth;
			mat4  VIEW_SCALE   = mat4(mat3(scaleValue - (1.0 / 256.0)));

				#ifdef WORLD_CURVATURE

					#if defined OVERWORLD
						float WCSize = OVERWORLD_CURVATURE_SIZE;
					#elif defined NETHER
						float WCSize = NETHER_CURVATURE_SIZE;
					#elif defined END
						float WCSize = END_CURVATURE_SIZE;
					#endif

					vec4 linePosStart     = gbufferModelViewInverse * (gl_ModelViewMatrix * vec4(gl_Vertex.xyz, 1.0));
					vec4 linePosEnd       = gbufferModelViewInverse * (gl_ModelViewMatrix * vec4(gl_Vertex.xyz + gl_Normal.xyz, 1.0));

					linePosStart.y       -= dot(linePosStart.xz, linePosStart.xz) / WCSize + 0.001;
					linePosEnd.y         -= dot(linePosEnd.xz, linePosEnd.xz) / WCSize + 0.001;

					linePosStart          = gbufferModelView * linePosStart;
					linePosEnd            = gbufferModelView * linePosEnd;

				#else

					vec4 linePosStart     = gl_ModelViewMatrix * vec4(gl_Vertex.xyz, 1.0);
					vec4 linePosEnd       = gl_ModelViewMatrix * vec4(gl_Vertex.xyz + gl_Normal.xyz, 1.0);
				#endif

						 linePosStart     = gl_ProjectionMatrix * VIEW_SCALE * vec4(linePosStart.xyz * 0.99609375, linePosStart.w);
						 linePosEnd       = gl_ProjectionMatrix * vec4(linePosEnd.xyz * 0.99609375, linePosEnd.w);

			vec3  ndc1                    = linePosStart.xyz / linePosStart.w;
			vec3  ndc2                    = linePosEnd.xyz / linePosEnd.w;
			vec2  lineScreenDirection     = normalize((ndc2.xy - ndc1.xy) * screenSize);
			vec2  lineOffset              = vec2(-lineScreenDirection.y, lineScreenDirection.x) * lineWidth / screenSize;

			if (lineOffset.x < 0.0){
				lineOffset   = -lineOffset;
			}

			if (gl_VertexID % 2 == 0){
				gl_Position  = vec4((ndc1 + vec3(lineOffset, 0.0)) * linePosStart.w, linePosStart.w);
			}else{
				gl_Position  = vec4((ndc1 - vec3(lineOffset, 0.0)) * linePosStart.w, linePosStart.w);
			}

			#if MOUVEMENT_CAM > 0
			gl_Position += vec4(0.03 * sin(frameTimeCounter * 3.0 * SPEED_MOOVE), 0.015 * cos(frameTimeCounter * 4.0 * SPEED_MOOVE), 0.0, 0.0) * gl_ProjectionMatrix * VIEW_SCALE * onGroundSmooth;
			#endif

		#endif

		#if AA > 1
			gl_Position.xy=TAAJitter(gl_Position.xy, gl_Position.w);
		#endif
	}

#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

	//Uniforms//
	uniform sampler2D noisetex;
	uniform int frameCounter;
	uniform int isEyeInWater;
	uniform int heldItemId;
	uniform int heldItemId2;
	uniform int moonPhase;
	#define UNIFORM_MOONPHASE

	uniform int heldBlockLightValue;
	uniform int heldBlockLightValue2;

	uniform float frameTimeCounter;
	uniform float nightVision;
	uniform float rainFactor;
	uniform float screenBrightness;
	uniform float far;
	uniform float viewWidth, viewHeight;

	#if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
		uniform float darknessFactor;
		uniform float darknessLightFactor;
	#endif

	uniform ivec2 eyeBrightnessSmooth;

	uniform vec3 cameraPosition;
	uniform vec3 fogColor;

	uniform mat4 gbufferProjectionInverse;
	uniform mat4 gbufferModelViewInverse;
	uniform mat4 shadowProjection;
	uniform mat4 shadowModelView;

	#if MC_VERSION >= 11700
		uniform int renderStage;
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
	#include "/lib/util/dither.glsl"
	#include "/lib/color/blocklightColor.glsl"
	#include "/lib/color/dimensionColor.glsl"
	#include "/lib/util/spaceConversion.glsl"

	#if (defined WATER_CAUSTICS && defined OVERWORLD)
	#include "/lib/color/waterColor.glsl"
	#endif

	#include "/lib/lighting/forwardLighting.glsl"

	#if COLOR_BLOC_SELECTOR > 0
	#include "/lib/color/selectionColor.glsl"
	#if COLOR_BLOC_SELECTOR > 1
	#include "/lib/color/hue.glsl"
	#endif
	#endif

	#if AA > 1
	#include "/lib/util/jitter.glsl"
	#endif

	//Program//
	void main(){
		vec4 albedo = color;

		if (albedo.a > 0.00001){

			vec2 lightmap = clampVec2_01(lmCoord);

			vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);

			#if AA > 1
				vec3 viewPos = ScreenToView(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
			#else
				vec3 viewPos = ScreenToView(screenPos);
			#endif

			vec3 worldPos = ViewToPlayer(viewPos);


			albedo.rgb = pow(albedo.rgb, vec3(2.2));
			albedo.a = albedo.a * 0.5 + 0.5;

			#ifdef WHITE_WORLD
				if (albedo.a > 0.9) albedo.rgb = vec3(0.5);
			#endif

			#ifdef BLACK_WORLD
				if (albedo.a > 0.9) albedo.rgb = vec3(0.0);
			#endif


			float NoL            =clamp01(dot(normal, lightVec) * 1.01 - 0.01);
			float NoU            =clampInv11(dot(normal, upVec));
			float NoE            =clampInv11(dot(normal, eastVec));
			float vanillaDiffuse =(0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
			      vanillaDiffuse*=vanillaDiffuse;

			vec3 shadow = vec3(0.0);
			#ifndef GBUFFERS_LINE
				GetLighting(albedo.rgb, shadow, viewPos, worldPos, lightmap, 1.0, NoL, vanillaDiffuse,
				1.0, 0.0, 0.0, true, true, false, true);
			#endif

			#if MC_VERSION >= 11700
				if (renderStage == 14) {
			#else
				if (albedo.rgb == vec3(0.0) && albedo.a > 0.5) {
			#endif

			#if COLOR_BLOC_SELECTOR == 0
				albedo.a = 1.0;

			#elif COLOR_BLOC_SELECTOR == 1
				if (albedo.rgb == vec3(0.0)) albedo.rgb = selectionCol;

			#elif COLOR_BLOC_SELECTOR == 2
				if (albedo.rgb == vec3(0.0)){
					albedo = clamp01(vec4(hue2(frameTimeCounter * RAINBOW_COLOR_BLOC_SELECTOR_SPEED ), 1.0));
					albedo = pow(albedo, vec4(2.2)) * COMPOSANTE_I * 0.5;
				}

			#elif COLOR_BLOC_SELECTOR == 3
				if (albedo.rgb == vec3(0.0)){
					float worldPosCBSA =worldPos.x + worldPos.y + worldPos.z;
					float cameraPosCBSA=cameraPosition.x + cameraPosition.y + cameraPosition.z;
					float finalPosCBSA =worldPosCBSA + cameraPosCBSA;
					      albedo       =clamp01(vec4(hue2(frameTimeCounter * HARLEQUIN_COLOR_BLOC_SELECTOR_SPEED + finalPosCBSA * CBSA_OBSTRUCTION), 1.0));
					      albedo       =pow(albedo, vec4(2.2)) * COMPOSANTE_I * 0.5;
				}
			#endif
			}

			}else discard;

		/* RENDERTARGETS: 0 */
		#ifdef DEBUG_BASIC
            gl_FragData[0]=vec4(1.0, 0.6, 0.0, 0.75);
		#else
			gl_FragData[0] = vec4(albedo);
		#endif

		#ifdef ADVANCED_MATERIALS
		/* RENDERTARGETS: 0,3,6,1 */
		gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);
		gl_FragData[2] = vec4(0.0, 0.0, float(gl_FragCoord.z < 1.0), 1.0);
		gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);
		#endif
	}

#endif