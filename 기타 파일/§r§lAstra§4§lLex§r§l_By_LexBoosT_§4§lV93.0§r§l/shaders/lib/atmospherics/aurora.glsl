#if AURORA_COLOR == 6
#include "/lib/color/auroraColor.glsl"
#endif

#if (defined AURORA_END && defined END)
#include "/lib/color/auroraEndColor.glsl"
#endif


vec3 DrawAurora(vec3 viewPos, float dither, int sampleCount) {

	float NdotVoU = dot(normalize(viewPos), upVec);

	#ifdef OVERWORLD
	const float auroraSpeed = AURORA_SPEED;
	const float auroraDistance = AURORA_DISTANCE;
	const float auroraSize = AURORA_SIZE;
	const float auroraVisibility = AURORA_VISIBILITY;
	const float auroraGradient = COLOR_GRADIENT;
	#else
	const float auroraSpeed = AURORA_END_SPEED;
	const float auroraDistance = AURORA_END_DISTANCE;
	const float auroraSize = AURORA_END_SIZE;
	const float auroraVisibility = AURORA_END_VISIBILITY;
	const float auroraGradient = COLOR_END_GRADIENT;
	#endif

	#ifdef OVERWORLD
	float visibility = pow2((1.0 - rainFactor)) * (1.0 - sunVisibility);
	#else
	float visibility = 1.0;
	#endif

	#if (defined OVERWORLD && defined WEATHER_PERBIOME && defined AURORA_WEATHER_PERBIOME)
	visibility *= pow2(isSnowy);
	#endif

	if (NdotVoU > 0.0 && visibility > 0.0) {
		vec3 aurora = vec3(0.0);

		vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos, 1.0))).xyz;
			 wpos.xz /= wpos.y;
		vec2 cameraPositionM = cameraPosition.xz * 0.0075;
			 cameraPositionM.x += frameTimeCounter * 0.04 * auroraSpeed;

		int sampleCountA = sampleCount + 5;
		float ditherA = dither + 5.0;
		float gradientMix = ditherA / sampleCountA;
		float auroraAnimate = frameTimeCounter * 0.001 * auroraSpeed;

		for(int i = 0; i < sampleCount; i ++ ) {
			float current = pow2(auroraDistance + (i + ditherA) * auroraSize / sampleCountA);

			vec2 planePos = (wpos.xz * (0.8 + current) + cameraPositionM) * 0.006;

			float noise = texture2D(noisetex, planePos).r;
				  noise = pow2(pow2(pow2(pow2(1.0 - 2.0 * abs(noise - 0.5)))));

				  noise *= texture2D(noisetex, planePos * 3.0 + auroraAnimate).b;
				  noise *= texture2D(noisetex, planePos * 5.0 - auroraAnimate).b;
				  noise *= auroraVisibility;

			float colorGradient = COLOR_GRADIENT;

				#ifdef OVERWORLD
					#if AURORA_COLOR == 1
					vec3 auroraColor = mix(vec3(0.1, 1.0, 0.5) , vec3(0.3451, 0.0, 0.4118), pow(gradientMix, colorGradient));

					#elif AURORA_COLOR == 2
					vec3 auroraColor = mix(vec3(0.1, 1.0, 0.5), vec3(0.0, 0.0, 0.7216), pow(gradientMix, colorGradient));

					#elif AURORA_COLOR == 3
					vec3 auroraColor = mix(vec3(0.1, 1.0, 0.5), vec3(0.6667, 0.0, 0.0), pow(gradientMix, colorGradient));

					#elif AURORA_COLOR == 4
					vec3 auroraColor = mix(vec3(0.1, 1.0, 0.5), vec3(0.6157, 0.6275, 0.0), pow(gradientMix, colorGradient));

					#elif AURORA_COLOR == 5
					vec3 auroraColor = mix(hue2(frameTimeCounter * RAINBOW_COLOR_AURORA_1_SPEED + RAINBOW_COLOR_AURORA_1_START), hue2(frameTimeCounter * RAINBOW_COLOR_AURORA_2_SPEED + RAINBOW_COLOR_AURORA_2_START), pow(gradientMix, colorGradient));

					#elif AURORA_COLOR == 6
					vec3 auroraColor = mix(auroraLowCol, auroraHighCol, pow(gradientMix, colorGradient));
					#endif
				#else
					vec3 auroraColor = mix(auroraEndLowCol, auroraEndHighCol, pow(gradientMix, colorGradient));
				#endif

				aurora += noise * auroraColor * exp2(- 6.0 * i / sampleCount);
				aurora *= 1.0 - exp(-(10.0 - 9.0 * rainFactor) * sqrt1(NdotVoU));
				gradientMix += 1.0 / sampleCount;
		}
			return aurora * visibility / sampleCount;
	}
	return vec3(0.0);
}

