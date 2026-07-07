#if defined END_STARS_REF && defined END_STARS
    vec3 endStars = vec3(0.0);
    vec3 endStarsRef = DrawEndStars(albedo.rgb, skyRefPos);
    endStarsRef += endStars;
    skyReflection += endStarsRef * END_STARS_REF_STRENGTH_W;
#endif

#if defined END_AURORA_REF && defined AURORA_END
    vec3 endAurora = vec3(0.0);
    vec3 endAuroraRef = DrawAurora(skyRefPos * 100, dither, 15);
    endAuroraRef += endAurora;
    skyReflection += endAuroraRef * END_AURORA_REF_STRENGTH_W;
#endif

#if defined END_SHOOTING_STARS_REF && defined SHOOTING_STARS_END
    vec3 endShootingStar = vec3(0.0);
    vec3 endShootingStarRef = vec3(0.0);

    for (int i = 0; i < NUM_SHOOTING_STARS; i++) {
        float size = 1.0 + (i * 0.2);
        endShootingStarRef += DrawShootingStar(albedo.rgb, skyRefPos, size, dither);
    }

    endShootingStarRef += endShootingStar;
    skyReflection += endShootingStarRef * END_SHOOTING_STARS_REF_STRENGTH_W;
#endif

#if defined END_FBM_REF && defined FBM
    vec3 endFBM = vec3(0.0);
    vec3 endFBMRef = doFullSkyFBM(albedo.rgb, skyRefPos);
    endFBMRef += endFBM;
    skyReflection += endFBMRef * END_FBM_REF_STRENGTH_W;
#endif