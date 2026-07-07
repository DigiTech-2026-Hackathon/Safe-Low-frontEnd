vec3 getSpiral(vec2 coord, float NdotS) {
	coord = vec2(atan(coord.y, coord.x) - frameTimeCounter * 0.3, length(coord.xy));
	float center = pow16(1.0 - coord.y) * 14.0;
	float spiral = sin((coord.x + sqrt(coord.y) * 18.0) * 6.0) + center - coord.y;

	return clamp01(endColVortex.rgb * spiral * 0.12 * LOST_GLARE_INTENSITY);
}

vec3 getBlackHole(vec3 color, vec3 worldPos, float NdotS) {
	if (NdotS > 0.0) {
		vec3 sunVecBH = mat3(gbufferModelViewInverse) * sunVec;
		vec2 sunCoord = sunVecBH.xz / (sunVecBH.y + length(sunVecBH));
		vec2 planeCoord = worldPos.xz / (worldPos.y + length(worldPos)) - sunCoord;

		vec3 spiral = getSpiral(planeCoord, NdotS);
		float spiralBrightness = clamp01(length(spiral));
		color = mix(color, spiral, pow2(spiralBrightness));
		color *= pow(clamp01(1.0 - pow16(pow32(NdotS))), 10.0);
	}
	return color;
}