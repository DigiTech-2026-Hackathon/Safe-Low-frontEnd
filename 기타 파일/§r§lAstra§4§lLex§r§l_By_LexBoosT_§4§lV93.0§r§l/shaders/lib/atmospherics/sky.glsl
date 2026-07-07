#ifdef OVERWORLD
vec3 GetSkyColor(vec3 viewPos, bool isReflection) {
    float timeBrightnessInv = 1.0 - dayFactor;
    float timeBrightnessInv2 = pow2(timeBrightnessInv);
    float timeBrightnessInv4 = pow2(timeBrightnessInv2);

    vec3 nViewPos = normalize(viewPos);

    float ndotVoU = clamp(dot(nViewPos, upVec), - 1.0, 1.0);
    float ndotVoL = clamp(dot(nViewPos, sunVec), - 1.0, 1.0);

    float groundDensity = 0.08 * (4.0 - 3.0 * sunVisibility) * (10.0 * pow2(rainFactor) + 1.0);

    float exposure = exp2(dayFactor * 0.75 - 0.75 + SKY_EXPOSURE_D);
    float nightExposure = exp2(- 3.5 + SKY_EXPOSURE_N);
    float weatherExposure = exp2(SKY_EXPOSURE_W);

    float gradientCurve = mix(SKY_HORIZON_F, SKY_HORIZON_N, ndotVoL);
    float baseGradient = exp(-(1.0 - pow(1.0 - Max0(ndotVoU), gradientCurve)) / (SKY_DENSITY_D + 0.025));
    float ground = 1.0;

    #if SKY_GROUND > 0
    float groundVoU = clamp01(- ndotVoU * 1.015 - 0.015);
    ground = 1.0 - exp(- groundDensity * max(OVERWORLD_FOG_DENSITY, 0.125) / groundVoU);

    #if SKY_GROUND == 1
    if (! isReflection) {
        ground = 1.0;
    }
    #endif
    #endif

    vec3 sky = skyCol * baseGradient / pow2(SKY_I);

    #ifdef SKY_VANILLA
    sky = mix(sky, fogCol * baseGradient, pow(1.0 - Max0(ndotVoU), 4.0));
    #endif

    sky = sky / sqrt(pow2(sky) + 1.0) * exposure * sunVisibility * pow2(SKY_I);
    sky *= 2.0 - 0.5 * timeBrightnessInv4;
    sky *= mix(SKY_NOON, SKY_DAY, timeBrightnessInv4);

    float sunMix = (ndotVoL * 0.5 + 0.5) * pow(clamp01(1.0 - ndotVoU), 2.0 - sunVisibility) *
    pow(1.0 - dayFactor * 0.6, 3.0);
    float horizonMix = pow(1.0 - abs(ndotVoU), 2.5) * 0.125;
    float lightMix = (1.0 - (1.0 - sunMix) * (1.0 - horizonMix));

    vec3 lightSky = pow(lightSun, vec3(4.0 - sunVisibility)) * baseGradient;
    lightSky = lightSky / (1.0 + lightSky * rainFactor);

    sky = mix(sqrt(sky * (1.0 - lightMix)), sqrt(lightSky), lightMix);
    sky *= sky;

    float nightGradient = exp(- Max0(ndotVoL) / SKY_DENSITY_N);
    vec3 nightSky = pow2(lightNight) * nightGradient * nightExposure;
    nightSky *= mix(SKY_NIGHT, 1.0, sunVisibility);
    sky = mix(nightSky, sky, pow2(sunVisibility));

    float rainGradient = exp(- Max0(ndotVoU) / SKY_DENSITY_W);
    vec3 weatherSky = pow2(weatherCol.rgb) * weatherExposure;
    weatherSky *= GetLuminance(ambientCol / (weatherSky)) * (0.2 * sunVisibility + 0.2);
    sky = mix(sky, weatherSky * rainGradient, rainFactor);

    sky *= ground;

    #ifdef UNDERGROUND_SKY
    sky *= 1.0 - isEyeInCave;
    #endif

    return sky;
}

#endif