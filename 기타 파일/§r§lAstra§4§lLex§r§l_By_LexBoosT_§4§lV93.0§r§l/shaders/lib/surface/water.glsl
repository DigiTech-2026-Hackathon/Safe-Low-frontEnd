float GetWaterHeightMap(vec3 worldPos, vec2 offset) {
	float noise = 0.0;
	float noiseA = 0.0;
	float noiseB = 0.0;

	vec2 wind = vec2(frameTimeCounter) * 0.5 * WATER_SPEED;

	worldPos.xz += worldPos.y * 0.25;

	#if WATER_MODE == 0
		offset /= 128.0;
		noiseA = texture2D(noisetex, (worldPos.xz - wind) / 64.0 + offset).g;
		noiseB = texture2D(noisetex, (worldPos.xz + wind) / 12.0 + offset).g;
		noise = mix(noiseA, noiseB, WATER_DETAIL);
	#else
		noise = 0.0;
	#endif

	return noise * WATER_BUMP;
}

vec3 GetParallaxWaves(vec3 worldPos, vec3 viewVector) {
	vec3 parallaxPos = worldPos;

	for(int i = 0; i < 4; i ++ ) {
		float height = - 1.25 * GetWaterHeightMap(parallaxPos, vec2(0.0)) + 0.25;
		parallaxPos.xz += height * viewVector.xy / dist;
	}
	return parallaxPos;
}

vec3 GetWaterNormal(vec3 worldPos, vec3 viewPos, vec3 viewVector) {
	vec3 waterPos = worldPos + cameraPosition;

	#ifdef WATER_PARALLAX
	waterPos = GetParallaxWaves(waterPos, viewVector);
	#endif

	float normalOffset = WATER_SHARPNESS;

	float fresnel = pow(clamp01(1.0 + dot(normalize(normal), normalize(viewPos))), 5.0);
	float normalStrength = 0.35 * (1.0 - fresnel);

	float h1 = GetWaterHeightMap(waterPos, vec2(normalOffset, 0.0));
	float h2 = GetWaterHeightMap(waterPos, vec2(- normalOffset, 0.0));
	float h3 = GetWaterHeightMap(waterPos, vec2(0.0, normalOffset));
	float h4 = GetWaterHeightMap(waterPos, vec2(0.0, - normalOffset));

	float xDelta = (h2 - h1) / normalOffset;
	float yDelta = (h4 - h3) / normalOffset;

	vec3 normalMap = vec3(xDelta, yDelta, 1.0 - (xDelta * xDelta + yDelta * yDelta));
	return normalMap * normalStrength + vec3(0.0, 0.0, 1.0 - normalStrength);
}