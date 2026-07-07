float CloudNoiseDetail(vec2 coord, vec2 wind, float scale, float windScale, float weight) {
	return texture2D(noisetex, coord * scale + wind * windScale).r * weight;
}

float CloudNoise(vec2 coord, vec2 wind) {
    float noiseA = texture2D(noisetex, coord * 0.125 + wind * 0.15).r;
    noiseA += CloudNoiseDetail(coord, wind, 0.0625, 0.15, 5.0);
    noiseA += CloudNoiseDetail(coord, wind, 0.03125, 0.5, 5.0);
    noiseA += CloudNoiseDetail(coord, wind, 0.015625, 0.25, 10.0);
    noiseA += CloudNoiseDetail(coord, wind, 0.012500, 0.125, 10.0);
    noiseA += CloudNoiseDetail(coord, wind, 0.025000, 0.25, 10.0);

    float noiseB = texture2D(noisetex, coord * 0.0625 - wind * 0.2).r;
    noiseB += CloudNoiseDetail(coord, wind, 0.03125, 0.5, 5.0);
    noiseB += CloudNoiseDetail(coord, wind, 0.015625, 0.25, 10.0);
    noiseB += CloudNoiseDetail(coord, wind, 0.012500, 0.125, 10.0);
    noiseB += CloudNoiseDetail(coord, wind, 0.025000, 0.25, 10.0);

    return (noiseA + noiseB) * 0.34;
}

float CloudCoverage(float noise, float coverage, float NdotVoU, float NdotVoS) {
	float noiseCoverageNdotVoS = abs(NdotVoS);
	noiseCoverageNdotVoS *= noiseCoverageNdotVoS;
	noiseCoverageNdotVoS *= noiseCoverageNdotVoS;
	float NdotVoUmult = 2.0 * CLOUD_COVERAGE;


	float noiseCoverage = coverage * coverage + CLOUD_AMOUNT
								* (1.0 + noiseCoverageNdotVoS * 0.175)
								* (1.0 + NdotVoU * NdotVoUmult * (1.0-rainFactor * CLOUD_RAIN_COVERING))
								- 10;

	return Max0(noise - noiseCoverage);
}

vec4 DrawCloud(vec3 viewPos, float dither, vec3 lightCol, vec3 ambientCol, int sampleCount) {

	float NdotVoU = dot(normalize(viewPos), upVec);
	float NdotVoS = dot(normalize(viewPos), sunVec);
	float cloud = 0.0;
	float cloudGradient = 0.0;
	float gradientMix = dither * 0.2;

	float cloudBrightness= mix(CLOUD_BRIGHTNESS_DAY, CLOUD_BRIGHTNESS_NIGHT, moonVisibility);

	float colorMultiplier = cloudBrightness * 4.0 * (0.23 - 0.07 * sqrt1(dayFactor));

	float noiseMultiplier = CLOUD_THICKNESS * 0.125;

	float sunScattering = 0.5 * pow(NdotVoS * 0.55 * (2.0 * sunVisibility - 1.0) + 0.55 , 6.0);
	float moonScattering = 0.5 * pow(-NdotVoS * 0.5 * (2.0 * moonVisibility - 1.0) + 0.5, 6.0);
	float scattering = mix(sunScattering, moonScattering, moonVisibility);

	float cloudHeightFactor = max(1.11 - 0.0015 * eyeAltitude, 0.0);
		  cloudHeightFactor *= cloudHeightFactor;
		  cloudHeightFactor *= cloudHeightFactor;
	float cloudHeight = CLOUD_HEIGHT * cloudHeightFactor;

	float cloudSpeedFactor = 0.0015;
	vec2 wind = vec2(frameTimeCounter * CLOUD_SPEED * cloudSpeedFactor, 0.0);

	vec3 cloudColor = vec3(0.0);

	float coordFactor = 0.009375;

	if (NdotVoU > 0.0) {
		vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz);
		for (int i = 1; i < sampleCount; i ++) {
			if (cloud > 0.99)
				break;

			vec3 planeCoord = wpos * ((cloudHeight + (i + dither) * 2) / wpos.y) * 0.029;
			vec2 coord = cameraPosition.xz * 0.00025 + planeCoord.xz;

			float ang1 = (i + frameTimeCounter * 0.025) * 2.391;
			float ang2 = ang1 + 2.391;
			coord += mix(vec2(cos(ang1), sin(ang1)), vec2(cos(ang2), sin(ang2)), dither * 0.25 + 0.75) * coordFactor;

			float coverage = float(i - 4.0 + dither) * 0.5;

			float noise = CloudNoise(coord, wind);
				  noise = CloudCoverage(noise, coverage, NdotVoU, NdotVoS) * noiseMultiplier;
				  noise = noise / sqrt(pow2(noise) + 1.0);

			cloudGradient = mix(cloudGradient, mix(gradientMix * gradientMix, 1.0 - noise, 0.1), noise * (1.0 - cloud));

			cloud += Max0(noise - cloud * 0.95);
			cloud = mix(cloud, 1.0, rainFactor * pow2(noise * noise));
			gradientMix += 0.2;
		}

		float meFactorP = min((1.0 - min(nightFactor, 0.6) / 0.6) * 0.115, 0.075);
			vec3 meColor = vec3(0.0);
			if (NdotVoS > 0.0) {
				float meNdotVoU = 1.0 - NdotVoU;
				float meFactor = meFactorP * meNdotVoU * meNdotVoU * 12.0 * (1.0 - rainFactor);
				meColor = mix(lightMorning, lightEvening, mefade);
				meColor *= meColor;
				meColor *= meColor;
				meColor *= meFactor * meFactor * NdotVoS;
			}

		float sunVisibilityM = pow(sunVisibility, 4.0 - meFactorP * 24.0);
			vec3 skyColorNormal = skyColor;
            vec3 skyColor2 = pow2(skyColor);

            vec3 cloudNightColor = ambientCol * 4.0;
            vec3 cloudDayColor = pow(lightCol, vec3(1.5)) * 1.5;
            vec3 cloudUpColor = mix(cloudNightColor, cloudDayColor, sunVisibilityM);
            cloudUpColor *= 1.0 + scattering;
            cloudUpColor += max(meColor, vec3(0.0));

			#if DAY_CLOUD_COLOR == 0
			vec3 cloudDownColorDay = pow(skyColorNormal, vec3(0.75)) * 0.225 * sunVisibility * sky_ColorSqrt;
			#else
			vec3 cloudDownColorDay = vec3(0.8) * 0.225 * sunVisibility * pow(sky_ColorSqrt, vec3(0.75));
			#endif

			#if NIGHT_CLOUD_COLOR == 0
			vec3 cloudDownColorNight = skyColor2 * 0.225 * moonVisibility * sky_ColorSqrt;
			#else
            vec3 cloudDownColorNight = mix(pow2(pow(lightNight, vec3(1.3))), skyColor2 * 0.225, rainFactor) * moonVisibility * sky_ColorSqrt;
			#endif

			vec3 cloudDownColor = mix(cloudDownColorDay, cloudDownColorNight, moonVisibility);

            vec3 weatherSky = weatherCol.rgb * weatherCol.rgb;
            weatherSky *= GetLuminance(ambientCol / (weatherSky)) * 1.4;
            weatherSky *= mix(SKY_RAIN_NIGHT, SKY_RAIN_DAY, sunVisibility);
            weatherSky = max(weatherSky, skyColor2 * 0.75);
			weatherSky *= rainFactor;
			#ifdef LIGHT_SHAFT
            	weatherSky *= scattering * (1.0 + sunVisibility) * (1.5 + moonVisibility);
			#else
            	weatherSky *= scattering;
			#endif

            cloudUpColor = mix(cloudUpColor, weatherSky, rainFactor * rainFactor);

            cloudColor = mix(cloudDownColor, cloudUpColor, cloudGradient);

			cloud *= pow2(pow2(1.0 - exp(- (10.0 - 8.2 * rainFactor) * NdotVoU)));
	}

	#ifdef UNDERGROUND_SKY
		if (isEyeInWater == 0) {
			float ug = mix(clamp01((cameraPosition.y - 48.0) * 0.0625), 1.0, eBS);
			cloudColor = mix(minLightCol * 0.125, cloudColor, ug);
		}
    #endif

	#if MC_VERSION >=11800
		cloudColor *= clamp01((cameraPosition.y + 70.0) * 0.125);
	#else
		cloudColor *= clamp01((cameraPosition.y + 6.0) * 0.125);
	#endif

	return clamp01(vec4(cloudColor * colorMultiplier, cloud * CLOUD_OPACITY));
}