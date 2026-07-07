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
varying vec2 texCoord;
varying vec3 sunVec, upVec, uSunVec, eastVec;

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

	//Program//
	void main(){
		texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

		gl_Position=ftransform();

		upVec = normalize(gbufferModelView[1].xyz);
		eastVec = normalize(gbufferModelView[0].xyz);
		uSunVec = GetuSunVec();
		sunVec = GetSunVec(uSunVec);

	}

#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

	//Uniforms//
	uniform sampler2D noisetex;

	uniform int frameCounter;
	uniform int isEyeInWater;

	#ifndef WEATHER_PERBIOME
		uniform float isSnowy;
	#endif

	uniform float blindFactor, darknessFactor, nightVision;
	uniform float far, near;
	uniform float frameTimeCounter;
	uniform float rainStrength;
	uniform float rainFactor;
	uniform float screenBrightness;
	uniform float viewWidth, viewHeight, aspectRatio;
	uniform float eyeAltitude;

	#ifdef UNDERGROUND_SKY
	uniform float isEyeInCave;
	#endif

	uniform int moonPhase;
	#define UNIFORM_MOONPHASE

	uniform ivec2 eyeBrightnessSmooth;

	uniform vec3 cameraPosition;

	uniform mat4 gbufferProjection, gbufferPreviousProjection, gbufferProjectionInverse;
	uniform mat4 gbufferModelView, gbufferPreviousModelView, gbufferModelViewInverse;
	uniform mat4 shadowProjection;
	uniform mat4 shadowModelView;

	uniform vec3 moonPosition;
	uniform vec3 skyColor;
	uniform vec3 fogColor;

	uniform sampler2D colortex0;

	#if (defined ADVANCED_MATERIALS || defined AO)
	uniform sampler2D colortex3;
	#endif

	#ifdef GLOWING_ENTITY_FIX
	uniform sampler2D colortex13;
	#endif

	uniform sampler2D depthtex0;
	uniform sampler2D depthtex1;

	#if (defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR)
	uniform vec3 previousCameraPosition;

	uniform sampler2D colortex6;
	uniform sampler2D colortex1;
	#endif

	//Optifine Constants//

	#if (defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR)
	const bool colortex0MipmapEnabled = true;
	const bool colortex6MipmapEnabled = true;
	#endif

	//Common Variables//
	float eBS = eyeBrightnessSmooth.y / 240.0;
	float sunVisibility  = clamp00125(dot( sunVec, upVec) + 0.0625) * 8.0;
	float moonVisibility = clamp00125(dot( -sunVec, upVec) + 0.0625) * 8.0;
	float screenBrightness2 = clamp01(screenBrightness);

	vec3 lightVec = sunVec * (1.0 - 2.0 * float(timeAngle > 0.5325 && timeAngle < 0.9675));

	float GetNoise(vec2 pos){
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.54953);
	}

	//Common Functions//
	#ifdef AO
	float GetLinearDepth(float depth) {
		return (2.0 * near) / (far + near - depth * (far - near));
	}

	float BlueNoise(vec2 coord) {
		return texelFetch(noisetex, ivec2(coord)% 64, 0).b;
	}

		float farMinusNear = far - near;

		vec2 OffsetDist(float x, int s) {
		float n = fract(x * 1.414) * 3.1415;
		return pow2(vec2(cos(n), sin(n)) * x / s);
		}

		float DoAmbientOcclusion(float z0, float linearZ0, float dither) {
			if (z0 < 0.56) return 1.0;
			float ao = 0.0;
			float fovScaleAO = 0.0;
			float radius = 0.5;
			int samples = 0;
			float scm = 0.0;

			float sampleDepth = 0.0, angle = 0.0, dist = 0.0;

			#if AO_FOVSCALE ==1
				fovScaleAO = 3.425;
			#elif AO_FOVSCALE ==2
				fovScaleAO = 2.74;
			#elif AO_FOVSCALE ==3
				fovScaleAO = 2.055;
			#elif AO_FOVSCALE ==4
				fovScaleAO = 1.37;
			#elif AO_FOVSCALE ==5
				fovScaleAO = 0.685;
			#endif

			#if AO_QUALITY == 1
				samples = 4;
				scm = 0.4;
			#elif AO_QUALITY == 2
				samples = 12;
				scm = 0.6;
			#endif

			float fovScale = gbufferProjection[1][1] / fovScaleAO;
			float distScale = max(farMinusNear * linearZ0 + near, 3.0);
			vec2 scale = radius * vec2(scm / aspectRatio, scm) * fovScale / distScale;

			for (int i = 1; i <= samples; i++) {
				vec2 offset = OffsetDist(i + dither, samples) * scale;
				if (i % 2 == 0) offset.y = -offset.y;

				vec2 coord1 = texCoord + offset;
				vec2 coord2 = texCoord - offset;

				sampleDepth = GetLinearDepth(texture2D(depthtex0, coord1).r);
				float aosample = farMinusNear * (linearZ0 - sampleDepth) * 2.0;
				angle = clamp(0.5 - aosample, 0.0, 1.0);
				dist = clamp(0.5 * aosample - 1.0, 0.0, 1.0);

				sampleDepth = GetLinearDepth(texture2D(depthtex0, coord2).r);
				aosample = farMinusNear * (linearZ0 - sampleDepth) * 2.0;
				angle += clamp(0.5 - aosample, 0.0, 1.0);
				dist += clamp(0.5 * aosample - 1.0, 0.0, 1.0);

				ao += clamp(angle + dist, 0.0, 1.0);
			}
			ao *= 1.0 / float(samples);
			ao *= sqrt(ao) * 0.9 + 0.1;

				return pow(ao, AO_STRENGTH * 2.0);
		}
	#endif

	//Includes//

	#ifdef END
	#include "/lib/color/lightColor.glsl"
	#endif

	#include "/lib/color/dimensionColor.glsl"
	#include "/lib/color/skyColor.glsl"
	#include "/lib/color/blocklightColor.glsl"
	#include "/lib/color/waterColor.glsl"
	#include "/lib/util/dither.glsl"
	#include "/lib/util/spaceConversion.glsl"

	#if (defined OVERWORLD || defined END)
	#include "/lib/atmospherics/sky.glsl"
	#endif

	#include "/lib/atmospherics/fog.glsl"
	#include "/lib/atmospherics/waterFog.glsl"

	#ifdef FULL_BORDER
	#include "/lib/outline/fullBorder.glsl"
	#endif

	#ifdef OUTLINE_ENABLED
	#include "/lib/outline/outlineOffset.glsl"
	#include "/lib/outline/blackOutline.glsl"
	#endif

	#if defined GLOWING_ENTITY_FIX || AURORA_COLOR == 5 || defined GLOWING_ENTITY_RGB
	#include "/lib/color/hue.glsl"
	#endif

	#if ((defined AURORA && defined OVERWORLD) || (defined AURORA_END && defined END))
	#include "/lib/atmospherics/aurora.glsl"
	#endif

	#if (defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR)
	#include "/lib/util/encode.glsl"
	#include "/lib/reflections/complexFresnel.glsl"
	#include "/lib/surface/materialDeferred.glsl"
	#include "/lib/reflections/roughReflections.glsl"
	#endif

	#if REALISTIC_CLOUDS == 1 && defined OVERWORLD
	#include "/lib/atmospherics/ovclouds.glsl"
	#endif

	#ifdef END
		#ifdef END_STARS
		#include "/lib/atmospherics/endstars.glsl"
		#endif

		#ifdef LOST_GLARE
		#include "/lib/atmospherics/lostglare.glsl"
		#endif

		#if defined END && defined BLACK_HOLE
		#include "/lib/atmospherics/vortex.glsl"
		#endif

		#ifdef SHOOTING_STARS_END
		#include "/lib/atmospherics/shootingstars.glsl"
		#endif

		#ifdef FBM
		#include "/lib/atmospherics/fbm.glsl"
		#endif
	#endif

	//Program//
	void main() {
		vec4 color  = texture2D(colortex0, texCoord);
		float z     = texture2D(depthtex0, texCoord).r;
		float ao 	= 1.0;

		float dither= Bayer8(gl_FragCoord.xy);
	    	  dither= animateDither(dither);

		#ifdef AO
			float aoDither = BlueNoise(gl_FragCoord.xy);
				  aoDither = animateDither(aoDither);
		#endif

		vec4 screenPos =vec4(texCoord, z, 1.0);
		vec4 viewPos   =gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
		     viewPos  /=viewPos.w;

		vec3 nViewPos=normalize(viewPos.xyz);
		vec3 worldPos=ViewToPlayer(viewPos.xyz);
		vec4 cloud = vec4(0.0);
		float NdotS = clamp01(dot(nViewPos, sunVec));

		#ifdef OUTLINE_ENABLED
			vec4 outerOutline = vec4(0.0), innerOutline = vec4(0.0);
			Outline(color.rgb, false, outerOutline, innerOutline);

			color.rgb = mix(color.rgb, innerOutline.rgb, innerOutline.a);
		#endif


		if (z < 1.0){

			#ifdef AO
			float linearZ = GetLinearDepth(z);
			float ao = DoAmbientOcclusion(z, linearZ, aoDither);
			#endif

			#ifdef GLOWING_ENTITY_FIX
				float isGlowing = texture2D(colortex13, texCoord).r;
			#endif

			#if (defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR)
				float smoothness = 0.0, skyOcclusion = 0.0;
				vec3 normal = vec3(0.0), fresnel3 = vec3(0.0);

				GetMaterials(smoothness, skyOcclusion, normal, fresnel3, texCoord);
				float smoothnessP = smoothness;

				if (smoothness > 0.0){
					vec4 reflection   =vec4(0.0);
					vec3 skyReflection=vec3(0.0);

					float cloudMixRate= 1.0;
					float ssrMask = clamp01(length(fresnel3) * 400 - 1.0);
					if(ssrMask > 0.0){

					#ifdef REFLECTION_ROUGH
						float roughness=1.0 - smoothnessP;

						roughness*=roughness;
						roughness*=roughness;

						vec3 roughPos   =worldPos + cameraPosition;
							 roughPos  *=1000.0;
						vec3 roughNoise =texture2D(noisetex, roughPos.xz + roughPos.y).rgb;
							 roughNoise =ROUGH_NOISE * (roughNoise - vec3(0.5));

						     roughNoise*= roughness;
							 roughNoise*= roughness;

						normal    +=roughNoise;
						reflection =RoughReflection(viewPos.xyz, normal, dither, smoothness);
					#else
						reflection =RoughReflection(viewPos.xyz, normal, dither, smoothness);
					#endif

					reflection.a *= ssrMask;
					}

					if (reflection.a < 1.0){
						vec3 skyRefPos    =reflect(nViewPos, normal);

						#if defined (OVERWORLD)

							skyReflection=GetSkyColor(skyRefPos, true);

							#ifdef REFLECTION_ROUGH
								cloudMixRate = smoothness * smoothness * (3.0 - 2.0 * smoothness);
							#endif

							#ifdef METAL_AURORA_REFLECTION
								#ifdef AURORA
								if (moonVisibility > 0.0){
									skyReflection+=DrawAurora(skyRefPos * 100.0, dither, 15) * (AURORA_REFLECTION_STRENGTH * 2.0) * cloudMixRate;
								}
								#endif
							#endif

							#ifdef METAL_CLOUDS_REFLECTION
								#if REALISTIC_CLOUDS == 1
										cloud        =DrawCloud(skyRefPos * 100.0, dither, lightCol, ambientCol, 4);
										skyReflection=mix(skyReflection, cloud.rgb, cloud.a * cloudMixRate);
								#endif
							#endif

							float NoU            =clampInv11(dot(normal, upVec));
							float NoE            =clampInv11(dot(normal, eastVec));
							float vanillaDiffuse =(0.25 * NoU + 0.75) + (0.5 - abs(NoE)) * (1.0 - abs(NoU)) * 0.1;
								vanillaDiffuse*=vanillaDiffuse;

							#ifdef CLASSIC_EXPOSURE
								skyReflection *= 4.0 - 3.0 * eBS;
							#endif

							skyReflection = mix(vanillaDiffuse * minLightCol * ((isEyeInWater == 1) ? MINLIGHT_U_I : MINLIGHT_I),
											skyReflection, skyOcclusion);

						#elif defined (NETHER)
							skyReflection=netherCol.rgb * 0.2;

						#elif defined (END)
							skyReflection=endCol.rgb * 0.1;
							skyRefPos *= 1000000.0;

							#if defined END_STARS_REF && defined END_STARS
								vec3 endStars = vec3(0.0);
								vec3 endStarsRef = DrawEndStars(color.rgb, skyRefPos);
								endStarsRef += endStars;
								skyReflection += endStarsRef * END_STARS_REF_STRENGTH_W * 0.5;
							#endif

							#if defined END_AURORA_REF && defined AURORA_END
								vec3 endAurora = vec3(0.0);
								vec3 endAuroraRef = DrawAurora(skyRefPos, dither, 15);
								endAuroraRef += endAurora;
								skyReflection += endAuroraRef * END_AURORA_REF_STRENGTH_W;
							#endif

							#if defined END_SHOOTING_STARS_REF && defined SHOOTING_STARS_END
								vec3 endShootingStar = vec3(0.0);
								vec3 endShootingStarRef = vec3(0.0);

								for (int i = 0; i < NUM_SHOOTING_STARS; i++) {
									float size = 1.0 + (i * 0.2);
									endShootingStarRef = DrawShootingStar(color.rgb, skyRefPos, size, dither);
								}

								endShootingStarRef += endShootingStar;
								skyReflection += endShootingStarRef * END_SHOOTING_STARS_REF_STRENGTH_W;
							#endif

							#if defined END_FBM_REF && defined FBM
								vec3 endFBM = vec3(0.0);
								vec3 endFBMRef = doFullSkyFBM(color.rgb, skyRefPos);
								endFBMRef += endFBM;
								skyReflection += endFBMRef * END_FBM_REF_STRENGTH_W * 0.5;
							#endif

						#endif
					}

					reflection.rgb=max(mix(skyReflection, reflection.rgb, reflection.a), vec3(0.0));

					color.rgb = clamp01(color.rgb + reflection.rgb * (fresnel3 * SMOOTHNESS_METAL_REFLECTION_STRENGTH));
				}

			#endif

			#ifdef GLOWING_ENTITY_FIX

				if (isGlowing > 0.9975) {
					const vec2 glowOutlineOffsets[16] = vec2[16](vec2( 0.0, -1.0),
																 vec2(-1.0,  0.0),
																 vec2( 1.0,  0.0),
																 vec2( 0.0,  1.0),
																 vec2(-1.0, -2.0),
																 vec2( 0.0, -2.0),
																 vec2( 1.0, -2.0),
																 vec2(-2.0, -1.0),
																 vec2( 2.0, -1.0),
																 vec2(-2.0,  0.0),
																 vec2( 2.0,  0.0),
																 vec2(-2.0,  1.0),
																 vec2( 2.0,  1.0),
																 vec2(-1.0,  2.0),
																 vec2( 0.0,  2.0),
																 vec2( 1.0,  2.0)
					);

					#ifdef GLOWING_ENTITY_RGB
						vec3 colorGlow = clamp01(vec3(hue2(frameTimeCounter * 0.1)));
            				 colorGlow = pow(colorGlow, vec3(2.2)) * 1.0 * 0.5;
					#else
						vec3 colorGlow = vec3(0.5);
					#endif

					for (int i = 0; i < 16; i++) {
						vec2  glowOffset = glowOutlineOffsets[i] / (vec2(viewWidth, viewHeight) * 0.5);
						float glowSample = texture2D(colortex13, texCoord.xy + glowOffset).r;
						if (glowSample < 0.5) {
							color.rgb = (i < 4) ? vec3(0.0) : colorGlow;
							break;
						}
					}
				}

			#endif

			#ifdef FULL_BORDER
				color.rgb = fullborder(color.rgb, depthtex1, texCoord, viewWidth, viewHeight, near, far);
			#endif

			color.rgb *= ao;

			#ifdef FOG
				color.rgb = Fog(color.rgb, viewPos.xyz);
			#endif

		}else{

			#if SKY_BLUR > 0

				vec2 skyBlurOffset[4] = vec2[4](vec2( 0.0,  1.0),
										vec2( 0.0, -1.0),
										vec2( 1.0,  0.0),
										vec2(-1.0,  0.0));
				vec2 wh = vec2(viewWidth, viewHeight);
				vec3 skyBlurColor = color.rgb;
				for(int i = 0; i < 4; i++) {
					vec2 texCoordM = texCoord + skyBlurOffset[i] / wh;
					float depth = texture2D(depthtex0, texCoordM).r;
					if (depth == 1.0) skyBlurColor += texture2D(colortex0, texCoordM).rgb;
					else skyBlurColor += color.rgb;
				}

				#if SKY_BLUR == 1
				color.rgb = mix(color.rgb, skyBlurColor / 5.0, 1.0);
				#elif SKY_BLUR == 2
				color.rgb = mix(color.rgb, skyBlurColor / 5.0, sunVisibility);
				#elif SKY_BLUR == 3
				color.rgb = mix(color.rgb, skyBlurColor / 5.0, moonVisibility);
				#endif

			#endif

			#ifdef NETHER
				color.rgb = netherCol.rgb * NETHER_FOG_COLOR_M;
			#endif

			#ifdef END

				#ifdef ENDER_SKY_COLOR_CUSTOM
					color.rgb = vec3(endColCustom.rgb * (0.035 + 0.02 * screenBrightness2));
					color.rgb = pow(color.rgb, vec3(1.0)) * 10;
				#else
					color.rgb = vec3(endCol.rgb * (0.035 + 0.02 * screenBrightness2));
					color.rgb = pow(color.rgb, vec3(1.0)) * 10;
				#endif

				#ifdef AURORA_END
					color.rgb = DrawAurora(viewPos.xyz, dither, 30);
				#endif

				#ifdef END_STARS
					color.rgb = DrawEndStars(color.rgb, viewPos.xyz);
				#endif

				#ifdef LOST_GLARE
					color.rgb = LostGlare(color.rgb, nViewPos);
				#endif

				#if defined END && defined BLACK_HOLE
					color.rgb = getBlackHole(color.rgb, worldPos, NdotS);
				#endif

				#ifdef SHOOTING_STARS_END
					for (int i = 0; i < NUM_SHOOTING_STARS; i++) {
						float size = 1.0 + (i * 0.2);
						color.rgb = DrawShootingStar(color.rgb, viewPos.xyz, size, dither);
					}
				#endif

				#ifdef FBM
					color.rgb = doFullSkyFBM(color.rgb, viewPos.xyz);
				#endif

			#endif

			#ifdef UNDERWATER_SKY_OPACITY
				if (isEyeInWater == 1) {
					float NdotU2 = Max0(dot(nViewPos, upVec));
					vec3 colorSkyOp = color.rgb;
					colorSkyOp.rgb = mix(color.rgb, 0.1 * pow(rawWaterColorSqrt.rgb * (1.0 - blindFactor), vec3(2.0)), 1 - pow2(NdotU2));
					colorSkyOp.rgb *= UNDERWATER_SKY_BRIGHTNESS;
					color.rgb = mix(color.rgb, colorSkyOp.rgb, sunVisibility);
				}
			#endif

			if (isEyeInWater == 2){
				color.rgb = vec3(1.0, 0.3, 0.01);
			}

			#if MC_VERSION >= 11900
			if (blindFactor > 0.0 || darknessFactor > 0.0) color.rgb *= 1.0 - max(blindFactor, darknessFactor);
			#else
			if (blindFactor > 0.0) color.rgb *= 1.0 - blindFactor;
			#endif

		}

		#ifdef OUTLINE_ENABLED
			color.rgb = mix(color.rgb, outerOutline.rgb, outerOutline.a);
		#endif

		vec3 reflectionColor = pow(color.rgb, vec3(0.125)) * 0.5;

		/* RENDERTARGETS: 0,5 */
		gl_FragData[0] = vec4(color);
		gl_FragData[1] = vec4(reflectionColor, float(z < 1.0));

		#if REFRACTION > 0
		/* RENDERTARGETS: 0,5,14 */
		gl_FragData[2] = vec4(0.0, 0.0, 0.0, 1.0);
		#endif

	}

#endif
