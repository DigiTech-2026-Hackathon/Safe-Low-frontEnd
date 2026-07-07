/*#############################################
#    _   ___ _____ ___    _   _    _____  __  #
#   /_\ / __|_   _| _ \  /_\ | |  | __\ \/ /  #
#  / _ \\__ \ | | |   / / _ \| |__| _| >  <   #
# /_/ \_\___/ |_| |_|_\/_/ \_\____|___/_/\_\  #
#											  #
#############################################*/

//Settings//////////////////Settings///////////////////Settings///////////////////Settings//

//#define DEBUG_TERRAIN

#include "/lib/util/functions.glsl"

#include "/settings/globalSettings.glsl"

//Varying////////////////////Varying////////////////////Varying////////////////////Varying//
varying float mat;
varying float isPlant;

#ifdef DETECTEUR_CAVE
varying float visibleblock;
#endif

varying vec2 texCoord, lmCoord, signMidCoordPos;
varying vec3 sunVec, upVec, uSunVec, eastVec, normal;
varying vec4 color;

#ifdef ADVANCED_MATERIALS
	varying float dist;

	varying vec3 binormal, tangent;
	varying vec3 viewVector;

	varying vec4 vTexCoord, vTexCoordAM;
#endif

#ifdef SHOW_DARK_ZONES
	varying float isLightSource;
#endif

#ifdef ANISO_FILTER
varying vec4 spriteBounds;
#endif

varying float isSkulkSensor;

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

	//Uniforms//
	uniform float frameTimeCounter;

	#if MOUVEMENT_CAM > 0
	uniform float onGroundSmooth;
	#endif

	uniform vec3 cameraPosition;

	uniform mat4 gbufferModelViewInverse;
	uniform mat4 gbufferProjection;

	#if AA > 1
		uniform int frameCounter;
		uniform float viewWidth, viewHeight;
	#endif

	//Attributes//
	attribute vec4 mc_Entity;
	attribute vec4 mc_midTexCoord;

	#ifdef ADVANCED_MATERIALS
	attribute vec4 at_tangent;
	#endif

	//Common Variables//

	float GetNoise(vec2 pos){
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.54953);
	}

	//Includes//
	#include "/lib/vertex/waving.glsl"

	#if AA > 1
	#include "/lib/util/jitter.glsl"
	#endif

	#ifdef WORLD_CURVATURE
	#include "/lib/vertex/worldCurvature.glsl"
	#endif

	//Program//
	void main(){

		#ifdef DETECTEUR_CAVE
			if(mc_Entity.x == 10003 || mc_Entity.x == 10002 || mc_Entity.x == 10999){
					visibleblock= 0.0;
				}else{
					visibleblock= 1.0;
				}
		#endif

		texCoord=(gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

		lmCoord  = GetLightMapCoordinates();

		normal=normalize(gl_NormalMatrix * gl_Normal);

		#ifdef ADVANCED_MATERIALS
			binormal=normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
			tangent=normalize(gl_NormalMatrix * at_tangent.xyz);

			mat3 tbnMatrix=mat3(tangent.x,binormal.x,normal.x,
								tangent.y,binormal.y,normal.y,
								tangent.z,binormal.z,normal.z);

			viewVector=tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;

			if (mc_Entity.x == 0)
			viewVector /= 0.0;

			dist=length(gl_ModelViewMatrix * gl_Vertex);

			vec2 midCoord=(gl_TextureMatrix[0] * mc_midTexCoord).xy;
			vec2 texMinMidCoord= texCoord - midCoord;
			signMidCoordPos = sign(texMinMidCoord);

			vTexCoordAM.zw=abs(texMinMidCoord) * 2.0;
			vTexCoordAM.xy=min(texCoord, midCoord - texMinMidCoord);

			vTexCoord.xy=sign(texMinMidCoord) * 0.5 + 0.5;
		#endif

		color=gl_Color;

		mat=0.0;
		isPlant=0.0;

		#ifdef SHOW_DARK_ZONES
			isLightSource=0.0;
		#endif

		/*
		SSS
		*/
		if (mc_Entity.x == 10100 || mc_Entity.x == 10101 || mc_Entity.x == 100   || mc_Entity.x == 101   ||
			mc_Entity.x == 10102 ||	mc_Entity.x == 10103 || mc_Entity.x == 102   || mc_Entity.x == 103   ||
			mc_Entity.x == 104   ||	mc_Entity.x == 10104 ||	mc_Entity.x == 10107 || mc_Entity.x == 10108 ||
			mc_Entity.x == 109   ||	mc_Entity.x == 10109 ||	mc_Entity.x == 10112 || mc_Entity.x == 10113 ||
			mc_Entity.x == 10116 ||	mc_Entity.x == 10117 ||	mc_Entity.x == 10118 || mc_Entity.x == 10119 ||
			mc_Entity.x == 10120 ||	mc_Entity.x == 10121 ||	mc_Entity.x == 10122 ||	mc_Entity.x == 10123 ||
			mc_Entity.x == 10256 ||	mc_Entity.x == 10304 ||	mc_Entity.x == 10401 ||	mc_Entity.x == 10402 ||
			mc_Entity.x == 10701 ||	mc_Entity.x == 10702 ||	mc_Entity.x == 10703 ||	mc_Entity.x == 10704 ){
				mat = 1.0;
			}

		#if SSS_ON_GLASS == 2
			if (mc_Entity.x == 10305){
				mat = 1.0;
			}
		#endif

		if (mc_Entity.x == 10105 || mc_Entity.x == 10106){
				mat = 2.0, color.rgb *= 1.125;
		}

		/*
		Other SSS
		*/
		if (mc_Entity.x == 10114 ||	mc_Entity.x == 10302 || mc_Entity.x == 10124 || mc_Entity.x == 10125 ||
			mc_Entity.x == 10126 || mc_Entity.x == 10127 || mc_Entity.x == 10128 || mc_Entity.x == 10222){
				mat = 3.0;
		}

		/*
		Emissive
		*/
		if (mc_Entity.x == 10200 || mc_Entity.x == 10207 || mc_Entity.x == 10210 || mc_Entity.x == 10213 ||
			mc_Entity.x == 10214 ||	mc_Entity.x == 10215 || mc_Entity.x == 10226 || mc_Entity.x == 10231 ||
			mc_Entity.x == 10249 || mc_Entity.x == 10251 || mc_Entity.x == 10252 ||	mc_Entity.x == 10253 ||
			mc_Entity.x == 10254 || mc_Entity.x == 10257 || mc_Entity.x == 10258 || mc_Entity.x == 10265 ||
			mc_Entity.x == 10266 ||	mc_Entity.x == 10267 || mc_Entity.x == 10268 ){
				mat = 4.0;
			}

		if (mc_Entity.x == 10269 || mc_Entity.x == 10273 || mc_Entity.x == 10274){
			isSkulkSensor = 1.0;
		}else{
			isSkulkSensor = 0.0;
		}

		#ifdef SHOW_DARK_ZONES
		if (mc_Entity.x == 10200 || mc_Entity.x == 10207 || mc_Entity.x == 10210 || mc_Entity.x == 10213 ||
			mc_Entity.x == 10214 ||	mc_Entity.x == 10215 || mc_Entity.x == 10216 || mc_Entity.x == 10217 ||
			mc_Entity.x == 10218 ||	mc_Entity.x == 10219 || mc_Entity.x == 10222 || mc_Entity.x == 10226 ||
			mc_Entity.x == 10231 ||	mc_Entity.x == 10248 || mc_Entity.x == 10249 || mc_Entity.x == 10250 ||
			mc_Entity.x == 10251 ||	mc_Entity.x == 10252 ||	mc_Entity.x == 10253 || mc_Entity.x == 10254 ||
			mc_Entity.x == 10255 ||	mc_Entity.x == 10257 || mc_Entity.x == 10259 || mc_Entity.x == 10888 ||
			mc_Entity.x == 10278 ||	mc_Entity.x == 10279 || mc_Entity.x == 10280 || mc_Entity.x == 10281){
				isLightSource = 1.0;
			}

		#endif

		if (mc_Entity.x == 10130){ // Emerald-Diamond Block
			mat = 102.0, color.rgb *= 1.225;
		}

		#if SSS_ON_CALCITE
		if (mc_Entity.x == 10994){ // Calcite Block
			mat = 103.0, color.rgb *= 1.225;
		}
		#endif

		#if SSS_ON_QUARTZ
		if (mc_Entity.x == 10995){ // Quartz Block
			mat = 104.0, color.rgb *= 1.225;
		}
		#endif

		#if defined CHORUS_EMISSIVE_O || defined CHORUS_EMISSIVE_N || defined CHORUS_EMISSIVE_E
			if (mc_Entity.x == 10275){ // Chorus Flower
				mat = 105;
			}
		#endif

		if (mc_Entity.x == 10276){ // Nether Quartz Ore
			mat = 106;
		}

		if (mc_Entity.x == 10277){ // Nether Quartz Ore
			mat = 107;
		}

		if (mc_Entity.x == 10889){ // End Portal Frame
			lmCoord.x = min(lmCoord.x, 0.85);
		}

		#include "/lib/vertex/blockbrightness.glsl"

		/*////////////////////////////////////////////////////////////////////////////
		//////////////////////////////WEATHER_DETECTION//////////////////////////////
		//////////////////////////////////////////////////////////////////////////*/

		if (mc_Entity.x == 10996 || mc_Entity.x == 10997) // Snow
			mat = 100.0;

		if (mc_Entity.x == 10998 || mc_Entity.x == 10999) // Sand
			mat = 101.0;

		/*////////////////////////////////////////////////////////////////////////////
		//////////////////////////////WEATHER_DETECTION//////////////////////////////
		//////////////////////////////////////////////////////////////////////////*/

		if (mc_Entity.x == 10245){ // Furnace / Smoker
			lmCoord.x -= 0.0667;
		}

		if (color.a < 0.1){
			color.a = 1.0;
		}

		#ifdef ANISO_FILTER
            vec2 spriteRadius = abs(texCoord - mc_midTexCoord.xy);
            vec2 bottomLeft = mc_midTexCoord.xy - spriteRadius;
            vec2 topRight = mc_midTexCoord.xy + spriteRadius;
            spriteBounds = vec4(bottomLeft, topRight);
        #endif

		upVec = normalize(gbufferModelView[1].xyz);
		eastVec = normalize(gbufferModelView[0].xyz);
		uSunVec = GetuSunVec();
		sunVec = GetSunVec(uSunVec);

		vec4 position=gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

		float istopv=gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1.0 : 0.0;
		position.xyz=WavingBlocks(position.xyz, istopv);

		#ifdef WORLD_CURVATURE
			position.y -= WorldCurvature(position.xz);
		#endif

		gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

		#if MOUVEMENT_CAM > 0
			gl_Position += vec4(0.03 * sin(frameTimeCounter * 3.0 * SPEED_MOOVE), 0.015 * cos(frameTimeCounter * 4.0 * SPEED_MOOVE), 0.0, 0.0) * gl_ProjectionMatrix * onGroundSmooth;
		#endif

		#if AA > 1
			gl_Position.xy=TAAJitter(gl_Position.xy, gl_Position.w);
		#endif

	}

#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

	//Uniforms//
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
	uniform float viewWidth, viewHeight;
	uniform float far;

	#if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
		uniform float darknessFactor;
		uniform float darknessLightFactor;
	#endif

	uniform ivec2 eyeBrightnessSmooth;

	uniform mat4 gbufferProjectionInverse;
	uniform mat4 gbufferModelViewInverse;
	uniform mat4 shadowProjection;
	uniform mat4 shadowModelView;
	uniform vec3 cameraPosition;
	uniform sampler2D texture;
	uniform sampler2D noisetex;

	#ifdef ADVANCED_MATERIALS
		uniform ivec2 atlasSize;
		uniform sampler2D specular;
		uniform sampler2D normals;

		#ifdef REFLECTION_RAIN
			uniform float wetness;
			uniform mat4 gbufferModelView;
		#endif

	#endif

	uniform vec3 fogColor;

	//Common Variables//
	float eBS              =eyeBrightnessSmooth.y / 240.0;
	float sunVisibility    =clamp00125(dot( sunVec,upVec) + 0.0625) * 8.0;
	float moonVisibility   =clamp00125(dot( -sunVec,upVec) + 0.0625) * 8.0;
	float screenBrightness2=clamp01(screenBrightness);

	#ifdef ADVANCED_MATERIALS
		vec2 dcdx = dFdx(texCoord);
		vec2 dcdy = dFdy(texCoord);
	#endif

	#ifdef OVERWORLD
		vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
	#else
		vec3 lightVec = sunVec;
	#endif

	#ifdef ANISO_FILTER
		#include "/lib/antialiasing/IMSaf.glsl"
	#endif

	//Includes//
	#include "/lib/color/blocklightColor.glsl"
	#include "/lib/color/dimensionColor.glsl"
	#include "/lib/color/specularColor.glsl"
	#include "/lib/util/dither.glsl"
	#include "/lib/util/spaceConversion.glsl"

	#if (defined WATER_CAUSTICS && defined OVERWORLD)
	#include "/lib/color/waterColor.glsl"
	#include "/lib/lighting/caustics.glsl"
	#endif

	#include "/lib/lighting/forwardLighting.glsl"

	#if AA > 1
	#include "/lib/util/jitter.glsl"
	#endif

	#ifdef ADVANCED_MATERIALS
	#include "/lib/util/encode.glsl"
	#include "/lib/surface/ggx.glsl"
	#include "/lib/reflections/complexFresnel.glsl"

	#ifdef DIRECTIONAL_LIGHTMAP
	#include "/lib/surface/directionalLightmap.glsl"
	#endif

	#include "/lib/surface/materialGbuffers.glsl"
	#include "/lib/surface/parallax.glsl"

	#ifdef REFLECTION_RAIN
	#include "/lib/reflections/rainPuddles.glsl"
	#endif

	#endif

	#if EMISSIVE > 0
	#include "/lib/surface/emissiveT.glsl"
	#endif

	#ifdef SHOW_DARK_ZONES
	#include "/lib/lighting/showdarkzones.glsl"
	#endif

	//Program//
	void main(){

		#ifdef DETECTEUR_CAVE
			if(visibleblock>0.5){
		#endif
			vec4 albedo = vec4(0.0);
			vec4 detectcolor = texture2D(texture, texCoord);
				 albedo = detectcolor * vec4(color.rgb, 1.0);

			vec3 newNormal = normal;
			float smoothness = 0.0;
			float material = floor(mat);
			bool doLighting = true;
			bool coloredHandlight = true;

			#ifdef ADVANCED_MATERIALS
				vec2 newCoord = (vTexCoord.xy) * vTexCoordAM.zw + vTexCoordAM.xy;
				float surfaceDepth = 1.0;
				float parallaxFade = clamp01((dist - PARALLAX_DISTANCE) / 32.0);
				float skipAdvMat = float(mat > 98.98 && mat < 99.02);

				#ifdef PARALLAX
					if(skipAdvMat < 0.5){
						newCoord = GetParallaxCoord(texCoord, parallaxFade, surfaceDepth);
						detectcolor = textureGrad(texture, newCoord, dcdx, dcdy);
						albedo = detectcolor * vec4(color.rgb, 1.0);
					}
				#endif

				float skyOcclusion = 0.0;

				vec3 fresnel3 = vec3(0.0);

			#endif

			if (albedo.a > 0.00001){

				vec2 lightmap = clampVec2_01(lmCoord);

				vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
				#if AA > 1
					vec3 viewPos = ScreenToView(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
				#else
					vec3 viewPos = ScreenToView(screenPos);
				#endif

				vec3 worldPos = ViewToPlayer(viewPos);

				vec3 nViewPos=normalize(viewPos.xyz);

				float foliage      =float(mat > 0.98 && mat < 1.02 || mat > 46.98 && mat < 47.02);
				float leaves       =float(mat > 1.98 && mat < 2.02);
				float otherSSS     =float(mat > 2.98 && mat < 3.02);
				float emissive     =float(mat > 3.98 && mat < 4.02);
				float lava		   =float(mat > 98.98 && mat < 99.02);
				float snow  	   =float(mat > 99.98 && mat < 100.02);
				float sand  	   =float(mat > 100.98 && mat < 101.02);
				float emerald_diam =float(mat > 101.98 && mat < 102.02);
				float calcite 	   =float(mat > 102.98 && mat < 103.02);
				float quartz       =float(mat > 103.98 && mat < 104.02);

				float emission     = emissive * 0.4;

				float metalness=0.0;

				#ifdef ANISO_FILTER
					#ifdef PARALLAX
					vec2 AFcoord = newCoord;
					#else
					vec2 AFcoord = texCoord;
					#endif
					if (lava < 0.5){
					vec2 spriteDimensions = vec2(spriteBounds.z - spriteBounds.x, spriteBounds.w - spriteBounds.y);
					albedo = textureAF(AFcoord, AF_SAMPLES, spriteDimensions, spriteBounds.xy, viewHeight) * color;
					}
				#endif

				/*////////COLOR_POINTER////////////*/
				#if EMISSIVE > 0
					getEmissiveT(viewPos, emission, detectcolor, albedo, lightmap, doLighting, coloredHandlight);
				#endif
				/*////////COLOR_POINTER////////////*/

				float subsurface = (foliage * mix(SSS_FOLIAGE_STRENGTH * 1.5, SSS_FOLIAGE_STRENGTH * 2.0, sunVisibility)) + (leaves * SSS_LEAVES_STRENGTH * 2.0) + (otherSSS * 0.5) + (emerald_diam * 0.5);
					#if SSS_ON_SNOW == 1
						subsurface += (snow * 0.5);
					#endif
					#if SSS_ON_SAND == 1
						subsurface += (sand * 0.5);
					#endif
					#if SSS_ON_QUARTZ == 1
						subsurface += (quartz * 0.3);
					#endif
					#if SSS_ON_CALCITE == 1
						subsurface += (calcite * 0.3);
					#endif

				subsurface *= 1.5;

				vec3 baseReflectance = vec3(0.04);

				#ifdef ADVANCED_MATERIALS
					float f0 = 0.0, porosity = 0.5, ao = 1.0;
					vec3 normalMap = vec3(0.0, 0.0, 1.0);
					GetMaterials(smoothness, metalness, f0, emission, subsurface, porosity, ao, normalMap, newCoord, dcdx, dcdy);

					mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
										tangent.y, binormal.y, normal.y,
										tangent.z, binormal.z, normal.z);

					if ((normalMap.x > -0.999 || normalMap.y > -0.999) && viewVector == viewVector)
					newNormal = clampVec3Inv_11(normalize(normalMap * tbnMatrix));

				#endif

				albedo.rgb = pow(albedo.rgb, vec3(2.2));

				#ifdef WHITE_WORLD
					#ifdef TERRAINW
						albedo.rgb = vec3(0.5);
					#endif
				#endif

				#ifdef BLACK_WORLD
					#ifdef TERRAINW
						albedo.rgb = vec3(0.0);
					#endif
				#endif

				vec3 outNormal = newNormal;
				#if NORMAL_PLANTS == 1
					if (foliage > 0.5){
						newNormal = upVec;

						#ifdef ADVANCED_MATERIALS
							newNormal = normalize(mix(outNormal, newNormal, pow2(normalMap.z)));
						#endif
					}
				#elif NORMAL_PLANTS == 2
					if (isEyeInWater == 1){
						if (foliage > 0.5){
							newNormal = upVec;

							#ifdef ADVANCED_MATERIALS
								newNormal = normalize(mix(outNormal, newNormal, pow2(normalMap.z)));
							#endif
						}
					}
				#endif

				bool isBackface      = dot(normal, lightVec) < -0.0001;
				float NoL            = clamp01(dot(newNormal, lightVec));
				float NoU            = clampInv11(dot(newNormal, upVec));
				float NoE            = clampInv11(dot(newNormal, eastVec));
				float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
				      vanillaDiffuse*= vanillaDiffuse;

				#if NORMAL_PLANTS == 0 || NORMAL_PLANTS == 2
				if (foliage > 0.5) vanillaDiffuse *= 2.5;
				#elif NORMAL_PLANTS == 1
				if (foliage > 0.5) vanillaDiffuse *= 1.0;
				#endif

				float parallaxShadow = 1.0;
				#ifdef ADVANCED_MATERIALS
					vec3 rawAlbedo = albedo.rgb * 0.999 + 0.001;

					#if LESS_AO == 0
						float lessAO = ao;
					#else
						float lessAO = pow2(ao);
					#endif

					albedo.rgb *= lessAO;

					#ifdef REFLECTION_SPECULAR
						albedo.rgb *= (1.0 - metalness * 0.45);
					#endif

					float doParallax = 0.0;

					#ifdef SELF_SHADOW
						float pNoL = dot(outNormal, lightVec);

						#if defined (OVERWORLD)
							doParallax = float(lightmap.y > 0.0 && pNoL > 0.0);
						#elif defined (END)
							doParallax = float(pNoL > 0.0);
						#endif

						if (doParallax > 0.5 && skipAdvMat < 0.5){
							parallaxShadow = GetParallaxShadow(surfaceDepth, parallaxFade, newCoord, lightVec, tbnMatrix);
						}
					#endif

					#ifdef DIRECTIONAL_LIGHTMAP
						mat3 lightmapTBN = GetLightmapTBN(viewPos);
						lightmap.x = DirectionalLightmap(lightmap.x, lmCoord.x, outNormal, lightmapTBN);
						lightmap.y = DirectionalLightmap(lightmap.y, lmCoord.y, outNormal, lightmapTBN);
					#endif

				#endif

				vec3 shadow = vec3(0.0);

				if (doLighting) GetLighting(albedo.rgb, shadow, viewPos, worldPos, lightmap, color.a, NoL, vanillaDiffuse,
				parallaxShadow, emission, subsurface, (isSkulkSensor < 0.5), true, coloredHandlight, true);

				#ifdef ADVANCED_MATERIALS
					float puddles = 0.0;

					#if (defined REFLECTION_RAIN && defined OVERWORLD)

					float pNoU = dot(outNormal, upVec);

					if(wetness > 0.001) {
					puddles = GetPuddles(worldPos, newCoord, wetness) * clamp01(pNoU);
					}

					#ifdef WEATHER_PERBIOME
						float weatherweight = isSnowy + isDesert + isMesa + isSavanna;
						puddles *= 1.0 - weatherweight;
					#endif

					#if DISABLE_PUDDLES == 0
						puddles *= clamp01(lightmap.y * 32.0 - 31.0) * (1.0 - lava);
					#elif DISABLE_PUDDLES == 1
						puddles *= clamp01(lightmap.y * 32.0 - 31.0) * (1.0 - lava) * (1.0 - snow);
					#elif DISABLE_PUDDLES == 2
						puddles *= clamp01(lightmap.y * 32.0 - 31.0) * (1.0 - lava) * (1.0 - snow) * (1.0 - sand);
					#elif DISABLE_PUDDLES == 3
						puddles *= clamp01(lightmap.y * 32.0 - 31.0) * (1.0 - lava) * (1.0 - sand);
					#endif

					float ps = sqrt(1.0 - 0.75 * porosity);
					float pd = (0.5 * porosity + 0.15);

					smoothness = mix(smoothness, SMOOTHNESS_PUDDLE_REFLECTION, puddles * ps);
					f0 = max(f0, puddles * 0.02);

					albedo.rgb *= 1.0 - (puddles * pd);

					if (puddles > 0.001 && rainFactor > 0.001){
						mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
											  tangent.y, binormal.y, normal.y,
											  tangent.z, binormal.z, normal.z);

						vec3 puddleNormal = GetPuddleNormal(worldPos, viewPos, tbnMatrix);
						outNormal = normalize(mix(outNormal, puddleNormal, puddles * sqrt(1.0 - porosity) * rainFactor));
					}
				#endif

				skyOcclusion = Smooth3(lightmap.y);

				baseReflectance = mix(vec3(f0), rawAlbedo, metalness);
				float fresnel = pow(clamp01(1.0 + dot(outNormal, nViewPos)), 5.0);

				fresnel3 = mix(baseReflectance, vec3(1.0), fresnel);
					#if MATERIAL_FORMAT == 1
						if (f0 >= 0.9 && f0 < 1.0) {
							baseReflectance = GetMetalCol(f0);
							fresnel3 = ComplexFresnel(pow(fresnel, 0.2), f0);

						}
					#endif

				float aoSquared = pow2(ao);
					shadow *= aoSquared; fresnel3 *= aoSquared;
					albedo.rgb = albedo.rgb * (1.0 - fresnel3 * smoothness * smoothness * (1.0 - metalness));


				#if (defined OVERWORLD && (defined ADVANCED_MATERIALS || defined SPECULAR_HIGHLIGHT_ROUGH))

					vec3 specularColor = GetSpecularColor(lightmap.y, metalness, baseReflectance);

					vec3 GetSpecularHighlight = GetSpecularHighlight(newNormal, viewPos, lightVec, smoothness, baseReflectance, specularColor, shadow * vanillaDiffuse, color.a);

					if (isEyeInWater == 0) GetSpecularHighlight *= pow(lightmap.y, 2.5);

					if (!isBackface)
					albedo.rgb += GetSpecularHighlight;

				#endif

				#if (defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR && defined REFLECTION_ROUGH)
					newNormal= outNormal;
					if ((normalMap.x > -0.999 || normalMap.y > -0.999) && viewVector == viewVector){
						normalMap = mix(vec3(0.0, 0.0, 1.0), normalMap, smoothness);
						newNormal = mix(normalMap * tbnMatrix, newNormal, 1.0 - pow(1.0 - puddles, 4.0));
						newNormal = clampVec3Inv_11(normalize(newNormal));
					}
					#endif
				#endif

				#ifdef LAVA_NOISE
					if (lava > 0.5){
						vec3 npos = worldPos.xyz + cameraPosition.xyz + vec3(frameTimeCounter * 3.0 * 0.20, 0, 0);
						float n3da = texture2D(noisetex, npos.xz / 512.0 + floor(npos.y / 7.0) * 0.70).r;
						float n3db = texture2D(noisetex, npos.xz / 512.0 + floor(npos.y / 7.0 + 1.0) * 0.70).r;
						float noise = mix(n3da, n3db, fract(npos.y / 7.0));
						noise = noise * 30.0 * 0.05 + 0.1;
						albedo.rgb *= noise;
					}
				#endif

				#if (defined WATER_CAUSTICS && defined OVERWORLD)
					#include "/lib/lighting/causticsCall.glsl"
				#endif

				#ifdef SHOW_DARK_ZONES
					if (vanillaDiffuse > 0.99) {
						if(isLightSource < 0.5){
							albedo.rgb=showDarkZones(albedo.rgb);
						}
					}
				#endif

			} else {
				albedo = vec4(0.0);
			}

			/* RENDERTARGETS: 0 */
			#ifdef DEBUG_TERRAIN
            	gl_FragData[0]=vec4(0.0, 1.0, 0.949, 0.75);
			#else
				gl_FragData[0] = vec4(albedo);
			#endif

			#if (defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR)
				/* RENDERTARGETS: 0,3,6,1 */
				gl_FragData[1]=vec4(smoothness, skyOcclusion, 0.0, 1.0);
				gl_FragData[2]=vec4(EncodeNormal(newNormal), float(gl_FragCoord.z<1.0), 1.0);
				gl_FragData[3]=vec4(fresnel3, 1.0);
			#endif

		#ifdef DETECTEUR_CAVE
		}
		discard;
		#endif
	}
#endif