vec3 lexClosest(vec3 finalColor, vec2 pos, float intensity) {
	const int dsDither[16] = int[](- 4, 0, - 3, 1, 2, - 2, 3, - 1, - 3, 1, - 4, 0, 3, - 1, 2, - 2);
	int index = (int(pos.x)& 3) * 4 + (int(pos.y)& 3);

	finalColor.xyz = clamp(finalColor.xyz * (128.0 - 1.0) + dsDither[index] * (intensity * 100), vec3(0), vec3(128.0 - 1.0));

	finalColor /= 128.0;
	return finalColor;
}