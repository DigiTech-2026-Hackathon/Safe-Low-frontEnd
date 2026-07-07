/*#############################################
#    _   ___ _____ ___    _   _    _____  __  #
#   /_\ / __|_   _| _ \  /_\ | |  | __\ \/ /  #
#  / _ \\__ \ | | |   / / _ \| |__| _| >  <   #
# /_/ \_\___/ |_| |_|_\/_/ \_\____|___/_/\_\  #
#											  #
#############################################*/

//Settings//////////////////Settings///////////////////Settings///////////////////Settings//

//#define DEBUG_WATER

#include "/lib/util/functions.glsl"

#include "/settings/globalSettings.glsl"
#include "/settings/color/waterColorSettings.glsl"

//Varying////////////////////Varying////////////////////Varying////////////////////Varying//
varying float mat, dist, isWater;

varying vec2 texCoord, lmCoord;
varying vec3 sunVec, upVec, uSunVec, eastVec, normal, binormal, tangent, viewVector;
varying vec4 color;

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

#if (defined ADVANCED_MATERIALS || defined NEW_NETHER_PORTAL)
varying vec4 vTexCoord, vTexCoordAM;
#endif

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

	//Uniforms//
	uniform float frameTimeCounter;
	#if MOUVEMENT_CAM > 0
	uniform float onGroundSmooth;
	#endif
	uniform vec3 cameraPosition;

	uniform mat4 gbufferModelViewInverse;

	#if AA > 1
		uniform int frameCounter;
		uniform float viewWidth,viewHeight;
	#endif

	//Attributes//
	attribute vec4 mc_Entity;
	attribute vec4 mc_midTexCoord;
	attribute vec4 at_tangent;

	//Common Functions//
	float WavingWater(vec3 worldPos){
		float fractY=fract(worldPos.y + cameraPosition.y + 0.005);

		float wave=sin(TAU * (frameTimeCounter * 0.7 + worldPos.x * 0.14 + worldPos.z * 0.07))+
					sin(TAU * (frameTimeCounter * 0.5 + worldPos.x * 0.10 + worldPos.z * 0.20));
		if(fractY > 0.01) return wave * 0.0125;

		return 0.0;
	}

	//Includes//
	#include "/lib/util/moonrot.glsl"

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
		lmCoord  = clampVec2_01(lmCoord);

		normal  =normalize(gl_NormalMatrix * gl_Normal);
		binormal=normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
		tangent =normalize(gl_NormalMatrix * at_tangent.xyz);

		mat3 tbnMatrix=mat3(tangent.x,binormal.x,normal.x,
							tangent.y,binormal.y,normal.y,
							tangent.z,binormal.z,normal.z);

		viewVector=tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;

		dist=length(gl_ModelViewMatrix * gl_Vertex);

		#if (defined ADVANCED_MATERIALS || NEW_NETHER_PORTAL > 0)
		vec2 midCoord=(gl_TextureMatrix[0] * mc_midTexCoord).xy;
		vec2 texMinMidCoord=texCoord - midCoord;

		vTexCoordAM.zw=abs(texMinMidCoord) * 2;
		vTexCoordAM.xy=min(texCoord, midCoord - texMinMidCoord);

		vTexCoord.xy=sign(texMinMidCoord) * 0.5 + 0.5;
		#endif

		color=gl_Color;

		if(color.a < 0.1) color.a = 1.0;

		mat= 0.0;
		isWater = 0.0;

		if (mc_Entity.x == 10300){//Water Block
			mat = 1.0, isWater = 1.0;
		} else if (mc_Entity.x == 10303){//Stained_glass / Stained_glass_pane
			mat = 2.0;
		} else if (mc_Entity.x == 10304){//Tinted_glass
			mat = 3.0;
		} else if (mc_Entity.x == 10302){//Ice Block
			mat = 4.0;
		}

		/*////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////NETHER_PORTAL//////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////////////*/
		#if NEW_NETHER_PORTAL > 0
			float matEmissive = 5.0;
		#else
			float matEmissive = 2.0;
		#endif

		#ifdef OVERWORLD
			// Nether Portal
			if (mc_Entity.x == 10223){
				mat=matEmissive, color.a *= 1.0;
			}
		#endif

		#ifdef NETHER
			// Nether Portal
			if (mc_Entity.x == 10223){
				mat=matEmissive, color.a *= 1.0;
			}
		#endif

		#ifdef END
			// Nether Portal
			if (mc_Entity.x == 10223){
				mat=matEmissive, color.a *= 1.0;
			}
		#endif
		/*////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////NETHER_PORTAL//////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////////////*/

		uSunVec = GetuSunVec();
		sunVec = GetSunVec(uSunVec);
		upVec  =normalize(gbufferModelView[1].xyz);
		eastVec=normalize(gbufferModelView[0].xyz);

		#if (defined OVERWORLD && !defined NETHER && !defined END)
			moonRotMatrix=getMoonRotMatrix(uSunVec);
		#endif

		#if ((defined OVERWORLD && !defined NETHER && !defined END)&&(defined PLANET || defined PLANET2))
			float planetRotz =0.0;

			#if defined (PLANET)
				planetRotz = PLANET_ROTZ;
			#elif defined (PLANET2)
				planetRotz = PLANET_ROTZ + 45;
			#endif

			planetRotMatrix=rotmat(PLANET_ROTX, PLANET_ROTY, planetRotz);
		#endif

		#if ((defined OVERWORLD && !defined NETHER && !defined END)&& defined NEBULA)
			nebulaRotMatrix=rotmat(NEBULA_ROTX, NEBULA_ROTY, NEBULA_ROTZ);
		#endif

		#if ((defined OVERWORLD && !defined NETHER && !defined END)&& defined GALAXY)
			galaxyRotMatrix=rotmat(GALAXY_ROTX, GALAXY_ROTY, GALAXY_ROTZ);
		#endif

		vec4 position=gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

		#ifdef WAVING_WATER
			float istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1.0 : 0.0;
			if (mc_Entity.x == 10300) position.y += WavingWater(position.xyz);
		#endif

		#ifdef WORLD_CURVATURE
			position.y -= WorldCurvature(position.xz);
    	#endif

		gl_Position=gl_ProjectionMatrix*gbufferModelView*position;

		if (mat == 0.0) {
			gl_Position.z-=0.00001;
			lmCoord       =(lmCoord - 0.03125) * 1.06667;
		} else {
			lmCoord.y=(lmCoord.y - 0.03125) * 1.06667;
			lmCoord.x=smoothstep(0.0, 1.0, pow((lmCoord.x - 0.03125) * 0.55, 0.35));
		}

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
	uniform int frameCounter;
	uniform int isEyeInWater;
	uniform int heldItemId, heldItemId2;
	uniform int moonPhase;
	#define UNIFORM_MOONPHASE

	uniform int heldBlockLightValue;
	uniform int heldBlockLightValue2;

	#ifndef WEATHER_PERBIOME
		uniform float isSnowy;
	#endif

	uniform float blindFactor, darknessFactor, nightVision;
	uniform float far, near;
	uniform float frameTimeCounter;
	uniform float rainStrength;
	uniform float rainFactor;

	uniform float isEyeInCave;

	uniform float screenBrightness;
	uniform float viewWidth, viewHeight;
	uniform float eyeAltitude;

	uniform ivec2 eyeBrightnessSmooth;

	uniform vec3 moonPosition;
	uniform vec3 cameraPosition, previousCameraPosition;
	uniform vec3 skyColor;
	uniform vec3 fogColor;

	uniform mat4 gbufferProjection, gbufferPreviousProjection, gbufferProjectionInverse;
	uniform mat4 gbufferModelView, gbufferPreviousModelView, gbufferModelViewInverse;
	uniform mat4 shadowProjection;
	uniform mat4 shadowModelView;

	uniform sampler2D texture;
	uniform sampler2D gaux2;
	uniform sampler2D depthtex1;
	uniform sampler2D depthtex2;
	uniform sampler2D noisetex;

	#if (defined PLANET || defined PLANET2)
		uniform sampler2D colortex9;
	#endif

	#ifdef NEBULA
		uniform sampler2D colortex10;
	#endif

	#ifdef GALAXY
		uniform sampler2D colortex11;
	#endif

	#ifdef ADVANCED_MATERIALS
		uniform ivec2 atlasSize;
		uniform sampler2D specular;
		uniform sampler2D normals;

		#ifdef REFLECTION_RAIN
			uniform float wetness;
		#endif
	#endif

	#if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
		uniform float darknessLightFactor;
	#endif

	//Common Variables//
	float eBS = eyeBrightnessSmooth.y / 240.0;
	float sunVisibility  = clamp00125(dot( sunVec,upVec) + 0.0625) * 8.0;
	float moonVisibility = clamp00125(dot( -sunVec,upVec) + 0.0625) * 8.0;
	float screenBrightness2 = clamp01(screenBrightness);

	float smoothness = 0.0;

	#ifdef ADVANCED_MATERIALS
		vec2 dcdx = dFdx(texCoord);
		vec2 dcdy = dFdy(texCoord);
	#endif

	#ifdef OVERWORLD
		vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
	#else
		vec3 lightVec = sunVec;
	#endif

	//Common Functions//

	float GetNoise(vec2 pos){
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.54953);
	}

	#include "/lib/surface/water.glsl"

	float getDayNightCaveValue(float dayValue, float nightValue, float caveValue){
    	return mix(mix(dayValue, nightValue, moonVisibility), caveValue, 1.0 - eBS);
	}

	float WaterOp(float alpha, float difOP, float fresnel, float lViewPos) {

	float waterFogDistanceDay = 1.0 - min(difOP / WATER_A, 0.25);
	float waterFogDistanceNight = 1.0 - min(difOP / WATER_A, 0.75);
	float waterFogDistanceCave = 1.0 - min(difOP / WATER_A, 0.5);

	float waterFogDistance = getDayNightCaveValue(waterFogDistanceDay, waterFogDistanceNight, waterFogDistanceCave);
		  waterFogDistance *= waterFogDistance;

	alpha = mix(0.97, alpha, min(waterFogDistance, 1.0 - fresnel));

	alpha = max(min(sqrt(lViewPos) * 0.075, 0.9), alpha);

	alpha = min(alpha, 1.0 - nightVision * 0.2);

	return alpha;
	}

	//Includes//
	#if (defined OVERWORLD && !defined NETHER && !defined END)
	#include "/lib/atmospherics/lunar.glsl"
	#endif

	#include "/lib/atmospherics/skyimage.glsl"
	#include "/lib/color/blocklightColor.glsl"
	#include "/lib/color/dimensionColor.glsl"
	#include "/lib/color/skyColor.glsl"
	#include "/lib/color/specularColor.glsl"
	#include "/lib/color/waterColor.glsl"
	#include "/lib/util/dither.glsl"
	#include "/lib/atmospherics/waterFog.glsl"
	#include "/lib/util/spaceConversion.glsl"

	#ifdef OVERWORLD
		#if REALISTIC_CLOUDS == 1
		#include "/lib/atmospherics/ovclouds.glsl"
		#endif

		#ifdef SHININGSTARS
		#include "/lib/atmospherics/shiningstars.glsl"
		#endif

		#ifdef STARS
		#include "/lib/atmospherics/stars.glsl"
		#endif
	#endif

	#if (defined OVERWORLD || defined END)
	#include "/lib/atmospherics/sky.glsl"
	#endif

	#if defined (END)
	#include "/lib/color/lightColor.glsl"
	#endif

	#if ((defined END_AURORA_REF && defined AURORA_END && defined END)||(defined AURORA && defined AURORA_REFLECTION && defined OVERWORLD))
	#if AURORA_COLOR == 5
	#include "/lib/color/hue.glsl"
	#endif
	#include "/lib/atmospherics/aurora.glsl"
	#endif

	#if ((defined END_SHOOTING_STARS_REF && defined SHOOTING_STARS_END && defined END)||(defined SHOOTING_STARS && defined SHOOTING_STARS_REFLECTION && defined OVERWORLD))
	#include "/lib/atmospherics/shootingstars.glsl"
	#endif

	#if (defined END_STARS_REF && defined END_STARS && defined END)
	#include "/lib/atmospherics/endstars.glsl"
	#endif

	#if (defined END_FBM_REF && defined FBM && defined END)
	#include "/lib/atmospherics/fbm.glsl"
	#endif

	#if (defined WATER_CAUSTICS && defined OVERWORLD)
	#include "/lib/lighting/caustics.glsl"
	#endif

	#include "/lib/atmospherics/fog.glsl"
	#include "/lib/lighting/forwardLighting.glsl"
	#include "/lib/surface/ggx.glsl"
	#include "/lib/reflections/simpleReflections.glsl"

	#if AA > 1
	#include "/lib/util/jitter.glsl"
	#endif

	#ifdef ADVANCED_MATERIALS
	#include "/lib/reflections/complexFresnel.glsl"
	#include "/lib/surface/directionalLightmap.glsl"
	#include "/lib/surface/materialGbuffers.glsl"
	#include "/lib/surface/parallax.glsl"

		#ifdef REFLECTION_RAIN
		#include "/lib/reflections/rainPuddles.glsl"
		#endif
	#endif

	#ifdef SHOW_DARK_ZONES
	#include "/lib/lighting/showdarkzones.glsl"
	#endif

	//Program//
	void main() {
		vec4 albedoT = texture2D(texture, texCoord);
		if (albedoT.a == 0.0) discard;
    	vec4 albedo = albedoT * vec4(color.rgb, 1.0);

		vec3 newNormal = normal;
		float f0 = 0.0;
		float dither = 0.0;
		float lexSkyReflect = 0.0;
		vec3 vlAlbedo = vec3(1.0);
		vec3 refraction = vec3(0.0);
		bool doLighting = true;
		bool coloredHandlight = true;


		vec3 worldPos = vec3(0.0);
		vec3 opaqueViewPos = vec3(0.0);
		vec4 cloud = vec4(1.0);

		#ifdef ADVANCED_MATERIALS
			vec2 newCoord = vTexCoord.xy * vTexCoordAM.zw + vTexCoordAM.xy;
			float surfaceDepth = 1.0;
			float parallaxFade = clamp01((dist - PARALLAX_DISTANCE) / 32.0);
			float skipAdvMat = float(mat > 0.98 && mat < 1.02);

			#ifdef PARALLAX
				if(skipAdvMat < 0.5) {
					newCoord = GetParallaxCoord(texCoord, parallaxFade, surfaceDepth);
					albedo = textureGrad(texture, newCoord, dcdx, dcdy) * vec4(color.rgb, 1.0);
				}
			#endif
		#endif

		vec2 lightmap = clampVec2_01(lmCoord);

		float skyRefFactor = 0.0;

		#if SKY_REFLECT_DARK_AREA == 1
			lexSkyReflect = 0.99;
		#elif SKY_REFLECT_DARK_AREA == 2
			lexSkyReflect = 0.88;
		#elif SKY_REFLECT_DARK_AREA == 3
			lexSkyReflect = 0.85;
		#elif SKY_REFLECT_DARK_AREA == 4
			lexSkyReflect = 0.80;
		#elif SKY_REFLECT_DARK_AREA == 5
			lexSkyReflect = 0.50;
		#elif SKY_REFLECT_DARK_AREA == 6
			lexSkyReflect = 0.0;
		#endif

		if (lightmap.y > lexSkyReflect) skyRefFactor = 1.0;

		#if defined (END) || defined (NETHER)
		skyRefFactor = 1.0;
		#endif

		if (albedo.a > 0.00001) {

			float water       = float(mat > 0.98 && mat < 1.02);
			float translucent = float(mat > 1.98 && mat < 2.02);
			float tintedGlass = float(mat > 2.98 && mat < 3.02);
			float ice      	  = float(mat > 3.98 && mat < 4.02);
			float netherportal= float(mat > 4.98 && mat < 5.02);

			float metalness      = 0.0;
			float emission       = 0.0;
			float subsurface     = (ice * 0.5) + water;

			#if SSS_ON_GLASS < 1
				if(translucent > 0.5)subsurface = 0.0;
			#else
				if(translucent > 0.5)subsurface += translucent * 0.5;
			#endif

			vec3 baseReflectance = vec3(0.05);

			#ifndef REFLECTION_TRANSLUCENT
				translucent = 0.0;
				tintedGlass = 0.0;
			#endif

			vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);

			#if AA > 1
				vec3 viewPos = ScreenToView(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
			#else
				vec3 viewPos = ScreenToView(screenPos);
			#endif

			worldPos = ViewToPlayer(viewPos);

			float lViewPos = length(viewPos.xyz);

			vec3 nViewPos = normalize(viewPos.xyz);

			float NdotU = dot(nViewPos, upVec);

			#if WATER_MODE > 0
				dither = InterleavedGradientNoise();
			#else
				dither = Bayer64(gl_FragCoord.xy);
				dither = animateDither(dither);
			#endif

			vec3 normalMap = vec3(0.0, 0.0, 1.0);

			mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
								  tangent.y, binormal.y, normal.y,
								  tangent.z, binormal.z, normal.z);

			if (water > 0.5) {
				normalMap = GetWaterNormal(worldPos, viewPos, viewVector);
				newNormal = clampVec3Inv_11(normalize(normalMap * tbnMatrix));
			}

			#ifdef ADVANCED_MATERIALS
				float porosity = 0.5, ao = 1.0, skyOcclusion = 0.0;
				if (water < 0.5) {
					GetMaterials(smoothness, metalness, f0, emission, subsurface, porosity, ao, normalMap, newCoord, dcdx, dcdy);

					if ((normalMap.x > -0.999 || normalMap.y > -0.999)&& viewVector == viewVector)
					newNormal = clampVec3Inv_11(normalize(normalMap * tbnMatrix));
				}
			#endif

			#if REFRACTION == 1
			refraction = vec3((newNormal.xy - normal.xy) * 0.5 + 0.5, float(albedo.a < 0.95));
			#elif REFRACTION == 2
			refraction = vec3((newNormal.xy - normal.xy) * 0.5 + 0.5, float(albedo.a < 0.95) * water);
			#elif REFRACTION == 3
			refraction = vec3((newNormal.xy - normal.xy) * 0.5 + 0.5, float(albedo.a < 0.95) * water + translucent + tintedGlass);
			#elif REFRACTION == 4
			refraction = vec3((newNormal.xy - normal.xy) * 0.5 + 0.5, float(albedo.a < 0.95) * water + translucent + tintedGlass + ice);
			#endif

			/*////////////////////////////////////////////////////////////////////////////////////////
			///////////////////////NETHER_PORTAL//////////////////////////////////////////////////////
			////////////////////////////////////////////////////////////////////////////////////////*/
			#if NEW_NETHER_PORTAL > 0
				#include "/lib/others/netherPortal.glsl"
			#endif
			/*////////////////////////////////////////////////////////////////////////////////////////
			///////////////////////NETHER_PORTAL//////////////////////////////////////////////////////
			////////////////////////////////////////////////////////////////////////////////////////*/

			if (water < 0.5) albedo.rgb = pow(albedo.rgb, vec3(2.2));

			float fresnel = clamp01(1.0 + dot(newNormal, nViewPos));
			float fresnelWR = pow(clamp01(1.0 + dot(newNormal, nViewPos)), 2.0);
			float fresnelWR2 = pow2(fresnelWR);
			float fresnel2 = pow2(fresnel);
			float fresnel4 = pow2(fresnel2);

			float lViewPosOP = 0.0;
			float difOP = 0.0;
			vec3 colorTer = vec3(0.0);

			if (water > 0.5) {

			#include "/lib/reflections/waterReflections.glsl"

			}

			#ifdef WHITE_WORLD
				#ifdef WATERW
					albedo.rgb = vec3(0.5);
				#endif
			#endif

			#ifdef BLACK_WORLD
				#ifdef WATERW
					albedo.rgb = vec3(0.0);
				#endif
			#endif

			vlAlbedo = mix(vec3(1.0), albedo.rgb, sqrt1(albedo.a)) * (1.0 - pow(albedo.a, 64.0));

			bool isBackface      = dot(normal, lightVec) < -0.0001;
			float NoL 			 = clamp01(dot(newNormal, lightVec) * 1.01 - 0.01);
			float NoU 			 = clampInv11(dot(newNormal, upVec));
			float NoE 			 = clampInv11(dot(newNormal, eastVec));
			float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
			 	  vanillaDiffuse*= vanillaDiffuse;


			float parallaxShadow = 1.0;

			#ifdef ADVANCED_MATERIALS
				vec3 rawAlbedo = albedo.rgb * 0.999 + 0.001;
				albedo.rgb *= ao;

				#ifdef REFLECTION_SPECULAR
					albedo.rgb *= (1.0 - metalness * 0.45);
				#endif

				#ifdef SELF_SHADOW
					if (lightmap.y > 0.0 && NoL > 0.0 && water < 0.5) {
						parallaxShadow = GetParallaxShadow(surfaceDepth, parallaxFade, newCoord, lightVec, tbnMatrix);
						NoL *= parallaxShadow;
					}
				#endif
			#endif

			vec3 shadow = vec3(0.0);
			if (doLighting) GetLighting(albedo.rgb, shadow, viewPos, worldPos, lightmap, color.a, NoL, vanillaDiffuse,
			parallaxShadow, emission, subsurface, true, true, coloredHandlight, true);

			/*/////////////////////////////////////////////
			/////Emin Water Absoption modified by me//////
			////////////Credits EminGT///////////////////
			//////////////////////////////////////////*/
			#ifdef ABSORPTION
				if (water > 0.5 && isEyeInWater == 0) {
					colorTer       =colorTer * 2.0;
					colorTer      *=colorTer;
				#if WATER_MODE < 2
				vec3  absorbColor    =(normalize(waterColor.rgb + vec3(0.01)) * sqrt(WATER_I)) * colorTer * 1.92;
				#else
				vec3  absorbColor    =(normalize(vanillaWaterColorAbs.rgb + vec3(0.01)) * sqrt(VANILLA_WATER_ABS_I)) * colorTer * 1.92;
				#endif

				float absorbDist     =1.0 - clamp01(difOP / 8.0);

				vec3  waterAlbedoAbs =mix(pow2(absorbColor), pow2(colorTer), pow2(absorbDist));
					  waterAlbedoAbs*=waterAlbedoAbs * 0.9;

				float waterFogAbs    =lViewPosOP / pow(far, 0.05) * 0.015 * (1.0 - sunVisibility * 0.25) * 2.5;
					  waterFogAbs    =(1.0 - (exp(-300.0 * pow(waterFogAbs*0.125, 3.25) * eBS)));

				float fixWaterFogAbs =max(1.0 - waterFogAbs, 0.0);
					  fixWaterFogAbs*=fixWaterFogAbs;
					  fixWaterFogAbs*=fixWaterFogAbs;
					  fixWaterFogAbs*=fixWaterFogAbs;
					  fixWaterFogAbs*=1.0 - rainFactor * 0.7;

				float skyLightFactor =clamp01(max(lightmap.y - 0.95, 0.05) * ALBEDO_ABS_POWER);
				float absorb         =(1.0 - albedo.a) * fixWaterFogAbs * skyLightFactor;

					albedo.rgb     =mix(albedo.rgb, waterAlbedoAbs / (1.0 - WATER_ABS_COLOR), absorb);
				}
			#endif

			#ifdef ADVANCED_MATERIALS
				float puddles = 0.0;

				#if (defined REFLECTION_RAIN && defined OVERWORLD)
					#include "/lib/others/puddles.glsl"
				#endif
			#endif

			if (water > 0.5 || ice > 0.5 || (translucent > 0.5 && albedo.a < 0.95)){

				vec4 reflection = vec4(0.0);
				vec3 skyReflection = vec3(0.0);
				float reflectionMask = 0.0;

				fresnel = fresnel4 * 0.95 + 0.05;
				fresnel*= max(1.0 - isEyeInWater * 0.5 * water, 0.5);
				fresnel*= 1.0 - translucent * (1.0 - albedo.a);

				fresnel*= getDayNightCaveValue(FRESNEL_DAY, FRESNEL_NIGHT, FRESNEL_CAVE);

				fresnel = clamp01(fresnel);

				#ifdef REFLECTION
				vec3 refNormal = mix(newNormal, normal, pow2(pow2(fresnel4)));
					reflection = SimpleReflection(viewPos, refNormal, dither, reflectionMask);
					reflection.rgb = pow(reflection.rgb * 2.0, vec3(8.0));
				#endif

					if (ice > 0.5){
						fresnel *= fresnel4 * ICE_REFLECTION_STRENGTH;
					}

					if (reflection.a < 1.0) {

						vec3 skyRefPos = reflect(nViewPos, newNormal);
						vec3 specularColor = GetSpecularColor(lightmap.y, 0.0, vec3(1.0));

						#if defined (OVERWORLD)
							skyReflection = GetSkyColor(skyRefPos, true);

							vec3 specular = GetSpecularHighlight(newNormal, viewPos, lightVec, 0.9, vec3(0.02), specularColor, shadow, color.a);

							vec3 gotTheSkyColor = vec3(0.0);
							     gotTheSkyColor = isEyeInWater == 1 ? 0.1 * pow(rawWaterColorSqrt.rgb * (1.0 - blindFactor), vec3(2.0)) : GetSkyColor(skyRefPos, true);
							skyReflection = gotTheSkyColor;

							float specularAlpha = mix(albedo.a , 1.0, fresnel) * fresnel;

							skyReflection += specular * (1.0 - reflectionMask) / specularAlpha;

							#if defined (REFLECTION_TRANSLUCENT)
							#include "/lib/reflections/waterReflectionStuff.glsl"
							#endif

							#ifdef CLASSIC_EXPOSURE
								skyReflection *= (4.0 - 3.0 * eBS) * lightmap.y;
							#endif

							float waterSkyOcclusion = lightmap.y;

							#if REFLECTION_SKY_FALLOFF > 1
								waterSkyOcclusion = clamp(1.0 - (1.0 - waterSkyOcclusion) * REFLECTION_SKY_FALLOFF, 0.0, 1.0);
							#endif
								waterSkyOcclusion *= waterSkyOcclusion;
								skyReflection *= waterSkyOcclusion;

						#elif defined (NETHER)
							skyReflection = netherCol.rgb * 0.2;

						#elif defined (END)
							skyReflection=endCol.rgb * 0.1;
							skyRefPos *= 1000000.0;

							#if defined (REFLECTION_TRANSLUCENT)
							#include "/lib/reflections/waterReflectionStuffEnd.glsl"
							#endif

						#endif

							skyReflection *= clamp01(1.0 - isEyeInWater) * skyRefFactor;
					}

				if (translucent > 0.5){
				float saturationFactor = STAINED_SAT;
				float transparencyFactor = STAINED_TRANS;
				vec3 gray = vec3(dot(albedo.rgb, vec3(0.299, 0.587, 0.114)));
					albedo.rgb = mix(gray, albedo.rgb, saturationFactor);
					albedo.a *= transparencyFactor;
				}

				reflection.rgb = max(mix(skyReflection, reflection.rgb, reflection.a), vec3(0.0));

				albedo.rgb = mix(albedo.rgb, reflection.rgb, fresnel);
				albedo.a = mix(albedo.a, 1.0, fresnel);


			}else{

			#ifdef ADVANCED_MATERIALS

					skyOcclusion = Smooth3(lightmap.y);

					#if REFLECTION_SKY_FALLOFF > 1
						skyOcclusion = clamp01(1.0 - (1.0 - skyOcclusion) * REFLECTION_SKY_FALLOFF);
					#endif

					skyOcclusion *= skyOcclusion;

					baseReflectance = mix(vec3(f0), rawAlbedo, metalness);

				#ifdef REFLECTION_SPECULAR

					vec3 fresnel3 = vec3(0.0);

					if(netherportal < 0.5){

						fresnel3 = mix(baseReflectance, vec3(1.0), fresnel);
					}
						#if MATERIAL_FORMAT == 0
							if (f0 >= 0.9 && f0 < 1.0) {
								baseReflectance = GetMetalCol(f0);
								fresnel3 = ComplexFresnel(pow(fresnel, 0.2), f0);
							}
						#endif

					float aoSquared = pow2(ao);
						shadow *= aoSquared;
						fresnel3 *= aoSquared * smoothness * smoothness;

						if (smoothness > 0.0) {
							vec4 reflection = vec4(0.0);
							vec3 skyReflection = vec3(0.0);
							float reflectionMask = 0.0;

							float ssrMask = clamp01(length(fresnel3) * 400.0 - 1.0);
							if(ssrMask > 0.0) reflection = SimpleReflection(viewPos, newNormal, dither, reflectionMask);
							reflection.rgb = pow(reflection.rgb * 2.0, vec3(8.0));
							reflection.a *= ssrMask;

						if (reflection.a < 1.0){
							vec3 skyRefPos = reflect(nViewPos, newNormal);
							#if defined (OVERWORLD)

								skyReflection = GetSkyColor(skyRefPos, true);

								#if defined (REFLECTION_TRANSLUCENT)
								#include "/lib/reflections/waterReflectionStuff.glsl"
								#endif

								#ifdef CLASSIC_EXPOSURE
									skyReflection *= 4.0 - 3.0 * eBS;
								#endif

								skyReflection = mix(vanillaDiffuse * minLightCol * ((isEyeInWater == 1) ? MINLIGHT_U_I : MINLIGHT_I),
												skyReflection, skyOcclusion);

							#elif defined (NETHER)
								skyReflection = netherCol.rgb * 0.2;

							#elif defined (END)
								skyReflection = endCol.rgb * 0.1;

								#if defined (REFLECTION_TRANSLUCENT)
								#include "/lib/reflections/waterReflectionStuffEnd.glsl"
								#endif
							#endif
						}
								if (translucent > 0.5){
								float saturationFactor = STAINED_SAT;
								float transparencyFactor = STAINED_TRANS;
								vec3 gray = vec3(dot(albedo.rgb, vec3(0.299, 0.587, 0.114)));
									albedo.rgb = mix(gray, albedo.rgb, saturationFactor);
									albedo.a *= transparencyFactor;
								}

								skyReflection *= skyRefFactor;
								reflection.rgb = max(mix(skyReflection, reflection.rgb, reflectionMask), vec3(0.0));

								albedo.rgb = albedo.rgb * (1.0 - fresnel3 * (1.0 - metalness)) +
											reflection.rgb * fresnel3;
								albedo.a = mix(albedo.a, 1.0, GetLuminance(fresnel3));
				}
				#endif

				#if (defined OVERWORLD || defined END)
				vec3 specularColor = GetSpecularColor(lightmap.y, metalness, baseReflectance);

				vec3 GetSpecularHighlight = GetSpecularHighlight(newNormal, viewPos, lightVec, smoothness, baseReflectance, specularColor, shadow * vanillaDiffuse, color.a);

				if (!isBackface)
				albedo.rgb += GetSpecularHighlight;

				#endif
			#endif
			}

			if (tintedGlass > 0.5) {
				albedo.a = sqrt2(albedo.a);
			}

			#if WATER_FOG == 1
				if (isEyeInWater == 1 && water < 0.5) {
				float opaqueDepth = texture2D(depthtex1, screenPos.xy).r;
				vec3 opaqueScreenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), opaqueDepth) * 0.5 + 0.5;
				#if AA > 1
				vec3 opaqueViewPos = ScreenToView(vec3(TAAJitter(opaqueScreenPos.xy, -0.5), opaqueScreenPos.z));
				#else
				vec3 opaqueViewPos = ScreenToView(opaqueScreenPos);
				#endif

				vec4 waterFog = GetWaterFog(opaqueViewPos - viewPos.xyz);
				albedo = mix(waterFog, vec4(albedo.rgb, 0.92), sqrt(albedo.a));
				}
			#endif

			#ifdef FOG
				albedo.rgb = Fog(albedo.rgb, viewPos);
			#endif

			#if (defined WATER_CAUSTICS && defined OVERWORLD)
				#include "/lib/lighting/causticsCall.glsl"
			#endif

			#ifdef SHOW_DARK_ZONES
				if (vanillaDiffuse > 0.99 && (mat < 0.95 || mat > 1.05) && translucent < 0.5) {
					albedo.rgb=showDarkZones(albedo.rgb);
				}
			#endif
		}

		/* RENDERTARGETS: 0,1 */
		#ifdef DEBUG_WATER
            gl_FragData[0]=vec4(0.5176, 0.0, 1.0, 0.75);
		#else
			gl_FragData[0] = vec4(albedo);
		#endif

		gl_FragData[1] = vec4(vlAlbedo, 1.0);

		/* RENDERTARGETS: 0,1,8 */
		gl_FragData[2] = vec4(isWater, 0.0, 0.0, 1.0);

		#if REFRACTION > 0
		/* RENDERTARGETS: 0,1,8,14 */
		gl_FragData[3] = vec4(refraction, 1.0);
		#endif
	}
#endif