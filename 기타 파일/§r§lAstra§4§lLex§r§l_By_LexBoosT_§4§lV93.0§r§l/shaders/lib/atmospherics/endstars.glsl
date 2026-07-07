vec3 DrawEndStars(vec3 EndStarsColor, vec3 EndStarsViewPos) {
    vec3 wpos = vec3(gbufferModelViewInverse * vec4(EndStarsViewPos, 1.0));
    if (wpos.y < 0)
    wpos = - wpos;
    vec3 planeCoord = 0.75 * wpos / (wpos.y + length(wpos.xz));

    float starJitter = 1.0;

    #ifdef STARS_JITTER
    vec3 planeCoordNorm = normalize(planeCoord);
    float jitterBias = mix(5.0, 20.0, abs(sin(planeCoordNorm.y * 15.0) + sin(planeCoordNorm.x * 15.0) * cos(planeCoordNorm.z * 15.0)) * 0.5);
    starJitter = sin(frameTimeCounter * 5.0 * STARS_JITTER_SPEED + jitterBias * 2.0) * 0.5 + 0.6;
    #endif

    float NdotVoU = clamp01(dot(normalize(EndStarsViewPos), normalize(upVec)));

    float NdotVoUF = abs(NdotVoU);
    NdotVoUF = 1.0 - NdotVoUF;
    NdotVoUF = pow(NdotVoUF, (2.0 - NdotVoUF) * (3.0 - 0.8));
    NdotVoUF = Max0(NdotVoUF);

    vec2 coord = planeCoord.xz * 0.75;
    coord = floor(coord * 1024.0) / 1024.0;

    float multiplier = sqrt(sqrt(NdotVoUF)) * 6.0;
    float star = 1.0;
    if (NdotVoUF > 0.0) {
        star *= GetNoise(coord.xy);
        star *= GetNoise(coord.xy + 0.1);
        star *= GetNoise(coord.xy + 0.23);
    }
    star = Max0(star - 0.780) * multiplier;

    #if NEW_ENDER_STARS == 1
    float star2 = 1.0;
    if (NdotVoUF > 0.0) {
        star2 *= GetNoise(coord.xy);
        star2 *= GetNoise(coord.xy + 0.2);
        star2 *= GetNoise(coord.xy + 0.43);
    }
    star2 = Max0(star2 - 0.840) * multiplier;
    #endif

    #if NEW_ENDER_STARS == 1
    EndStarsColor.rgb += star * pow(lightNight * 400, vec3(1.0, 0.0, 0.9176)) * pow4(starJitter) + star2 * pow(lightNight * 400, vec3(0.0, 0.0, 1.0)) * pow4(starJitter);
    #else
    EndStarsColor.rgb += star * pow(pow2(lightNight) * 400, vec3(1.0)) * pow4(starJitter);
    #endif

    return clamp(EndStarsColor, 0.0, 2.0);
}