vec4 RaytraceWater(sampler2D depthtex, vec3 viewPos, vec3 normal, float dither, out float border) {
    vec3 pos = vec3(0.0);
    float dist = 0.0;
    float finalDither = 0.0;

    vec3 start = viewPos + normal * 0.075;

    vec3 vector = 0.5 * reflect(normalize(viewPos), normalize(normal));
    viewPos += vector;
    vec3 tvector = vector;

    float difFactor = 0.4;
    int sr = 0;

    for(int i = 0; i < 30; i ++ ) {
        pos = nvec3(gbufferProjection * nvec4(viewPos)) * 0.5 + 0.5;
        if (pos.x < - 0.05 || pos.x > 1.05 || pos.y < - 0.05 || pos.y > 1.05)
        break;

        vec3 rfragpos = vec3(pos.xy, texture2D(depthtex, pos.xy).r);
        rfragpos = nvec3(gbufferProjectionInverse * nvec4(rfragpos * 2.0 - 1.0));
        dist = length(start - rfragpos);

        float err = length(viewPos - rfragpos);
        float lVector = length(vector) * (1.0 + clamp(0.25 * sqrt(dist), 0.3, 0.8));
        if (err < lVector ||(dist < difFactor && err > difFactor)) {
            sr ++ ;
            if (sr >= 6)
            break;
            tvector -= vector;
            vector *= 0.1;
        }
        vector *= 2.0;

        #if WATER_MODE > 0
        finalDither = (dither * 0.05 + 1.0);
        #else
        finalDither = 1.0;
        #endif

        tvector += vector * finalDither;
        viewPos = start + tvector;
    }

    return vec4(pos, dist);
}

vec4 SimpleReflection(vec3 viewPos, vec3 normal, float dither, out float reflectionMask) {
	vec4 color = vec4(0.0);
	float border = 0.0;
	reflectionMask = 0.0;

	vec4 pos = RaytraceWater(depthtex1, viewPos, normal, dither, border);

	border = clamp01(1.0 - pow(cdist(pos.xy), 50.0));

	#if REFLECTION_SKYBOX > 0
	float zThreshold = 1.0 + EPS;
	#else
	float zThreshold = 1.0 - EPS;
	#endif

	if (pos.z < zThreshold) {

		color = texture2D(gaux2, pos.xy);

		reflectionMask = color.a;

		#if REFLECTION_SKYBOX > 0
		color.a = 1.0;
		#endif

		color.a *= border;
		reflectionMask *= border;
	}

	return color;
}