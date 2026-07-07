/*#############################################
#    _   ___ _____ ___    _   _    _____  __  #
#   /_\ / __|_   _| _ \  /_\ | |  | __\ \/ /  #
#  / _ \\__ \ | | |   / / _ \| |__| _| >  <   #
# /_/ \_\___/ |_| |_|_\/_/ \_\____|___/_/\_\  #
#											  #
#############################################*/

//Settings//////////////////Settings///////////////////Settings///////////////////Settings//

//#define DEBUG_HANDS

#include "/lib/util/functions.glsl"

#include "/settings/globalSettings.glsl"

//Varying////////////////////Varying////////////////////Varying////////////////////Varying//
varying float isMainHand;

varying vec2 texCoord, lmCoord;
varying vec3 sunVec, upVec, uSunVec, eastVec, normal;
varying vec4 color;

#ifdef ADVANCED_MATERIALS
varying vec3 binormal, tangent;
varying vec3 viewVector;
varying vec4 vTexCoord, vTexCoordAM;
#endif

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

	//Uniforms//
	uniform float frameTimeCounter;
	uniform int isEyeInWater;
	uniform vec3 cameraPosition;

	uniform mat4 gbufferModelViewInverse;
	uniform mat4 gbufferProjection;

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
		texCoord=(gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

		lmCoord  = GetLightMapCoordinates();
		lmCoord.x -= Max0(lmCoord.x - 0.825) * 0.75;

		normal = normalize(gl_NormalMatrix * gl_Normal);

		float underwaterHandMovementSpeed = 0.0;

		#ifdef ADVANCED_MATERIALS
			binormal =normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
			tangent  =normalize(gl_NormalMatrix * at_tangent.xyz);

			mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
								  tangent.y, binormal.y, normal.y,
								  tangent.z, binormal.z, normal.z);

			viewVector=tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;

			vec2 midCoord      =(gl_TextureMatrix[0] * mc_midTexCoord).xy;
			vec2 texMinMidCoord=texCoord - midCoord;

			vTexCoordAM.zw = abs(texMinMidCoord) * 2;
			vTexCoordAM.xy = min(texCoord, midCoord - texMinMidCoord);

			vTexCoord.xy = sign(texMinMidCoord) * 0.5 + 0.5;
		#endif

		isMainHand = float(gl_ModelViewMatrix[3][0]> 0.0);

		upVec = normalize(gbufferModelView[1].xyz);
		eastVec = normalize(gbufferModelView[0].xyz);
		uSunVec = GetuSunVec();
		sunVec = GetSunVec(uSunVec);

		vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

		if (isEyeInWater > 0.5){
			underwaterHandMovementSpeed = 0.5;
		}else{
			underwaterHandMovementSpeed = 1.0;
		}

		#ifdef MOUVEMENTS_MAINS
			position -= vec4(0.03 * sin(frameTimeCounter * 3.0 * SPEED_MOOVE * underwaterHandMovementSpeed), 0.015 * cos(frameTimeCounter * 4.0 * SPEED_MOOVE * underwaterHandMovementSpeed), 0.0, 0.0) * gbufferModelView;
		#endif

		#ifdef MOUVEMENTS_MAINS_2
			position.y += sin(frameTimeCounter * 3.0 * SPEED_MOOVE * underwaterHandMovementSpeed) * 0.015;
			position.z -= cos(frameTimeCounter * 4.0 * SPEED_MOOVE * underwaterHandMovementSpeed) * 0.0015;
		#endif

		position = gbufferModelView * position;

		position.z -= ADVANCE_HAND_POS;
		position.y += ADVANCE_HAND_POS2;
		position.x += DECALLAGE_MAINS;

		#ifdef WORLD_CURVATURE
			if (gl_ProjectionMatrix[2][2] < -0.5)position.y -= WorldCurvature(position.xz);
			gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
		#endif

		gl_Position = gl_ProjectionMatrix * position;

		color = gl_Color;
	}
#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

	//Uniforms//
	uniform int heldItemId, heldItemId2;
	uniform int frameCounter;
	uniform int isEyeInWater;
	uniform int moonPhase;
	#define UNIFORM_MOONPHASE

	uniform int heldBlockLightValue;
	uniform int heldBlockLightValue2;

	uniform float frameTimeCounter;
	uniform float nightVision;
	uniform float rainFactor;
	uniform float screenBrightness;
	uniform float viewWidth, viewHeight;

	#if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
		uniform float darknessFactor;
		uniform float darknessLightFactor;
	#endif

	uniform ivec2 eyeBrightnessSmooth;

	uniform mat4 gbufferProjectionInverse;
	uniform mat4 gbufferModelViewInverse;
	uniform mat4 shadowProjection;
	uniform mat4 shadowModelView;

	uniform sampler2D texture;
	uniform vec3 cameraPosition;

	uniform sampler2D noisetex;

	#ifdef ADVANCED_MATERIALS
		uniform ivec2 atlasSize;
		uniform sampler2D specular;
		uniform sampler2D normals;
	#endif

	uniform vec3 fogColor;

	//Common Variables//
	float eBS              =eyeBrightnessSmooth.y / 240.0;
	float sunVisibility    =clamp00125(dot( sunVec, upVec) + 0.0625) * 8.0;
	float moonVisibility   =clamp00125(dot( -sunVec,upVec) + 0.0625) * 8.0;
	float screenBrightness2=clamp01(screenBrightness);

	//Common Variables//

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

	float GetHandItem(int id){
		return float((heldItemId == id && isMainHand > 0.5) || (heldItemId2 == id && isMainHand < 0.5));
	}

	//Includes//
	#include "/lib/util/dither.glsl"
	#include "/lib/color/blocklightColor.glsl"
	#include "/lib/color/dimensionColor.glsl"
	#include "/lib/color/specularColor.glsl"
	#include "/lib/util/spaceConversion.glsl"

	#if (defined WATER_CAUSTICS && defined OVERWORLD)
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

	//Program//
	void main(){
		vec4 albedo = texture2D(texture, texCoord) * color;
		vec3 newNormal = normal;
		float smoothness = 0.0;

		#ifdef ADVANCED_MATERIALS

			vec2  newCoord    =vTexCoord.xy * vTexCoordAM.zw + vTexCoordAM.xy;
			float surfaceDepth=1.0;
			float skipAdvMat  =float(heldItemId == 358 ||(heldItemId2 == 358 && isMainHand < 0.5));

			#ifdef PARALLAX

			if (skipAdvMat < 0.5){
				newCoord = GetParallaxCoord(texCoord, 0.0, surfaceDepth);
				albedo = textureGrad(texture, newCoord, dcdx, dcdy) * color;
			}

			#endif

			float skyOcclusion = 0.0;
			vec3 fresnel3 = vec3(0.0);
		#endif

		if (albedo.a > 0.00001) {
			if (albedo.a > 0.99) albedo.a = 1.0;

			vec2 lightmap=clampVec2_01(lmCoord);

			float emissive=(GetHandItem(13001) + GetHandItem(13002) + GetHandItem(13003) + GetHandItem(13004) + GetHandItem(13005) + GetHandItem(13006) + GetHandItem(13007) + GetHandItem(13008) + GetHandItem(13009) + GetHandItem(13010) + GetHandItem(13011) + GetHandItem(13012));

			float metalness      =0.0;
			float emission       =emissive * 0.25;
			float subsurface     =0.0;
			vec3  baseReflectance=vec3(0.04);

			emission*=dot(albedo.rgb, albedo.rgb) * 0.333;

			vec3 screenPos=vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z + 0.38);
			vec3 viewPos  =ScreenToView(screenPos);
			vec3 worldPos =ViewToPlayer(viewPos);
			vec3 nViewPos = normalize(viewPos.xyz);

			#ifdef ADVANCED_MATERIALS

				float f0 = 0.0, porosity =0.5, ao = 1.0;
				vec3 normalMap = vec3(0.0, 0.0, 1.0);

				GetMaterials(smoothness, metalness, f0, emission, subsurface, porosity, ao, normalMap, newCoord, dcdx, dcdy);

				mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
									  tangent.y, binormal.y, normal.y,
									  tangent.z, binormal.z, normal.z);

				if ((normalMap.x > -0.999 || normalMap.y > -0.999) && viewVector == viewVector)
				newNormal = clampVec3Inv_11(normalize(normalMap.xyz * tbnMatrix));

			#endif

			albedo.rgb = pow(albedo.rgb, vec3(2.2));

			#ifdef WHITE_WORLD
				#ifdef HANDSW
					albedo.rgb = vec3(0.5);
				#endif
			#endif

			#ifdef BLACK_WORLD
				#ifdef HANDSW
					albedo.rgb = vec3(0.0);
				#endif
			#endif

			bool isBackface      = dot(normal, lightVec) < -0.0001;
			float NoL            = clamp01(dot(newNormal, lightVec) * 1.01 - 0.01);
			float NoU            = clampInv11(dot(newNormal, upVec));
			float NoE            = clampInv11(dot(newNormal, eastVec));
			float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
			      vanillaDiffuse*= vanillaDiffuse;

			float parallaxShadow = 1.0;

			#ifdef ADVANCED_MATERIALS
				vec3 rawAlbedo = albedo.rgb * 0.999 + 0.001;
				albedo.rgb *= pow2(ao);

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

					if (doParallax > 0.5 && skipAdvMat < 0.5){
						parallaxShadow = GetParallaxShadow(surfaceDepth, 0.0, newCoord, lightVec, tbnMatrix);
					}

				#endif
			#endif

			vec3 shadow = clamp01(vec3(0.0));
			GetLighting(albedo.rgb, shadow, viewPos, worldPos, lightmap, 1.0, NoL, vanillaDiffuse,
			parallaxShadow, emission, subsurface, true, true, true, true);

			#ifdef ADVANCED_MATERIALS
				skyOcclusion = Smooth3(lightmap.y);

				      baseReflectance=mix(vec3(f0), rawAlbedo, metalness);
				float fresnel        =pow(clamp01(1.0 + dot(newNormal, nViewPos)), 5.0);

				fresnel3 = mix(baseReflectance, vec3(1.0), fresnel);

				#if MATERIAL_FORMAT ==1
					if (f0 >= 0.9 && f0 < 1.0) {
						baseReflectance=GetMetalCol(f0);
						fresnel3       =ComplexFresnel(pow(fresnel, 0.2), f0);
					}
				#endif

				float aoSquared = pow2(ao);
				shadow *= aoSquared; fresnel3 *= aoSquared;
				albedo.rgb = albedo.rgb * (1.0 - fresnel3 * pow2(smoothness) * (1.0 - metalness));

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

			#if (defined WATER_CAUSTICS && defined OVERWORLD)
			#include "/lib/lighting/causticsCall.glsl"
			#endif

		} else discard;

		/* RENDERTARGETS: 0 */
		#ifdef DEBUG_HANDS
            gl_FragData[0]=vec4(1.0, 0.451, 0.0, 0.75);
		#else
			gl_FragData[0] = clampVec4_01(albedo);
		#endif

		#if (defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR)
		/* RENDERTARGETS: 0,3,6,1 */
		gl_FragData[1]=vec4(smoothness, skyOcclusion, 0.0, 1.0);
		gl_FragData[2]=vec4(EncodeNormal(newNormal),float(gl_FragCoord.z<1.0),1.0);
		gl_FragData[3]=vec4(fresnel3,1.0);

		#endif
	}

#endif