float waterH(vec3 pos) {

    vec2 wind = vec2(frameTimeCounter) * WATER_SPEED * 3.0;

    float noise = 0.0;
    const float scale = 100.0;

    noise += texture2D(noisetex, (pos.xz + wind * 0.1 + pos.y) / scale).g;
    noise += texture2D(noisetex, (pos.xz - wind * 0.2 + pos.y) / scale * 0.5).g;
    noise -= texture2D(noisetex, (pos.xz + wind * 0.3 + pos.y) / scale * 1.0).g;
    noise += texture2D(noisetex, (pos.xz - wind * 0.1 + pos.y) / scale * 1.5).g;
    noise -= texture2D(noisetex, (pos.xz + wind * 0.2 + pos.y) / scale * 3.0).g;

    return noise;
}

float getCausticWaves(vec3 posxz) {

    float deltaPos = 0.1;
    float caustic_h0 = waterH(posxz);
    float caustic_h1 = waterH(posxz + vec3(deltaPos, 0.0, 0.0));
    float caustic_h2 = waterH(posxz + vec3(- deltaPos, 0.0, 0.0));
    float caustic_h3 = waterH(posxz + vec3(0.0, 0.0, deltaPos));
    float caustic_h4 = waterH(posxz + vec3(0.0, 0.0, - deltaPos));

    float absDiffX = abs(caustic_h1 - caustic_h2);
    float absDiffY = abs(caustic_h3 - caustic_h4);
    float caustic_h = (1.0 - abs(0.5 - caustic_h0)) * (1.0 - (absDiffX + absDiffY));

    float causticsVisibilityDay = CAUSTICS_VISIBILITY_DAY;
    float causticsVisibilityNight = CAUSTICS_VISIBILITY_NIGHT;
    float causticsVisibility = mix(causticsVisibilityDay, causticsVisibilityNight, moonVisibility);

    caustic_h = pow(Max0(caustic_h), 10.0) * causticsVisibility;

    return caustic_h;
}

#if (defined PROJECTED_CAUSTICS && defined OVERWORLD)
		float getProjectedCausticWaves(vec3 posxz) {

		float projectedColorMultDay = 50.0 * PROJECTED_VISIBILITY_DAY;
		float projectedColorMultNight = 100.0 * PROJECTED_VISIBILITY_NIGHT;
		float projectedColorMult = mix(projectedColorMultDay, projectedColorMultNight, moonVisibility);

		float deltaPos = 0.1;
		float caustic_h0 = waterH(posxz);
		float caustic_h1 = waterH(posxz + vec3(deltaPos, 0.0, 0.0));
		float caustic_h2 = waterH(posxz + vec3(- deltaPos, 0.0, 0.0));
		float caustic_h3 = waterH(posxz + vec3(0.0, 0.0, deltaPos));
		float caustic_h4 = waterH(posxz + vec3(0.0, 0.0, - deltaPos));

		float absDiffX = abs(caustic_h1 - caustic_h2);
		float absDiffY = abs(caustic_h3 - caustic_h4);
		float caustic_h = (1.0 - abs(0.5 - caustic_h0)) * (1.0 - (absDiffX + absDiffY));

		caustic_h = pow(Max0(caustic_h), 10.0) * projectedColorMult;

		return caustic_h;
	}
	#endif

vec3 GetAlbedo(vec3 albedo, float lightmapX) {
    albedo.rgb *= mix(0.2, 0.8, lightmapX);
    vec3 albedoWithWater = albedo.rgb * rawWaterColor.rgb;
    albedo.rgb += (1.0 - lightmapX) * albedoWithWater;
    return albedo.rgb;
}

vec3 GetCaustics(vec3 albedo, vec3 worldPos, vec3 cameraPosition, vec3 shadow, float skyLightMap, float lightmapX) {
    float causticfactor = 80.0 * (1.0 - sqrt(skyLightMap)) * (1.0 - 0.8 * lightmapX);
    causticfactor *= 0.1 + 0.9 * sqrt(skyLightMap) * (1.05 - rainFactor);

    vec3 causticcol = sqrt(rawWaterColor.rgb + vec3(0.001));
    vec3 causticpos = worldPos + cameraPosition;
    float caustic = getCausticWaves(causticpos);
    vec3 lightcaustic = 2.0 * caustic * causticfactor * causticcol * shadow * shadowFade;

    albedo.rgb = GetAlbedo(albedo, lightmapX);

    #ifdef SHADOW_COLOR
    albedo.rgb += shadow;
    #endif

    albedo.rgb *= 1.0 + lightcaustic;
    return clamp01(albedo.rgb);
}