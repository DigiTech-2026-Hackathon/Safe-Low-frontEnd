/*#############################################
#    _   ___ _____ ___    _   _    _____  __  #
#   /_\ / __|_   _| _ \  /_\ | |  | __\ \/ /  #
#  / _ \\__ \ | | |   / / _ \| |__| _| >  <   #
# /_/ \_\___/ |_| |_|_\/_/ \_\____|___/_/\_\  #
#											  #
#############################################*/

//Settings//////////////////Settings///////////////////Settings///////////////////Settings//

//#define DEBUG_ENTITIES

#include "/lib/util/functions.glsl"

#include "/settings/globalSettings.glsl"

//Varying////////////////////Varying////////////////////Varying////////////////////Varying//

varying float mat;

#if PLAYER_MOTION_BLUR == 0
varying float isPlayer;
#endif

varying vec2 texCoord, lmCoord;
varying vec3 sunVec, upVec, uSunVec, eastVec, normal;
varying vec4 color;

#ifdef ADVANCED_MATERIALS
	varying float dist;

	varying vec3 viewVector;
	varying vec3 binormal, tangent;

	varying vec4 vTexCoord, vTexCoordAM;
#endif

#ifdef GBUFFERS_ENTITIES_GLOWING
	varying float realDepth;
#endif

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

	//Uniforms//
	uniform int entityId;

	#if MOUVEMENT_CAM > 0
	uniform float frameTimeCounter;
	uniform float onGroundSmooth;
	#endif
	uniform int heldItemId;
	uniform int heldItemId2;
	uniform vec3 cameraPosition;

	uniform mat4 gbufferModelViewInverse;

	//Attributes//

	#ifdef ADVANCED_MATERIALS
		attribute vec4 mc_midTexCoord;
		attribute vec4 at_tangent;
	#endif

	//Includes//

	#ifdef WORLD_CURVATURE
	#include "/lib/vertex/worldCurvature.glsl"
	#endif

	//Program//
	void main(){
		texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

		lmCoord  = GetLightMapCoordinates();
		lmCoord.x = min(lmCoord.x, 0.9);

		normal=normalize(gl_NormalMatrix*gl_Normal);

		mat = 0.0;

		#if PLAYER_MOTION_BLUR == 0
		isPlayer = 0.0;
		#endif

		if (entityId == 12000){
			mat = 1.0;
		}
		else if (entityId == 18213){
			mat = 2.0;
		}
		else if (entityId == 18214) {
			mat = 3.0;
		}
		else if (entityId == 18215) {
			mat = 4.0;
		}
		else if (entityId == 18216) {
			mat = 5.0;
		}
		else if (entityId == 18217) {
			mat = 6.0;
		}
		else if (entityId == 18218) {
			mat = 7.0;
		}
		else if (entityId == 12001) {
			mat = 8.0;
		}
		else if (entityId == 18219) {
			mat = 9.0;
		}
		#if PLAYER_MOTION_BLUR == 0
		else if (entityId == 10316) {
			isPlayer = 1.0;
		}
		#endif

		#ifdef ADVANCED_MATERIALS
			tangent =normalize(gl_NormalMatrix * at_tangent.xyz);
			binormal=normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);

			mat3 tbnMatrix=mat3(tangent.x,binormal.x,normal.x,
								tangent.y,binormal.y,normal.y,
								tangent.z,binormal.z,normal.z);

			viewVector=tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;

			dist=length(gl_ModelViewMatrix * gl_Vertex);

			vec2 midCoord      =(gl_TextureMatrix[0] * mc_midTexCoord).xy;
			vec2 texMinMidCoord=texCoord - midCoord;

			vTexCoordAM.zw=abs(texMinMidCoord) * 2;
			vTexCoordAM.xy=min(texCoord, midCoord - texMinMidCoord);
			vTexCoord.xy=sign(texMinMidCoord) * 0.5 + 0.5;

		#endif

		color=gl_Color;

		upVec  =normalize(gbufferModelView[1].xyz);
		eastVec=normalize(gbufferModelView[0].xyz);
		uSunVec = GetuSunVec();
		sunVec = GetSunVec(uSunVec);

		vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

		#ifdef WORLD_CURVATURE
			position.y -= WorldCurvature(position.xz);
			gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
		#else
			gl_Position = ftransform();
		#endif

		if (entityId == 10312) {
			if (dot(normal, upVec) > 0.99) {
				vec3 LexPos  =fract(position.xyz + cameraPosition);
					 LexPos  =abs(LexPos - vec3(0.5));
				if ((LexPos.y > 0.437 && LexPos.y < 0.438) || (LexPos.y > 0.468 && LexPos.y < 0.469)) {
					gl_Position.z+=0.0001;
				}
			}
			if (gl_Normal.y == 1.0) {
				normal = upVec * 2.0;
			}
		} else if (entityId == 18218) { // Slime
			gl_Position.z -= 0.00015;
		} else if (entityId == 10315) { // Frog
			gl_Position.z -= 0.0001;
		}

		if (color.a < 0.5) gl_Position.z += 0.0005;

		#ifdef GBUFFERS_ENTITIES_GLOWING
			realDepth = gl_Position.z / gl_Position.w;
			gl_Position.z = 0.0;
		#endif

		#if MOUVEMENT_CAM > 0
			gl_Position += vec4(0.03 * sin(frameTimeCounter * 3.0 * SPEED_MOOVE), 0.015 * cos(frameTimeCounter * 4.0 * SPEED_MOOVE), 0.0, 0.0) * gl_ProjectionMatrix * onGroundSmooth;
		#endif
	}

#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

	//Uniforms//
	uniform int entityId;
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

	uniform vec3 cameraPosition;
	uniform vec4 entityColor;

	uniform mat4 gbufferProjectionInverse;
	uniform mat4 gbufferModelViewInverse;
	uniform mat4 shadowProjection;
	uniform mat4 shadowModelView;

	uniform sampler2D texture;
	uniform sampler2D noisetex;

	#ifdef GBUFFERS_ENTITIES_GLOWING
	uniform sampler2D depthtex0;
	#endif

	uniform ivec2 atlasSize;

	#ifdef ADVANCED_MATERIALS
		uniform sampler2D specular;
		uniform sampler2D normals;
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

	//Includes//
	#include "/lib/color/blocklightColor.glsl"
	#include "/lib/color/dimensionColor.glsl"
	#include "/lib/color/specularColor.glsl"
	#include "/lib/util/dither.glsl"
	#include "/lib/util/spaceConversion.glsl"

	#if (defined OVERWORLD && defined WATER_CAUSTICS)
	#include "/lib/color/waterColor.glsl"
	#include "/lib/lighting/caustics.glsl"
	#endif

	#include "/lib/lighting/forwardLighting.glsl"

	#ifdef ADVANCED_MATERIALS
	#include "/lib/util/encode.glsl"
	#include "/lib/surface/ggx.glsl"
	#include "/lib/reflections/complexFresnel.glsl"
	#include "/lib/surface/materialGbuffers.glsl"
	#include "/lib/surface/parallax.glsl"
	#endif

	#ifdef TECHNO_XP
	#include "/lib/color/hue.glsl"
	#endif

	#if ENTITY_FLASH == 2
	#include "/lib/color/entitiesflash.glsl"
	#endif

	//Program//
	void main(){

		vec4 multiplier = color;

		if (entityId == 10002 && color.g > color.b + 0.1) {

			#ifdef TECHNO_XP

				float variant = floor(texCoord.x * 4.0) + floor(texCoord.y * 4.0) * 4.0;
				multiplier = vec4(hue2(frameTimeCounter * 0.5 + variant * 0.1), 1.0);

				#ifndef ADVANCED_MATERIALS
				multiplier.rgb *=XP_ORB_INTENSITY;
				#else
				multiplier.rgb *=XP_ORB_INTENSITY;
				#endif

			#else

			multiplier.a = 1.0;

			#endif
		}

		vec4 albedo = texture2D(texture, texCoord) * multiplier;

		vec3  newNormal    =normal;
		vec3  fresnel3     = vec3(0.0);
		float smoothness   =0.0;
		float isGlowing    =0.0;
		float skyOcclusion =0.0;

		#ifdef ADVANCED_MATERIALS
			vec2  newCoord    =vTexCoord.xy * vTexCoordAM.zw + vTexCoordAM.xy;
			float surfaceDepth=1.0;
			float parallaxFade=clamp01((dist - PARALLAX_DISTANCE) / 32.0);

			float skipAdvMat  =float(entityId == 10002 || entityId == 10312);

			#ifndef PARALLAX_ENTITY
				skipAdvMat += float(entityId == 12001 || entityId == 10316|| entityId == 10315 || entityId == 10314 || entityId == 11111 || entityId == 12000 || entityId == 18213 || entityId == 18214 || entityId == 18215 || entityId == 0);
			#endif

			#ifdef PARALLAX
				if (skipAdvMat < 0.5 ){

					newCoord = GetParallaxCoord(texCoord, parallaxFade, surfaceDepth);
					albedo = textureGrad(texture, newCoord, dcdx, dcdy) * multiplier;
				}
			#endif
		#endif

		#if ENTITY_FLASH == 1
			albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
		#elif ENTITY_FLASH == 2
			albedo.rgb = mix(albedo.rgb, clamp01(entitiesFlashCol.rgb), entityColor.a);
		#endif

		float emission     =float(entityColor.a > 0.05) * 0.125;

		float lightningBolt=float(entityId == 22258);

		if (lightningBolt > 0.5) {

			#if defined (OVERWORLD)
			albedo.rgb = vec3(0.8, 0.85, 0.9) / weatherCol.a;
			emission = 0.25;
			#elif defined (NETHER)
			albedo.rgb = sqrt(netherCol.rgb / netherCol.a);
			emission = 0.35;
			#elif defined (END)
			albedo.rgb = endCol.rgb / endCol.a;
			emission = 0.15;
			#endif
			albedo.a = 1.1;
		}

		float fragAlpha = 1.0;
		#ifdef GBUFFERS_ENTITIES_GLOWING

			if (albedo.a > 0.99) isGlowing = 1.0;

			float backDepth = texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).r * 2.0 - 1.0;

			if(backDepth >= realDepth){
				gl_FragDepth = realDepth * 0.5 + 0.5;
			}
			else{
				gl_FragDepth = backDepth * 0.5 + 0.5;
				fragAlpha = 0.0;
				albedo.a  = 0.00001;
			}
		#endif

		if (albedo.a > 0.00001 && lightningBolt < 0.5){
			if (albedo.a > 0.99) albedo.a = 1.0;

			float metalness      =0.0;
			vec2  lightmap       =clampVec2_01(lmCoord);

			#ifdef GBUFFERS_ENTITIES_GLOWING
			vec3 screenPos   = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), realDepth);
			#else
			vec3 screenPos   = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
			#endif

			vec3  viewPos        =ScreenToView(screenPos);
			vec3  worldPos       =ViewToPlayer(viewPos);
			float lViewPos       =length(viewPos.xyz);
			vec3  nViewPos 	     = normalize(viewPos.xyz);
			vec3  baseReflectance=vec3(0.04);
			float lAlbedo 	     = length(albedo.rgb);

			#ifdef SSS_ON_ENTITY
				float subsurface =float(entityId == 18218 || entityId == 18217 || entityId == 10316 || entityId == 10314 || entityId == 10315) * SSS_ENTITIES_STRENGTH * 0.25;
			#else
				float subsurface = 0.0;
			#endif

			emission *= dot(albedo.rgb, albedo.rgb) * 0.333;

			/*
			Shulker
			*/
				if (mat > 6.98 && mat < 7.02){
					emission = float(lAlbedo > 1.1) * 0.5;
				}

			#if ENTITY_FLASH == 0
			float entityID = 0;
			if (entityID == 12001 || entityId == 18218 || entityId == 18217 || entityId == 10316 || entityId == 10315 || entityId == 10314 || entityId == 11111 || entityId == 12000 || entityId == 18213 || entityId == 18214 || entityId == 18215) {
				emission = 0.0;
			}
			#endif

			#ifdef FLASH_VICTIME

				bool flash = false;

				#ifdef FLASH_SWORD
					if ((heldItemId == 10278)||(heldItemId == 10267)||(heldItemId == 10268)||(heldItemId == 10272)||(heldItemId == 10276)||(heldItemId == 10283)||
						(heldItemId2 == 10278)||(heldItemId2 == 10267)||(heldItemId2 == 10268)||(heldItemId2 == 10272)||(heldItemId2 == 10276)||(heldItemId2 == 10283))
					flash = true;
				#endif
				#ifdef FLASH_AXE
					if ((heldItemId == 10746)||(heldItemId == 10279)||(heldItemId == 10286)||(heldItemId == 10258)||(heldItemId == 10275)||(heldItemId == 10271)||
						(heldItemId2 == 10746)||(heldItemId2 == 10279)||(heldItemId2 == 10286)||(heldItemId2 == 10258)||(heldItemId2 == 10275)||(heldItemId2 == 10271))
						flash = true;
				#endif
				#ifdef FLASH_BOW
					if ((heldItemId == 10262)||(heldItemId == 10261)||
						(heldItemId2 == 10262)||(heldItemId2 == 10261))
						flash = true;
				#endif
				#ifdef FLASH_TRIDENT
					if ((heldItemId == 19999)||
						(heldItemId2 == 19999))
						flash = true;
				#endif
				#ifdef FLASH_SNOWBALL
					if ((heldItemId == 10332)||
						(heldItemId2 == 10332))
						flash = true;
				#endif
				#ifdef FLASH_FISHING
					if ((heldItemId == 10346)||
						(heldItemId2 == 10346))
						flash = true;
				#endif
				#ifdef FLASH_EGG
					if ((heldItemId == 10344)||
						(heldItemId2 == 10344))
						flash = true;
				#endif
				#ifdef MACE
					if ((heldItemId == 10277)||
						(heldItemId2 == 10277))
						flash = true;
				#endif

				#ifdef DISABLE_FLASH_ENTITY_PLAYERS
					if (entityId==10316){
						flash = false;
					}
				#endif

					if(flash)
					{
						if (entityId != 10311 && entityId != 10312 && entityId != 10313 && entityId != 10002) {

							float oscillation = 0.0;
							float intensity = 0.0;

							#ifdef OSCILLATION
							oscillation = sin(frameTimeCounter * OSCILLATION_SPEED);
							oscillation = oscillation * oscillation;
							#endif

							#if defined(OVERWORLD)
							intensity = INTENSITE_FLASH_VICTIME_O * 0.01;
							#elif defined(NETHER)
							intensity = INTENSITE_FLASH_VICTIME_N * 0.05;
							#elif defined(END)
							intensity = INTENSITE_FLASH_VICTIME_E * 0.05;
							#endif

							emission = mix(intensity, emission, oscillation);

						}
					}
			#endif

			/*
			Drowned
			*/
				if (mat > 0.98 && mat < 1.02 && atlasSize.x < 900.0){
					if (
						CheckForColor(albedo.rgb, vec3(143, 241, 215))||
						CheckForColor(albedo.rgb, vec3(49, 173, 183)) ||
						CheckForColor(albedo.rgb, vec3(101, 224, 221))
					   )
					emission = 1.0;
				} else

			/*
			Glow Squid
			*/
				if (mat > 1.98 && mat < 2.02){
					lightmap.x *= 0.0;
					emission = lAlbedo * lAlbedo * 0.25;
					emission *= emission;
					emission *= emission;
					emission = max(emission * 10.0, 0.01);

					if (emission > 0.011) {
						float glowFactor = abs(fract(frameTimeCounter * 0.25 + worldPos.y * 0.0125) - 0.5) * 2.0;
						glowFactor = pow(glowFactor, 2.5);
						glowFactor = 0.002 + 0.998 * glowFactor;
						emission *= glowFactor;
					}

				} else

			/*
			Warden
			*/
				if (mat > 2.98 && mat < 3.02){
					emission = float(albedo.b > 0.5 && length(albedo.rgb) > 0.7 && albedo.r < 0.25) * 2.0 * clamp01(length(albedo.rgb));
				} else

			/*
			Blaze
			*/
				if (mat > 3.98 && mat < 4.02){
					lightmap.x *= 1.0;
					emission = float(lAlbedo > 1.7);
				} else

			/*
			End Crystal
			*/
				if (mat > 4.98 && mat < 5.02) {
					lightmap.x *= 0.85;
					emission =float(albedo.r * 2.0 > albedo.b + albedo.g) * 2.5;
				} else

			/*
			Allay
			*/
				if (mat > 5.98 && mat < 6.02) {
				if (atlasSize.x < 900) {
					emission = float(albedo.r > 0.9) * 0.7 + 0.02;
					lightmap = vec2(0.75);
					}
				}

			/*
			Breeze
			*/
				if (mat > 8.98 && mat < 9.02) {
				if (atlasSize.x < 900) {
					emission = float(albedo.r > 0.9) * 0.9 + 0.02;
					lightmap = vec2(0.15);
					emission *= 0.09;
					}
				}


			#ifdef ADVANCED_MATERIALS

				float f0 = 0.0, porosity = 0.5, ao = 1.0;
				vec3 normalMap = vec3(0.0, 0.0, 1.0);
				GetMaterials(smoothness, metalness, f0, emission, subsurface, porosity, ao, normalMap, newCoord, dcdx, dcdy);

				mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
									  tangent.y, binormal.y, normal.y,
									  tangent.z, binormal.z, normal.z);

				if ((normalMap.x > -0.999 || normalMap.y > -0.999) && viewVector == viewVector && skipAdvMat < 0.5)
				newNormal = clampVec3Inv_11(normalize(normalMap.xyz * tbnMatrix));

			#endif

			albedo.rgb = pow(albedo.rgb, vec3(2.2));

			#ifdef WHITE_WORLD
				#ifdef ENTITIESW
					albedo.rgb = vec3(0.5);
				#endif
			#endif

			#ifdef BLACK_WORLD
				#ifdef ENTITIESW
					albedo.rgb = vec3(0.0);
				#endif
			#endif

			bool isBackface      = dot(normal, lightVec) < -0.0001;
			float NoL            = clamp01(dot(newNormal, lightVec) * 1.01 - 0.01);
			float NoU            = clampInv11(dot(newNormal, upVec));
			float NoE            = clampInv11(dot(newNormal, eastVec));
			float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
			      vanillaDiffuse*=vanillaDiffuse;

			float parallaxShadow = 1.0;

			#ifdef ADVANCED_MATERIALS
				vec3 rawAlbedo = albedo.rgb * 0.999 + 0.001;
				albedo.rgb *= ao;

				#ifdef REFLECTION_SPECULAR
					albedo.rgb *= (1.0 - metalness * 0.45);
				#endif

				float doParallax = 0.0;

				#ifdef SELF_SHADOW

					#if defined (OVERWORLD)
						doParallax = float(lightmap.y > 0.0 && NoL > 0.0);
					#elif defined (END)
						doParallax = float(NoL > 0.0);
					#endif

					if (doParallax > 0.5){
						parallaxShadow = GetParallaxShadow(surfaceDepth, parallaxFade, newCoord, lightVec, tbnMatrix);
					}

				#endif
			#endif

			vec3 shadow = vec3(0.0);

			if (entityId != 10002){
			GetLighting(albedo.rgb, shadow, viewPos, worldPos, lightmap, 1.0, NoL, vanillaDiffuse,
			parallaxShadow, emission, subsurface, true, true, true, true);
			}

			#ifdef ADVANCED_MATERIALS

				skyOcclusion= Smooth3(lightmap.y);

				baseReflectance=mix(vec3(f0), rawAlbedo, metalness);

				float fresnel =pow(clamp01(1.0 + dot(newNormal, nViewPos)), 5.0);

				fresnel3 = mix(baseReflectance, vec3(1.0), fresnel);

				#if MATERIAL_FORMAT == 1

					if (f0 >= 0.9 && f0 < 1.0) {
						baseReflectance = GetMetalCol(f0);
						fresnel3 = ComplexFresnel(pow(fresnel, 0.2), f0);
					}

				#endif

				float aoSquared  = pow2(ao);
				      shadow    *=aoSquared; fresnel3*=aoSquared;
				      albedo.rgb =albedo.rgb * (1.0 - fresnel3 * pow2(smoothness) * (1.0 - metalness));

				#if ((defined OVERWORLD || defined END) && (defined ADVANCED_MATERIALS || defined SPECULAR_HIGHLIGHT_ROUGH))

					vec3 specularColor = GetSpecularColor(lightmap.y, metalness, baseReflectance);

					vec3 GetSpecularHighlight = GetSpecularHighlight(newNormal, viewPos, lightVec, smoothness, baseReflectance, specularColor, shadow * vanillaDiffuse, 1.0);

					if (isEyeInWater == 0) GetSpecularHighlight *= pow(lightmap.y, 2.5);

					if (!isBackface)
					albedo.rgb += GetSpecularHighlight;


				#endif

				#if (defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR && defined REFLECTION_ROUGH)

					normalMap = mix(vec3(0.0, 0.0, 1.0), normalMap, smoothness);
					newNormal = clampVec3Inv_11(normalize(normalMap * tbnMatrix));

				#endif

			#endif

			#if (defined OVERWORLD && defined WATER_CAUSTICS)
			#include "/lib/lighting/causticsCall.glsl"
			#endif

			#ifdef END
				albedo.rgb = pow(albedo.rgb, vec3(0.9));
			#endif

		}

		/* RENDERTARGETS: 0,3,7 */
		#ifdef DEBUG_ENTITIES
        gl_FragData[0]=vec4(1.0, 0.0, 0.0, 0.75);
		#else
		gl_FragData[0] = vec4(albedo);
		#endif

		gl_FragData[1] = vec4(smoothness, skyOcclusion, 1.0, fragAlpha);
		gl_FragData[2] = vec4(vec3(1.0), fragAlpha);

		#if PLAYER_MOTION_BLUR == 0
		/* RENDERTARGETS: 0,3,7,8 */
		gl_FragData[3] = vec4(0.0, isPlayer, 0.0, fragAlpha);
		#endif

		#if (defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR)
			#ifdef GBUFFERS_ENTITIES_GLOWING
			float realPosition = gl_FragDepth;
			#else
			float realPosition = gl_FragCoord.z;
			#endif

			#if PLAYER_MOTION_BLUR == 0
			/* RENDERTARGETS: 0,3,7,8,6,1,13 */
			gl_FragData[4] = vec4(EncodeNormal(newNormal), float(realPosition < 1.0), fragAlpha);
			gl_FragData[5] = vec4(fresnel3, fragAlpha);
			gl_FragData[6] = vec4(isGlowing, 0.0, 0.0, 1.0);
			#else
			/* RENDERTARGETS: 0,3,7,6,1,13 */
			gl_FragData[3] = vec4(EncodeNormal(newNormal), float(realPosition < 1.0), fragAlpha);
			gl_FragData[4] = vec4(fresnel3, fragAlpha);
			gl_FragData[5] = vec4(isGlowing, 0.0, 0.0, 1.0);
			#endif
		#else
			#if PLAYER_MOTION_BLUR == 0
			/* RENDERTARGETS: 0,3,7,8,13 */
			gl_FragData[4] = vec4(isGlowing, 0.0, 0.0, 1.0);
			#else
			/* RENDERTARGETS: 0,3,7,13 */
			gl_FragData[3] = vec4(isGlowing, 0.0, 0.0, 1.0);
			#endif
		#endif

	}

#endif