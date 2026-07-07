if (netherportal > 0.5) {

	lightmap = vec2(0.0);

	#if AA > 1
	const int sampleCount = 24;
	#else
	const int sampleCount = 48;
	#endif

	float multiplier = 0.0525 / (- viewVector.z * sampleCount);

	vec2 interval = viewVector.xy * multiplier;

	vec2 coord = vTexCoord.xy;

	vec4 albedoC = vec4(0.0);
	albedo *= 0.0;
	for(int i = 1 ; i <= sampleCount; i ++ ) {
		coord += interval * PORTAL_PARALLAX_DEPTH;
		vec4 psample = textureLod(texture, fract(coord) * vTexCoordAM.zw + vTexCoordAM.xy, 0);

		albedoC = max(albedoC, psample);

		psample.rgb *= vec3(1.8, 3.5, 1.0);

		psample.a = sqrt2(psample.a) * 0.75;

		albedo += psample;
	}
	albedo /= sampleCount;

	#if defined(OVERWORLD)
	const float glowPowerMultiplier = NETHER_PORTAL_GLOWING_POWER_OVERWORLD * 0.05;
	#elif defined(NETHER)
	const float glowPowerMultiplier = NETHER_PORTAL_GLOWING_POWER_NETHER * 0.05;
	#elif defined(END)
	const float glowPowerMultiplier = NETHER_PORTAL_GLOWING_POWER_ENDER * 0.05;
	#endif

	emission = albedoC.r * albedoC.b;
	emission *= emission;
	emission *= emission;
	emission = clamp(emission * glowPowerMultiplier * 12.0, 0.004, 1.0);

	#if NEW_NETHER_PORTAL > 1
	vec2 portalCoord = abs(vTexCoord.xy - 0.5);
	portalCoord = vec2(frameTimeCounter) * 0.013 + 0.0625 * length(portalCoord);
	float noise = texture2D(noisetex, portalCoord).r;
	noise *= noise;
	noise *= noise;
	emission *= noise * 20.0;
	emission = clamp(emission * glowPowerMultiplier * 15.0, 0.004, 1.0);
	#endif
	if(emission > 0.25)doLighting = false;
	coloredHandlight = false;
}