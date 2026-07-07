vec3 SunGlare(vec3 color, vec3 nViewPos, vec3 lightCol) {
	float ndotVoS = dot(nViewPos, sunVec);
	if (ndotVoS > 0.0) {
		float VoL = ndotVoS;
		VoL *= VoL;
		VoL *= VoL;
		VoL *= VoL;

		float visfactor = 0.2;

		float sunGlare = VoL;
		sunGlare = visfactor / (1.0 - (1.0 - visfactor) * sunGlare) - visfactor;
		sunGlare *= ndotVoS;

		float sunGlareDay = 0.1;

		sunGlare *= sunGlareDay * SUN_GLARE_DAY * sunVisibility;

		sunGlare *= shadowFade;

		vec3 finalSunGlare = lightCol * sunGlare;

		if (isEyeInWater == 1)
		color += clamp01(0.025 * lightCol * finalSunGlare);

		#if SUNGLARE_RAIN == 1
		if (isEyeInWater == 1) {
			color += (SUNGLARE_UNDERWATER_STRENGTH * 0.01 * (0.1 - rainFactor * 2.5)) * lightCol * finalSunGlare;
		} else if (isEyeInWater == 0) {
			color += (SUNGLARE_OUTWATER_STRENGTH * 0.01 * (1.1 - rainFactor)) * lightCol * finalSunGlare;
		}
		#elif SUNGLARE_RAIN == 2
		if (isEyeInWater == 1) {
			color += (SUNGLARE_UNDERWATER_STRENGTH * 0.01 * lightCol * finalSunGlare * (1.0 - rainFactor));
		} else if (isEyeInWater == 0) {
			color += (SUNGLARE_OUTWATER_STRENGTH * 0.01 * lightCol * finalSunGlare * (1.0 - rainFactor));
		}
		#endif

	}
	return color;
}

vec3 MoonGlare(vec3 color, vec3 nViewPos, vec3 lightCol) {
	float ndot_VoS = dot(nViewPos, - sunVec);
	if (ndot_VoS > 0.0) {
		float moonPhaseOffsetSunGlare = 1.0;
		float visfactor = 0.2;
		float sunGlareNight = 200.0;
		float VoL = ndot_VoS;
		VoL *= VoL;
		VoL *= VoL;
		VoL *= VoL;

		#ifdef NEWMOON_DISABLER_STUFF
			moonPhaseOffsetSunGlare = 1.0 - (float((moonPhase == 4)));
		#endif

		float moonGlare = VoL;
			  moonGlare = visfactor / (1.0 - (1.0 - visfactor) * moonGlare) - visfactor;
			  moonGlare *= ndot_VoS;
			  moonGlare *= sunGlareNight * SUN_GLARE_NIGHT * moonPhaseOffsetSunGlare * moonVisibility;
	          moonGlare *= shadowFade;

		vec3 finalSunGlare = lightCol * moonGlare;

		if (isEyeInWater == 1)
		color += clamp01(0.025 * lightCol * finalSunGlare);

		#if SUNGLARE_RAIN == 1
		if (isEyeInWater == 1) {
			color += (SUNGLARE_UNDERWATER_STRENGTH * 0.01 * (0.1 - rainFactor * 2.5)) * lightCol * finalSunGlare;
		} else if (isEyeInWater == 0) {
			color += (SUNGLARE_OUTWATER_STRENGTH * 0.01 * (1.1 - rainFactor)) * lightCol * finalSunGlare;
		}
		#elif SUNGLARE_RAIN == 2
		if (isEyeInWater == 1) {
			color += (SUNGLARE_UNDERWATER_STRENGTH * 0.01 * lightCol * finalSunGlare * (1.0 - rainFactor));
		} else if (isEyeInWater == 0) {
			color += (SUNGLARE_OUTWATER_STRENGTH * 0.01 * lightCol * finalSunGlare * (1.0 - rainFactor));
		}
		#endif

	}
	return color;
}