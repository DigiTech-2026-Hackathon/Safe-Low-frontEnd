
#if (defined OVERWORLD && defined CLOUDS_REFLECTION && REALISTIC_CLOUDS == 1 && defined REFLECTION)
	if (isEyeInWater == 0) {
	cloud = DrawCloud(skyRefPos * 100.0, dither, lightCol, ambientCol, 4);
	cloud.a *= CLOUD_OPACITY * CLOUD_VISIBILITY_WATER_REFLECTION;
	skyReflection = Max0(mix(skyReflection, cloud.rgb, cloud.a));
	}
#endif

#if (defined OVERWORLD && defined CLOUDS_REFLECTION && REALISTIC_CLOUDS == 1 && defined REFLECTION)
	float cloudMask = clamp01(cloud.a * 50.0);
	float cloudMaskStars = clamp01(cloud.a * 20.0);
#else
	float cloudMask = 0.0;
	float cloudMaskStars = 0.0;
#endif

vec3 skyReflectionBase = skyReflection;

#if (defined OVERWORLD && defined STARS && defined STARS_REFLECTION && defined REFLECTION)
	if (moonVisibility > 0.0) {

	lightNight *= max(pow(fresnel / 9, 2), 0.00001);
	vec3 stars1 = vec3(0.0);
	if (skyRefFactor > 0.5) DrawStars(albedo.rgb, skyRefPos * 100.0);
	vec3 stars = mix(vec3(0.0), stars1, 1.0 - cloudMaskStars);

	skyReflection += stars.rgb * WATER_STARS_REFLECTION_STRENGTH * 0.5;

	lightNight /= max(pow(fresnel / 9, 2), 0.00001);
}
#endif

#if (defined OVERWORLD && defined SHOOTING_STARS && defined SHOOTING_STARS_REFLECTION && defined REFLECTION)
    if (moonVisibility > 0.0) {
        for (int i = 0; i < NUM_SHOOTING_STARS; i++) {
            float size = 1.0 + (i * 0.2);
            skyReflection += DrawShootingStar(albedo.rgb, skyRefPos * 100.0, size, dither);
        }
    }
#endif

vec4 srpl = gbufferModelViewInverse*vec4(skyRefPos * 100, 1.0);
	 srpl /= srpl.w;
vec3 skyRefPosLunar = getLunarCoord(srpl.xyz);


#if (defined OVERWORLD && defined SHININGSTARS && defined SHININGSTARS_REFLECTION && defined REFLECTION)
if (moonVisibility > 0.0) {
	skyReflection = mix(skyReflection, DrawConstellations(skyReflection, skyRefPosLunar.xyz, dither, 1.0),
	(1.0 - rainFactor) * (1.0 - cloudMaskStars) * moonVisibility * SHININGSTARS_REFLECTION_STRENGTH);
}
#endif

#if (defined OVERWORLD && ((defined PLANET || defined PLANET2) && defined PLANET_REFLECTION) && defined REFLECTION)
skyReflection = mix(skyReflection.rgb,
	drawPlanetImage(skyReflection.rgb, skyReflection.rgb, vec2(0.2 * PLANET_SIZE_X, 0.2 * PLANET_SIZE_Y), skyRefPosLunar.xyz, colortex9, PLANET_OPACITY),
	(1.0 - rainFactor) * (1.0 - cloudMask) * mix(PLANET_REFLECTION_STRENGTH_NIGHT, PLANET_REFLECTION_STRENGTH_DAY, sunVisibility)
);
#endif

#if (defined OVERWORLD && defined NEBULA && defined NEBULA_REFLECTION && defined REFLECTION)
if (moonVisibility > 0.0) {
	skyReflection = mix(skyReflection.rgb,
		drawNebulaImage(skyReflection.rgb, vec2(0.2 * NEBULA_SIZE_X, 0.2 * NEBULA_SIZE_Y), skyRefPosLunar.xyz, colortex10, NEBULA_OPACITY),
		(1.0 - rainFactor) * (1.0 - cloudMask) * NEBULA_REFLECTION_STRENGTH_NIGHT
	);
}
#endif

#if (defined OVERWORLD && defined GALAXY && defined GALAXY_REFLECTION && defined REFLECTION)
if (moonVisibility > 0.0) {
	skyReflection = mix(skyReflection.rgb,
		drawGalaxyImage(skyReflection.rgb, vec2(0.2 * GALAXY_SIZE_X, 0.2 * GALAXY_SIZE_Y), skyRefPosLunar.xyz, colortex11, GALAXY_OPACITY),
		(1.0 - rainFactor) * (1.0 - cloudMask) * GALAXY_REFLECTION_STRENGTH_NIGHT
	);
}
#endif

#if (defined OVERWORLD && defined AURORA && defined AURORA_REFLECTION && defined REFLECTION)
if (moonVisibility > 0.0) {
	skyReflection += DrawAurora(skyRefPos * 100.0, dither, 15) * AURORA_REFLECTION_STRENGTH * (1.0 - cloudMask);
}
#endif

float alt = normalize(srpl.xyz).y;
#if HORIZON_MIRROR_REFLECTION == 1
float altfade = clamp01(alt / 0.4 - 0.1);
#else
float altfade = 1.0;
#endif

skyReflection = mix(skyReflectionBase, skyReflection, altfade);
