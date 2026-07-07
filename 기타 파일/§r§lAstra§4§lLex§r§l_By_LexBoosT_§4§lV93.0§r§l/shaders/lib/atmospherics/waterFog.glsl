vec4 GetWaterFog(vec3 viewPos) {
    float fog = length(viewPos) / waterFogRange;
    fog = 1.0 - exp(-4.0 * fog);

    #ifdef OVERWORLD
    vec3 waterFogColor = mix(waterColor.rgb, weatherCol.rgb * 0.25, rainFactor * 0.25);
    waterFogColor *= 0.15 + dayFactor * 0.05;
    #else
    vec3 waterFogColor = waterColor.rgb;
    #endif

    #ifdef ENABLE_DARKNESS_EFFECT
        float darknessFactor = (MC_VERSION >= 11900) ? darknessFactor : 0.0;
        waterFogColor *= 0.125 * (1.0 - max(blindFactor, darknessFactor));
    #endif

    vec3 waterFogTint;
    #if defined(OVERWORLD)
        waterFogTint = lightCol * max(0.25, shadowFade);
    #elif defined(NETHER)
        waterFogTint = netherCol.rgb;
    #elif defined(END)
        waterFogTint = endCol.rgb;
    #endif

    waterFogTint = sqrt(waterFogTint * dot(waterFogTint, waterFogTint));


    return vec4(waterFogColor * waterFogTint, clamp01(fog));
}