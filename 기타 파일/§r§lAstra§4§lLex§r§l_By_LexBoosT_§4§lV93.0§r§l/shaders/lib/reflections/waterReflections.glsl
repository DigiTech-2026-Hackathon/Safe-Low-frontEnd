#if WATER_MODE == 0
albedo.rgb = waterColor.rgb * pow2(waterAlpha);

	#ifdef WATER_REVERB
		if (isEyeInWater == 1) {
		albedo.a = 1.0 - pow2(pow2(1.0 - albedo.a * fresnelWR2));
		albedo.a = max(albedo.a, 0.0002);
		} else albedo.a = waterAlpha;
	#endif

#elif WATER_MODE == 1

	albedo.a *= length(albedo.rgb) * waterAlpha * 1.5;
	float albedoTex = pow2(albedoT.r * albedoT.r);
	albedo.rgb = waterColor.rgb * albedoTex + 4.0 * waterColor.rgb * albedoTex;
	albedo.rgb = mix(albedo.rgb, albedo.rgb * color.rgb, 0.5);
	if (waterAlpha > 0.82) albedo.rgb = min(albedo.rgb * (1.0 + length(albedo.rgb) * pow(waterAlpha, 32.0) * 50.0), vec3(2.0));
	if (isEyeInWater == 1) albedo.a = 0.5;

#elif WATER_MODE == 2

	if (isEyeInWater < 0.5){
		albedo.rgb = pow(albedo.rgb, vec3(2.2)) * 0.4;
		albedo.a *= 1.0 - pow2(1.0 - waterAlpha);
	}else{
		albedo.rgb = pow(albedo.rgb, vec3(2.2)) * 5.0;
		albedo.a *= 1.0 - pow8(1.0 - waterAlpha);
	}
#endif

if (isEyeInWater == 0) {
	#ifdef ABSORPTION
		colorTer = texture2D(gaux2, gl_FragCoord.xy / vec2(viewWidth, viewHeight)).rgb;
	#endif

	vec2 texCoordOP = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
	float depthT = texture2D(depthtex1, texCoordOP).r;
	vec3 screenPosOP = vec3(texCoordOP, depthT);

	#if AA > 1
		vec3 viewPosOP = ScreenToView(vec3(TAAJitter(screenPosOP.xy, - 0.5), screenPosOP.z));
	#else
		vec3 viewPosOP = ScreenToView(screenPosOP);
	#endif

	lViewPosOP = length(viewPosOP);
	difOP = (lViewPosOP - lViewPos);
	albedo.a = WaterOp(albedo.a, difOP, fresnel2, lViewPos);
}

baseReflectance = vec3(0.02);