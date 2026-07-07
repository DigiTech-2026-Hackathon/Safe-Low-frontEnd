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
varying vec3 sunVec, upVec, uSunVec;

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

	//Program//
	void main(){
		texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

		gl_Position=ftransform();

		upVec=normalize(gbufferModelView[1].xyz);
		uSunVec = GetuSunVec();
		sunVec = GetSunVec(uSunVec);
	}

#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

	//Uniforms//
	uniform int frameCounter;
	uniform int isEyeInWater;
	uniform float blindFactor;
	uniform float rainFactor;
	uniform float screenBrightness;
	uniform float viewWidth, viewHeight;

	#if defined END && defined BLACK_HOLE
		uniform float frameTimeCounter;
		uniform mat4 gbufferProjection, gbufferPreviousProjection;
		uniform mat4 gbufferModelView, gbufferPreviousModelView, gbufferModelViewInverse;
		uniform mat4 shadowProjection;
		uniform mat4 shadowModelView;
	#endif

	#if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
		uniform float darknessFactor;
	#endif

	uniform ivec2 eyeBrightnessSmooth;

	uniform vec3 skyColor;
	uniform vec3 cameraPosition;

	uniform sampler2D colortex0;
	uniform sampler2D colortex1;
	uniform sampler2D depthtex0;

	uniform mat4 gbufferProjectionInverse;

	//Common Variables//
	float eBS               = eyeBrightnessSmooth.y / 240.0;
	float eBS2              = clamp01((eyeBrightnessSmooth.y - 220) * 0.0666);
	float sunVisibility     = clamp00125(dot( sunVec, upVec) + 0.0625) * 8.0;
	float sunVisibilityLSM  = clamp(dot(sunVec,upVec) + 0.125, 0.0, 0.25) * 4.0;
	float screenBrightness2 = clamp01(screenBrightness);
	float rainStrengthSp2   = rainFactor * rainFactor;
	float lightShaftTime    = pow(abs(sunVisibility - 0.5) * 2.0, 10.0);

	//Includes//
	#include "/lib/color/dimensionColor.glsl"

	//Program//
	void main(){
		vec4 color = texture2D(colortex0, texCoord.xy);
			int lod = 0;

		float z     = texture2D(depthtex0, texCoord).r;

		vec4 screenPos =vec4(texCoord, z, 1.0);
		vec4 viewPos    = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
			 viewPos   /= viewPos.w;
		vec3 nViewPos   = normalize(viewPos.xyz);

		#if ((defined OVERWORLD && defined LIGHT_SHAFT) || (defined END && defined LIGHT_SHAFT_END))

			if (isEyeInWater == 1){
				lod = 1;
			}

			#ifndef MC_GL_RENDERER_GEFORCE
			if (mod(viewHeight, 2.0) == 0.0 && mod(viewWidth, 2.0) == 0.0)
				lod = 0;
			#endif

			vec3 vl1 = textureLod(colortex1, texCoord.xy + vec2( 0.0,  1.0 / viewHeight), lod).rgb;
			vec3 vl2 = textureLod(colortex1, texCoord.xy + vec2( 0.0, -1.0 / viewHeight), lod).rgb;
			vec3 vl3 = textureLod(colortex1, texCoord.xy + vec2( 1.0 / viewWidth,   0.0), lod).rgb;
			vec3 vl4 = textureLod(colortex1, texCoord.xy + vec2(-1.0 / viewWidth,   0.0), lod).rgb;
			vec3 vlSum = (vl1 + vl2 + vl3 + vl4) * 0.25;
			vec3 vl = vlSum;

			vl *= vl;

			#if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
				vl *= 1.0 - darknessFactor;
			#endif

			vec3 vlP = vl;
		#endif

		#if (defined LIGHT_SHAFT && defined OVERWORLD)

			if (isEyeInWater == 0) {

					float NdotU               = dot(nViewPos, upVec);
					      NdotU               = Max0(NdotU);
					      NdotU               = 1.0 - NdotU;
					if    (NdotU > 0.5) NdotU = smoothstep(0.0, 1.0, NdotU);

					#if DIRECTION_LIGHTSHAFT == 2
					NdotU *= NdotU;
					#elif DIRECTION_LIGHTSHAFT == 1
					NdotU *= NdotU;
					NdotU *= NdotU;
					#elif DIRECTION_LIGHTSHAFT == 0
					NdotU *= NdotU;
					NdotU *= NdotU;
					NdotU *= NdotU;
					#endif

					NdotU = mix(NdotU, 1.0, rainStrengthSp2 * 0.75);

					vl *=  pow2(NdotU);

				vec3 dayLightCol = pow2(lightCol);
				 	 dayLightCol=pow(dayLightCol, vec3(LIGHTSHAFT_CONTRAST_DAY));

				vec3 nightLightCol =pow3(lightCol) * 10.0;
				 	 nightLightCol =pow(nightLightCol, vec3(LIGHTSHAFT_CONTRAST_NIGHT));

				vec3 vlColor = mix(nightLightCol, dayLightCol, sunVisibility);

				vec3 weatherSky  = weatherCol.rgb * weatherCol.rgb;
					 weatherSky *= GetLuminance(ambientCol / weatherSky) * 1.4;
					 weatherSky *= mix(SKY_RAIN_NIGHT, SKY_RAIN_DAY, sunVisibility);
					 weatherSky  = max(weatherSky, skyColor * skyColor * 0.5625);
					 weatherSky *= rainFactor;
					 vlColor = mix(vlColor * 0.75, weatherSky, rainStrengthSp2);

				#if MC_VERSION >= 11800
				vl *= vlColor * clamp01(exp(2.0 * cameraPosition.y + 126.0));
				#else
				vl *= vlColor * clamp01(exp(2.0 * cameraPosition.y - 2.0));
				#endif

				float rainMult = mix(LIGHT_SHAFT_NIGHT_RAIN_MULTIPLIER * (0.25 + 0.2 * screenBrightness2),
									 LIGHT_SHAFT_DAY_RAIN_MULTIPLIER * (0.65 + 0.2 * screenBrightness2),
									 sunVisibility);

				float timeBrightnessSqrt = sqrt1(dayFactor);

				vl*=mix(1.0, LIGHT_SHAFT_NOON_MULTIPLIER * 0.4, timeBrightnessSqrt * (1.0 - rainFactor * 0.8));
				vl*=mix((LIGHT_SHAFT_NIGHT_MULTIPLIER * 10) * (0.91 - nightFactor * 0.39), 2.0, sunVisibility);
				vl*=mix(1.0, rainMult * 0.25, rainStrengthSp2);

			} else {

				vec3 dayLightCol = lightCol;
				     dayLightCol=pow(dayLightCol, vec3(UNDERWATER_LIGHTSHAFT_CONTRAST_DAY * 0.5));

				vec3 nightLightCol =pow3(lightCol);
				     nightLightCol =pow(nightLightCol, vec3(UNDERWATER_LIGHTSHAFT_CONTRAST_NIGHT * 0.25));

				vl *= length(mix(nightLightCol, dayLightCol, sunVisibility)) * LIGHT_SHAFT_UNDERWATER_MULTIPLIER * 0.005;
			}

		#endif

		#if (defined LIGHT_SHAFT_END && defined END)
			vl *= endColSqrt3.rgb * 0.1 * LIGHT_SHAFT_STRENGTH_END;
			vl *= (LIGHT_SHAFT_STRENGTH_END * 10.0) * (1.0 - rainFactor * eBS * 0.875) * shadowFade * (1.0 + isEyeInWater) * (1.0 - blindFactor);
		#endif

		#if (defined LIGHT_SHAFT && defined OVERWORLD)
			vl *= (LIGHT_SHAFT_STRENGTH * 60) * (SUNSET_SUNRISE_LIGHTSHAFT_STRENGTH + dayFactor) * shadowFade * (1.0 - blindFactor);

			float vlFactor = (1.0 - min((dayFactor) * 2.0, 0.75));
				  vlFactor = mix(vlFactor, 0.05, rainFactor);
			if (isEyeInWater == 1) vlFactor = 3.0;
			vl *= vlFactor * 1.75;
		#endif

		#if ((defined OVERWORLD && defined LIGHT_SHAFT) || (defined END && defined LIGHT_SHAFT_END))
			vec3 addedColor = color.rgb + vl * lightShaftTime;
			vec3 vlMixBlend = vlP * (1.0 - 0.5 * rainFactor);
			float mixedTime = sunVisibility < 0.5 ?
							  sqrt3(max(nightFactor - 0.3, 0.0) / 0.7) * lightShaftTime
							  : pow2(pow2((sunVisibilityLSM - 0.5) * 2.0));
			vec3 mixedColor = mix(color.rgb, vl / max(vlP, 0.01), vlMixBlend * mixedTime);
			color.rgb = mix(mixedColor, addedColor, sunVisibility * (1.0 - rainFactor));
		#endif

		/* RENDERTARGETS: 0 */
		gl_FragData[0] = vec4(Max0(color));
	}

#endif