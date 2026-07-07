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
varying float mat;

varying vec2 texCoord;
varying vec3 sunVec, upVec;
varying vec4 color;
varying vec4 position;

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

	//Uniforms//
	uniform float frameTimeCounter;
	#if MOUVEMENT_CAM > 0
	uniform float onGroundSmooth;
	#endif

	uniform int frameCounter;

	uniform vec3 cameraPosition;

	uniform mat4 shadowProjection,shadowProjectionInverse;
	uniform mat4 shadowModelView,shadowModelViewInverse;

	//Attributes//
	attribute vec4 mc_Entity;
	attribute vec4 mc_midTexCoord;

	//Common Variables//

	vec2 lmCoord = vec2(0.0);

	float GetNoise(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.54953);
	}

	//Includes//
	#include "/lib/vertex/waving.glsl"

	#ifdef WORLD_CURVATURE
	#include "/lib/vertex/worldCurvature.glsl"
	#endif

	//Program//
	void main(){
		texCoord=gl_MultiTexCoord0.xy;
		color=gl_Color;

		lmCoord  = GetLightMapCoordinates();

		position = shadowModelViewInverse * shadowProjectionInverse * ftransform();

		mat=0;

		if (mc_Entity.x == 10303) {
		mat = 1;
		} else if (mc_Entity.x == 10300) {
		mat = 2;
		} else if (mc_Entity.x == 10302) {
		mat = 3;
		}

		float istopv      =gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1.0 : 0.0;
		      position.xyz=WavingBlocks(position.xyz, istopv);

		if (mc_Entity.x  == 10300) {
			position.y += 0.015 * Max0(length(position.xyz) - 50.0);
		}

		#ifdef WORLD_CURVATURE
			position.y -= WorldCurvature(position.xz);
		#endif

		#if MOUVEMENT_CAM > 0
			position += vec4(0.03 * sin(frameTimeCounter * 3.0 * SPEED_MOOVE), 0.015 * cos(frameTimeCounter * 4.0 * SPEED_MOOVE), 0.0, 0.0) * gbufferModelView * onGroundSmooth;
		#endif

		gl_Position=shadowProjection * shadowModelView * position;

		float dist         = sqrt(pow2(gl_Position.x) + pow2(gl_Position.y));
		float distortFactor= dist * shadowMapBias + (1.0 - shadowMapBias);

		gl_Position.xy *= 1.0 / distortFactor;
		gl_Position.z = gl_Position.z * 0.2;
	}
#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

	//Uniforms//
	uniform int frameCounter;
	uniform int isEyeInWater;
	uniform int blockEntityId;
	uniform int moonPhase;

	uniform vec3 fogColor;
	uniform vec3 cameraPosition;
	uniform ivec2 eyeBrightnessSmooth;

	uniform sampler2D tex;
	uniform sampler2D noisetex;

	uniform float rainFactor;
	uniform float frameTimeCounter;

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

	//Includes//

	#include "/lib/color/waterColor.glsl"
	#include "/lib/color/endColor.glsl"
	#include "/lib/util/dither.glsl"
	float sunVisibility    =clamp00125(dot( sunVec, upVec) + 0.0625) * 8.0;
	float moonVisibility   =clamp00125(dot( -sunVec, upVec) + 0.0625) * 8.0;
	float eBS              = clamp01((eyeBrightnessSmooth.y - 220) * 0.0666);

	#if ((defined WATER_CAUSTICS || defined PROJECTED_CAUSTICS) && defined OVERWORLD)
	#include "/lib/lighting/caustics.glsl"
	#endif

	//Common Functions//

	void doWaterShadowCaustics(float dither){

		#if ((defined WATER_CAUSTICS && defined COLORED_SHADOWS) && defined OVERWORLD)
		vec3  worldPos =position.xyz + cameraPosition.xyz;
		      worldPos *= 0.5;
		float noise     = 0.0;
		float mult      = 0.5;

		vec2  wind      =vec2(frameTimeCounter * 0.3);
		float verticalOffset = worldPos.y * 0.2;

		if(mult>0.01){
			const float numberRays = UNDERWATER_LIGHT_SHAFT_SIZE;
			float lacunarity = 1.0/numberRays, persistance = 1.0, weight = 0.0;

			for(int i=0;i<8;i++){
				float windSign   =mod(i,2) * 2.0 - 1.0;
				vec2  noiseCoord =worldPos.xz + wind * windSign - verticalOffset;
				if   (i<7)noise +=texture2D(noisetex, noiseCoord * lacunarity).r * persistance;
				else{
					      noise    +=texture2D(noisetex, noiseCoord * lacunarity * 0.125).r * persistance * 10.0;
					      noise     =-noise;
					float noisePlus =1.0 + 0.125 * -noise;
					      noisePlus*=noisePlus;
					      noisePlus*=noisePlus;
					      noise    *=noisePlus;
				}

				if(i==0)noise=-noise;

				weight      += persistance;
				lacunarity  *= 1.5;
				persistance *= 0.625;
			}
			noise*= mult / weight;
		}
			float noiseFactor = 1.1 + noise;
			      noiseFactor = pow(noiseFactor, 20.0);
		if (noiseFactor > 1.0 - dither * 0.5) discard;
		#else
		discard;
		#endif
	}

	//Program//
	void main(){
		if(blockEntityId == 10250) discard;

		vec4 albedo = texture2D(tex, texCoord.xy);
			 albedo.rgb*=color.rgb;

		if (blockEntityId == 10888) {
			if (color.r > 0.1) discard;
		}

		if (albedo.a < 0.0001) discard;

		float premult = float(mat > 0.95 && mat < 1.05);
		float water   = float(mat > 1.95 && mat < 2.05);
		float ice     = float(mat > 2.95 && mat < 3.05);

		#if (((defined OVERWORLD || defined END) && defined COLORED_SHADOWS) || (defined OVERWORLD && defined WATER_CAUSTICS) || ((defined OVERWORLD || defined END) && defined LIGHT_SHAFT))
			if (water > 0.5) {
				if (isEyeInWater < 0.5) {
					albedo.rgb = mix(vec3(1.0), albedo.rgb, pow(albedo.a, (1.0 - albedo.a) * 0.5) * 1.05);
					albedo.rgb *= 1.0 - pow(albedo.a, 64.0);
				} else {
					albedo.rgb *= 0.00001 - pow(albedo.a, 64.0);
					float dither = Bayer64(gl_FragCoord.xy);
						  dither = animateDither(dither);
					doWaterShadowCaustics(dither);
				}

			} else if (water < 0.5) {
				#if RP_COLORED_SHADOW_COMPATIBILITY == 1
					albedo.rgb = mix(vec3(1.0), albedo.rgb, pow(albedo.a, (1.0 - albedo.a) * 0.0001) * 1.5);
					albedo.rgb *= 1.0 - pow(albedo.a, 64.0);
				#else
					albedo.rgb = mix(vec3(1.0), albedo.rgb, pow(albedo.a, (1.0 - albedo.a) * 0.6) * 1.05);
					albedo.rgb *= 1.0 - pow(albedo.a, 64.0);
				#endif
			}
			if (ice > 0.5) {
				if (isEyeInWater < 0.5) {
					albedo.rgb = mix(vec3(1.0), albedo.rgb, pow(albedo.a, (1.0 - albedo.a) * 0.5) * 1.05);
					albedo.rgb *= 1.0 - pow(albedo.a, 64.0);
				} else {
					discard;
				}
			}
		#else
			if (water > 0.5) {
				if (isEyeInWater < 0.5) {
				} else {
					float dither = Bayer64(gl_FragCoord.xy);
						  dither = animateDither(dither);
					doWaterShadowCaustics(dither);
				}
			}

			if (premult > 0.5) {
				if (albedo.a < 0.51) discard;
			}
		#endif

		#if (defined PROJECTED_CAUSTICS && defined OVERWORLD)
			if (water > 0.5) {
				vec3 worldPos = position.xyz + cameraPosition.xyz;

				#if WATER_MODE < 2
				vec3 causticsColor = (waterColorSqrt.rgb + vec3(0.01));
				#else
				vec3 causticsColor = (vanillaWaterColorAbs.rgb * vanillaWaterColorAbs.rgb + vec3(0.01));
				#endif

				float caustics = getProjectedCausticWaves(worldPos);
				albedo.rgb *= caustics;
				albedo.rgb *= Max0(causticsColor);
			}
		#endif

			gl_FragData[0] = clampVec4_01(albedo);
	}

#endif