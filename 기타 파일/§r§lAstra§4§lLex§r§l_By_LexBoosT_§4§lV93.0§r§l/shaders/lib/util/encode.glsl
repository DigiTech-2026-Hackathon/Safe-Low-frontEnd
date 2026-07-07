vec2 EncodeNormal(vec3 normal) {
	float p = sqrt(normal.z * 8.0 + 8.0);
	return vec2(normal.xy / p + 0.5);
}

vec3 DecodeNormal(vec2 enc) {
	vec2 fenc = enc * 4.0 - 2.0;
	float f = dot(fenc, fenc);
	float g = sqrt(1.0 - f / 4.0);
	vec3 normal;
	normal.xy = fenc * g;
	normal.z = 1.0 - f / 2.0;
	return normal;
}