#ifdef PUDDLES_ON_WATER
const float WATER_THRESHOLD = 0.5;
#else
const float WATER_THRESHOLD = 0.0;
#endif

if (water > WATER_THRESHOLD && wetness > 0.001) {
    puddles = GetPuddles(worldPos, newCoord, wetness) * clamp01(NoU) * skyRefFactor;
}

#ifdef WEATHER_PERBIOME
float weatherweight = float(isSnowy + isDesert + isMesa + isSavanna);
puddles *= 1.0 - weatherweight;
#endif

puddles *= clamp01(lightmap.y * 32.0 - 31.0);

float ps = sqrt(1.0 - 0.75 * porosity);
float pd = (0.5 * porosity + 0.15);

smoothness = mix(smoothness * 0.85, 1.0, puddles * ps);
f0 = max(f0, puddles * 0.02);

albedo.rgb *= 1.0 - (puddles * pd);

if (puddles > 0.001 && rainFactor > 0.001) {
    mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x, tangent.y, binormal.y, normal.y, tangent.z, binormal.z, normal.z);

    vec3 puddleNormal = GetPuddleNormal(worldPos, viewPos, tbnMatrix);
    newNormal = normalize(mix(newNormal, puddleNormal, puddles * sqrt(1.0 - porosity) * rainFactor));
}