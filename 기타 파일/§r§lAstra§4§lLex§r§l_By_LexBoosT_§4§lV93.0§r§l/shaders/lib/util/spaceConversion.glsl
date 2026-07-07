vec3 diagonal3(mat4 m) {
    return vec3(m[0][0], m[1][1], m[2][2]);
}

vec3 projMAD(mat4 m, vec3 v) {
    return (diagonal3(m) * v) + m[3].xyz;
}

vec3 ScreenToView(vec3 pos) {
	vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw);
	vec3 p3 = pos * 2.0 - 1.0;
	vec4 viewPos = iProjDiag * p3.xyzz + gbufferProjectionInverse[3];
	return viewPos.xyz / viewPos.w;
}

vec3 ViewToPlayer(vec3 pos) {
	return mat3(gbufferModelViewInverse) * pos + gbufferModelViewInverse[3].xyz;
}

vec3 WorldToShadow(vec3 pos) {
	vec3 shadowpos = mat3(shadowModelView) * pos + shadowModelView[3].xyz;
	return projMAD(shadowProjection, shadowpos);
}