vec4 DistortShadow(vec4 shadowpos, float distortFactor) {
	shadowpos.xy *= 1.0 / distortFactor;
	shadowpos.z = shadowpos.z * 0.2;
	shadowpos = shadowpos * 0.5 + 0.5;

	return shadowpos;
}

void GetShadowSpace(inout vec3 worldposition, inout vec4 vlposition, float shadowdepth, vec2 texCoord) {
	vec4 viewPos = gbufferProjectionInverse * (vec4(texCoord, shadowdepth, 1.0) * 2.0 - 1.0);
	viewPos /= viewPos.w;

	vec4 wpos = gbufferModelViewInverse * viewPos;
	worldposition = wpos.xyz / wpos.w;
	wpos = shadowModelView * wpos;
	wpos = shadowProjection * wpos;
	wpos /= wpos.w;

	float distb = sqrt(wpos.x * wpos.x + wpos.y * wpos.y);
	float distortFactor = 1.0 - shadowMapBias + distb * shadowMapBias;
	vec4 shadowPosition = DistortShadow(wpos, distortFactor);
		 shadowPosition.z += 0.0001;

	vlposition = shadowPosition;
}

vec3 getVolumetricRays(float depth0, float depth1, vec3 vlAlbedo, float dither, float NdotVoL, vec3 vl) {

	float visibility = 0.045;
	float endurance = 1.20;

	#if defined(OVERWORLD)
	if (isEyeInWater == 0)
	endurance *= min(2.0 + pow2(rainFactor) - pow2(sunVisibility), 2.0);
	else
	visibility *= 1.0 + 2.0 * pow(Max0(NdotVoL), 128.0) * float(sunVisibility > 0.5) * (1.0 - rainFactor);

	if (endurance >= 1.0)
	visibility *= Max0((NdotVoL + endurance) / (endurance + 1.0));
	else
	visibility *= pow(Max0((NdotVoL + 1.0) / 2.0), (11.0 - endurance * 10.0));

	#ifdef UNDERGROUND_SKY
	visibility *= 1.0 - isEyeInCave;
	#endif

	#elif defined(END)
	#ifdef LIGHT_SHAFT_END
	visibility = 0.14285;
	#else
	visibility = 0.0;
	#endif
	#endif

	if (visibility > 0.0) {

		float maxDist = min(3072.0, shadowDistance);
		if (isEyeInWater == 1)maxDist = min(3072.0, shadowDistance * 0.75);

		vec3 worldposition = vec3(0.0);
		vec4 vlposition = vec4(0.0);

		#if (defined END || defined OVERWORLD)
		vec3 watercol2 = rawWaterColorLightshaft.rgb / UNDERWATERL_I;
		watercol2 = pow(watercol2, mix(vec3(UNDERWATER_LIGHTSHAFT_CONTRAST_NIGHT), vec3(UNDERWATER_LIGHTSHAFT_CONTRAST_DAY), sunVisibility)) * 25.0;
		#endif

		float minDistFactor = 8.0;

		minDistFactor *= mix(clamp(far, 0, 512) / 192.0, clamp(far, 384, 512) / 192.0, isEyeInWater);

		float fovFactor = gbufferProjection[1][1] / 1.37;
		float x = abs(texCoord.x - 0.5);
		x = 1.0 - x * x;
		x = pow(x, Max0(3.0 - fovFactor));
		minDistFactor *= x;
		maxDist *= x;

		float lightBrightnessM = smoothstep(0.0, 1.0, 1.0 - pow2(1.0 - max(dayFactor, nightFactor)));

		int sampleCount = 10;
		float addition = 0.5;

		if (isEyeInWater == 0) {
			minDistFactor *= 0.5;
		}

		float sampleIntensity = 2.5;
		if (isEyeInWater == 0) {
			float qualityFactor = 1.42857;
			sampleIntensity /= qualityFactor;
			minDistFactor /= 1.7;
			addition *= qualityFactor;
		}
		for(int i = 0; i < sampleCount; i ++ ) {

			float minDist = 0.0;
			if (isEyeInWater == 0) {
				minDist = pow(i + dither + addition, 1.5) * minDistFactor;

			} else
			minDist = pow2(i + dither + 0.5) * minDistFactor * 0.045;

			if (minDist >= maxDist)
			break;

			if (depth1 < minDist ||(depth0 < minDist && vlAlbedo == vec3(0.0)))
			break;

			GetShadowSpace(worldposition, vlposition, GetDistX(minDist), texCoord.st);

			if (length(vlposition.xy * 2.0 - 1.0) < 1.0) {

				vec3 shadow0 = vec3(shadow2D(shadowtex0, vlposition.xyz).z);

				vec3 shadowCol = vec3(0.0);
				#ifdef COLORED_SHADOWS
				if (shadow0.z < 1.0) {
					float shadow1 = shadow2D(shadowtex1, vlposition.xyz).z;
					if (shadow1 > 0.0) {
						shadowCol = texture2D(shadowcolor0, vlposition.xy).rgb;
						shadowCol *= (shadowCol * 0.5) * shadow1;
						#if RP_COLORED_SHADOW_COMPATIBILITY == 1
						shadowCol *= 500.0;
						#elif RP_COLORED_SHADOW_COMPATIBILITY == 0
						shadowCol *= 1000.0;
						#endif
					}
				}
				#endif

				shadow0 *= shadow0;
				shadowCol *= shadowCol;

				vec3 shadow = clamp(shadowCol * (1.0 - shadow0) + shadow0, vec3(0.0), vec3(1.0));

				if (depth0 < minDist)
				shadow *= vlAlbedo;

				#if (defined LIGHT_SHAFT_END && defined END && defined ENDER_SMOKER_LIGHT_SHAFT)
					if (isEyeInWater == 0){

							vec3 npos = worldposition.xyz + cameraPosition.xyz + vec3(frameTimeCounter * ENDER_SMOKER_LIGHT_SHAFT_SPEED, 0, 0);
							float n3da = texture2D(noisetex, npos.xz / 384.0 + floor(npos.y / 5.0) * 0.95).r;
							float n3db = texture2D(noisetex, npos.xz / 384.0 + floor(npos.y / 5.0 + 1.0) * 0.95).r;
							float noise = mix(n3da, n3db, fract(npos.y / 5.0));
							noise = sin(noise * 12.0 + frameTimeCounter * ENDER_SMOKER_LIGHT_SHAFT_SPEED) * 0.15 + 0.5;
							shadow *= noise;
					}
				#endif

				#if (defined LIGHT_SHAFT && defined OVERWORLD && SMOKER_LIGHT_SHAFT > 0)

					if (isEyeInWater == 0) {

						vec3 npos = worldposition.xyz + cameraPosition.xyz + vec3(frameTimeCounter * SMOKER_LIGHT_SHAFT_OVERWORLD_SPEED * 0.25, 0, 0);
						float n3da = texture2D(noisetex, npos.xz / 384.0 + floor(npos.y / 1.55) * 0.55).r;
						float n3db = texture2D(noisetex, npos.xz / 384.0 + floor(npos.y / 1.55 + 1.0) * 0.55).r;
						float noise = mix(n3da, n3db, fract(npos.y / 1.55));
						noise = noise * 12.0 * 0.025 + 0.5;

						#if SMOKER_LIGHT_SHAFT == 1
						noise = mix(1.0, noise, moonVisibility);

						#elif SMOKER_LIGHT_SHAFT == 2
						noise = mix(1.0, noise, rainFactor);

						#elif SMOKER_LIGHT_SHAFT == 3
						noise = mix(1.0, noise, 1.0 - ((1.0 - rainFactor) * (1.0 - moonVisibility)));
						#endif

						shadow *= pow2(noise);
					}
				#endif

				#if (defined LIGHT_SHAFT && SMOKER_LIGHT_SHAFT_UNDERWATER == 1 && defined OVERWORLD) || (defined LIGHT_SHAFT_END && SMOKER_LIGHT_SHAFT_UNDERWATER == 1 && defined END)
					if (isEyeInWater == 1) {

					#if defined(OVERWORLD)
						float smokerLightShaftSpeed = SMOKER_LIGHT_SHAFT_OVERWORLD_SPEED;
					#endif
					#if defined(END)
						float smokerLightShaftSpeed = ENDER_SMOKER_LIGHT_SHAFT_SPEED;
					#endif

					vec3 npos = worldposition.xyz + cameraPosition.xyz + vec3(frameTimeCounter * smokerLightShaftSpeed * 0.25, 0, 0);
						float n3da = texture2D(noisetex, npos.xz / 256.0 + floor(npos.y / 5.0) * 0.95).r;
						float n3db = texture2D(noisetex, npos.xz / 256.0 + floor(npos.y / 5.0 + 1.0) * 0.95).r;
						float noise = mix(n3da, n3db, fract(npos.y / 5.0));
						noise = noise * 30.0 * 0.025 + 0.5;

					shadow *= pow4(noise);
					}
				#endif

				if (isEyeInWater == 0) {
					float sampleFactor = 0.0;
					sampleFactor = sqrt(minDist / maxDist);
					vl += shadow * sampleFactor * 1.5;
				} else {

					#ifdef END
					shadow *= endColSqrt3.rgb * 0.1 * LIGHT_SHAFT_STRENGTH_END;
					#else
					shadow *= watercol2.rgb * 0.5;
					#endif

					float sampleFactor = sqrt(minDist / maxDist);
					vl += shadow * sampleFactor * 0.05;
				}

				if (depth0 < minDist)shadow *= vlAlbedo;

			} else {
				vl += 1.0;
			}
		}

		vl = sqrt(vl * visibility);

		if (isEyeInWater == 1) {
			vl /= sqrt(vl);
		}

		if (isEyeInWater == 0) {
			float vlPower = 1.75 - rainFactor + sunVisibility * 0.25;
			if (vlPower < 1.0)vlPower = 1.0;
			vl = pow(vl, vec3(vlPower));
		}

		float moonPhaseOffsetLightShaft = 1.0;

		#ifdef NEWMOON_DISABLER_STUFF
		moonPhaseOffsetLightShaft = 1.0 - (float((moonPhase == 4)) * (1.0 - sunVisibility));
		#endif

		vl *= 0.9 * moonPhaseOffsetLightShaft;
		if (dot(vl, vl) > 0.0)vl += (dither - 0.19) / 128.0;
	}

	return vl;
}