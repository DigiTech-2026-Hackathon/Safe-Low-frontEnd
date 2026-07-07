vec3 LostGlare(vec3 LostGlareColor, vec3 nViewPos) {

	float NdotInvL = clamp01(dot(nViewPos, sunVec));
	float visfactor = 0.03;
	float invvisfactor = 1.0 - visfactor;
	float visibility = 0.0;

	visibility = clamp01(NdotInvL * 0.5 + 0.5);
	visibility = visfactor / (1.0 - invvisfactor * visibility) - visfactor;
	visibility = clamp01(visibility * 1.015 / invvisfactor - 0.015);

	visibility = visibility * 0.055;

	vec3 glowCol = clamp01(endColSqrt2.rgb);
	glowCol = pow(glowCol, vec3(2.2)) * LOST_GLARE_INTENSITY * 25.0;

	LostGlareColor += clamp01(glowCol * visibility);

	return LostGlareColor;
}
