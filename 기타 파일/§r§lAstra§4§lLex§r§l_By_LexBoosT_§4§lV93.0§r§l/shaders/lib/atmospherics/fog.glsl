#if defined(OVERWORLD)

vec3 GetFogColor(vec3 viewPos) {
    vec3 nViewPos = normalize(viewPos);
    float lViewPos = length(viewPos) / 64.0;
    lViewPos = 1.0 - exp(-lViewPos * lViewPos);

    float density = 0.4;
    float nightDensity = 1.0;
    float weatherDensity = 1.5;
    float groundDensity = 0.1 * (4.0 - 3.0 * sunVisibility) *
        (10.0 * rainFactor * rainFactor + 1.0);
    float exposure = exp2(dayFactor * 0.75 - 0.75);
    float nightExposure = exp2(-3.5);

    float ndotVoU = dot(nViewPos, upVec) * 0.5 + 0.5;
    float ndotVoS = dot(nViewPos, sunVec) * 0.5 + 0.5;

    float baseGradient = exp(-(ndotVoU * 0.5 + 0.5) * 0.5 / density);

    vec3 fog = fogCol * baseGradient / (SKY_I * SKY_I);
    fog = fog / sqrt(fog * fog + 1.0) * exposure * sunVisibility * (SKY_I * SKY_I);

    float sunMix = (ndotVoS * 0.5 + 0.5) * pow(clamp(1.0 - ndotVoU, 0.0, 1.0), 2.0 - sunVisibility) *
        pow(1.0 - dayFactor * 0.6, 3.0);
    float horizonMix = pow(1.0 - abs(ndotVoU), 2.5) * 0.125;
    float lightMix = (1.0 - (1.0 - sunMix) * (1.0 - horizonMix)) * lViewPos;

    vec3 lightFog = pow(lightSun, vec3(4.0 - sunVisibility)) * baseGradient;
    lightFog = lightFog / (1.0 + lightFog * rainFactor);

    fog = mix(sqrt(fog * (1.0 - lightMix)), sqrt(lightFog), lightMix);
    fog *= fog;

    float nightGradient = exp(-0.175 * nightDensity * ndotVoU);
    vec3 nightFog = pow2(lightNight) * nightGradient * nightExposure;
    nightFog *= mix(SKY_NIGHT, 1.0, sunVisibility);
    fog = mix(nightFog, fog, sunVisibility * sunVisibility);

    float rainGradient = exp(-0.0825 * weatherDensity * ndotVoU);
    vec3 weatherFog = weatherCol.rgb * weatherCol.rgb;
    weatherFog *= GetLuminance(ambientCol / weatherFog) * (0.2 * sunVisibility + 0.2);
    fog = mix(fog, weatherFog * rainGradient, rainFactor);

    #ifdef UNDERGROUND_FOG
    fog = mix(minLightCol * 0.2, fog * eBS, eBS);
    #endif

    return fog;
}

#endif

vec3 NormalFog(vec3 color, vec3 viewPos) {
    float viewLength = length(viewPos);
    vec3 fogColor = vec3(1.0);
    float fog = 0.0;

    #if DISTANT_FADE > 0
    #if DISTANT_FADE_STYLE == 0
    float fogFactor = viewLength;
    #else
    vec4 worldPos = gbufferModelViewInverse * vec4(viewPos, 1.0);
    worldPos.xyz /= worldPos.w;
    float fogFactor = length(worldPos.xz);
    #endif
    #endif

    #if defined(OVERWORLD)
    float fogDensity = OVERWORLD_FOG_DENSITY;

    #if SUNVISIBILITY_FOG == 1
    fogDensity *= 3.0 - sunVisibility * 2.0;

    #elif SUNVISIBILITY_FOG == 2
    fogDensity *= 4.0 - sunVisibility * 3.0;

    #elif SUNVISIBILITY_FOG == 3
    fogDensity *= 5.0 - sunVisibility * 4.0;

    #elif SUNVISIBILITY_FOG == 4
    fogDensity *= 6.0 - sunVisibility * 5.0;
    #endif

    fog = viewLength * fogDensity / 256.0;
    float clearDay = sunVisibility * (1.0 - rainFactor);

    if (isEyeInWater == 0) {
        #ifdef UNDERGROUND_FOG
        fog *= mix(1.0, (RAIN_FOG_DENSITY * rainFactor + 1.0) / (3.0 * clearDay + 1.0) * eBS, eBS);
        fog = 1.0 - exp(-2.0 * pow(fog, 0.35 * clearDay * eBS + 0.95));
        #else
        fog *= (RAIN_FOG_DENSITY * rainFactor + 1.0) / (3.0 * clearDay + 1.0);
        fog = 1.0 - exp(-2.0 * pow(fog, 0.35 * clearDay + 1.25) * eBS);
        #endif

        fogColor *= GetFogColor(viewPos);
    }

    if (isEyeInWater > 0) {
        fog *= (0.5 * rainFactor + 1.0) / (3.0 * clearDay + 3.0);
        fog = 1.0 - exp(-2.0 * pow(fog, 0.35 * clearDay + 8.0) * eBS);
        fogColor *= GetFogColor(viewPos);
    }

    #if DISTANT_FADE == 1 || DISTANT_FADE == 3
    if (isEyeInWater == 0) {

        float fogOffset = 12.0;
        #if MC_VERSION >= 11800
        fogOffset = 0.0;
        #endif

        float vanillaFog = 1.0 - (far - (fogFactor + fogOffset)) * 5.0 / (OVERWORLD_FOG_DENSITY * far);

        vanillaFog = clamp01(vanillaFog);

        if (vanillaFog > 0.0) {
            vec3 vanillaFogColor = GetSkyColor(viewPos, false);
            vanillaFogColor *= 1.0 + nightVision;

            #ifdef CLASSIC_EXPOSURE
            vanillaFogColor *= 4.0 - 3.0 * eBS;
            #endif

            fogColor *= fog;

            fog = mix(fog, 1.0, vanillaFog);
            if (fog > 0.0)
                fogColor = mix(fogColor, vanillaFogColor, vanillaFog) / fog;
        }
    }
    #endif

    #elif defined(NETHER)
    fog = 2.0 * pow(viewLength * NETHER_FOG_DENSITY / 256.0, 1.5);

    #if (DISTANT_FADE == 2 || DISTANT_FADE == 3)
    fog += 2.0 * pow(fogFactor / far, 6.0);
    #endif

    fog = 1.0 - exp(-fog);
    fogColor = netherCol.rgb * NETHER_FOG_COLOR_M;

    #elif defined(END)

    if (END_FOG_DENSITY <= 0.0) {
        fog = 0.0;
    } else {
        fog = 2.0 * pow(viewLength * END_FOG_DENSITY / 256.0, 1.5);

        #if (DISTANT_FADE == 2 || DISTANT_FADE == 3)
        fog += 2.0 * pow(fogFactor / far, 6.0);
        #endif

        fog = 1.0 - exp(-3.0 * fog);

        if (isEyeInWater == 1) {
            fogColor = endCol.rgb * 0.009;
        } else {
            fogColor = endCol.rgb * 0.04;
        }

        #ifndef LIGHT_SHAFT_END
        fogColor = vec3(0.0);
        #endif
    }

    #endif

    color.rgb = mix(color.rgb, fogColor, fog);

    return color.rgb;
}

vec3 BlindFog(vec3 color, vec3 viewPos) {
    float viewLength = length(viewPos);
    float fog = viewLength * (blindFactor * 0.2);
    fog = 1.0 - exp(-6.0 * pow3(fog));
    color = mix(color, vec3(0.0), fog * blindFactor);
    return color;
}

#if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
vec3 DarknessFog(vec3 color, vec3 viewPos) {
    float viewLength = length(viewPos);
    float fog;
    #if DARKNESS_HARD_FOG == 0
    fog = 2.0 * pow(viewLength * DARKNESS_FOG_DISTANCE / 256.0, 0.8);
    #else
    fog = viewLength * 0.01 * DARKNESS_FOG_DISTANCE;
    #endif
    fog = 1.0 - exp(-6.0 * pow3(fog));
    color = mix(color, darknessColor, fog * darknessFactor);
    return color;
}
#endif

vec3 LavaFog(vec3 color, vec3 viewPos) {
    float fog = length(viewPos) * LAVA_FOG_STRENGTH;
    fog = 1.0 - exp(-4.0 * pow3(fog));

    #if MC_VERSION >= 11700
    if (gl_Fog.start / gl_Fog.end < 0.0) {
        fog = min(length(viewPos) * 0.01, 1.0);
    }
    #endif

    return mix(color, vec3(1.0, 0.3, 0.01), fog);
}

vec3 SnowFog(vec3 color, vec3 viewPos) {
    float fog = length(viewPos) * POWDER_SNOW_FOG_STRENGTH;
    fog = 1.0 - exp(-pow(fog, 3.0));
    return mix(color, vec3(0.1, 0.15, 0.2) * (1.0 - 0.9 * moonVisibility) * eBS, fog);
}

vec3 Fog(vec3 color, vec3 viewPos) {
    color.rgb = NormalFog(color, viewPos);
    color.rgb = mix(color.rgb, LavaFog(color.rgb, viewPos), float(isEyeInWater == 2));
    color.rgb = mix(color.rgb, BlindFog(color.rgb, viewPos), blindFactor);

    #if MC_VERSION >= 11701
    color.rgb = mix(color.rgb, SnowFog(color.rgb, viewPos), float(isEyeInWater == 3));
    #endif

    #if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
    color.rgb = mix(color.rgb, DarknessFog(color.rgb, viewPos), darknessFactor * float(darknessFactor > 0.001));
    #endif
    return color;
}