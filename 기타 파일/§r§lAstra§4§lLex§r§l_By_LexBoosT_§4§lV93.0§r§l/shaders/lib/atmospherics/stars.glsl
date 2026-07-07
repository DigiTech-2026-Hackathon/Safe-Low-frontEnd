void DrawStars(inout vec3 color, vec3 viewPos) {
    vec4 moonPos = gbufferModelViewInverse * vec4(viewPos, 1.0);
    moonPos /= moonPos.w;
    vec3 moonCoord = getLunarCoord(moonPos.xyz);
    if (moonCoord.y < 0.0)
        moonCoord.y = -moonCoord.y;
    vec3 planeCoord = moonCoord / (moonCoord.y + length(moonCoord.xz));

    float floorStar = 1024.0;
    float floorStar2 = 484.0;
    float multiplier = 0.0;
    float starJitter = 1.0;
    float starsCov = 0.0;
    float star = 1.0;

    #if DOUBLE_LAYER_STARS > 0
    float star2 = 1.0;
    #endif

    float NdotVoU = clamp01(dot(normalize(viewPos.xyz), normalize(upVec)));

    #ifdef SUNSET_SUNRISE_STARS
    multiplier = sqrt(sqrt(NdotVoU)) * STARS_LIGHT_INTENSITY * (1.0 - rainFactor) * max(Max0(1.0 - dayFactor * 3.5) * 0.1, moonVisibility);
    #else
    multiplier = sqrt(sqrt(NdotVoU)) * STARS_LIGHT_INTENSITY * (1.0 - rainFactor) * moonVisibility;
    #endif

    #ifdef STARS_JITTER
    vec3 planeCoordNorm = normalize(planeCoord);
    float jitterBias = mix(5.0, 20.0, abs(sin(planeCoordNorm.y * 10.0) + sin(planeCoordNorm.x * 10.0) * cos(planeCoordNorm.z * 10.0)) * 0.5);
    starJitter = sin(frameTimeCounter * 3.0 * STARS_JITTER_SPEED + jitterBias * 1.5) * 0.5 + 0.5;
    #endif

    if (NdotVoU > 0.0) {
        vec2 starCoord = planeCoord.xz * DISTANCE_STARS;
        starCoord = floor(starCoord * floorStar) / floorStar;

        #if DOUBLE_LAYER_STARS > 0
        vec2 starCoord2 = planeCoord.xz * DISTANCE_STARS;
        starCoord2 = floor(starCoord2 * floorStar2) / floorStar2;
        #endif

        star *= GetNoise(starCoord.xy);
        star *= GetNoise(starCoord.xy + 0.1);
        star *= GetNoise(starCoord.xy + 0.23);

        #if DOUBLE_LAYER_STARS > 0
        star2 *= GetNoise(starCoord2.xy);
        star2 *= GetNoise(starCoord2.xy + vec2(0.274, 0.381)) * 1.02;
        star2 *= GetNoise(starCoord2.xy + vec2(0.308, 0.472)) * 1.02;
        star2 *= GetNoise(starCoord2.xy + vec2(0.438, 0.592)) * 1.02;
        #endif
    }

    #if STARS_COVERAGE == 1
    starsCov = 0.7625;
    #elif STARS_COVERAGE == 2
    starsCov = 0.7125;
    #elif STARS_COVERAGE == 3
    starsCov = 0.6625;
    #endif

    float moonStarsHideSize = MOON_STARS_HIDE_SIZE;
    float moonStarsFade = MOON_STARS_FADE;

    float sinmoonangle = length(moonCoord.xz) / length(moonCoord.xyz);
    multiplier *= clamp01((sinmoonangle - moonStarsHideSize) * moonStarsFade);

    star = clamp01(star - starsCov) * multiplier;

    #if DOUBLE_LAYER_STARS > 0
    star2 = clamp01(star2 - starsCov) * multiplier;
    #endif

    star *= 1.0 - exp(-(10.0 - 9.0 * rainFactor) * NdotVoU);

    #if DOUBLE_LAYER_STARS > 0
    star2 *= 1.0 - exp(-(10.0 - 9.0 * rainFactor) * NdotVoU);
    #endif

    color += star * pow(lightNight, vec3(0.5)) * 5.0 * pow4(starJitter);

    #if DOUBLE_LAYER_STARS > 0
    color += star2 * pow(lightNight, vec3(0.5)) * 100.0 * pow4(starJitter);
    #endif

    #if DOUBLE_LAYER_STARS > 0
    float finalStar1 = star * 25;
    #else
    float finalStar1 = star;
    #endif
}