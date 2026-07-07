uniform sampler2DShadow shadowtex0;

#ifdef COLORED_SHADOWS
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;
#endif

const vec2 shadowOffsets[9] = vec2[9](
    vec2(0.0, 0.0),
    vec2(0.5, 0.5),
    vec2(0.5, 0.0),
    vec2(0.5, - 0.5),
    vec2(0.0, - 0.5),
    vec2(-0.5, - 0.5),
    vec2(-0.5, 0.0),
    vec2(-0.5, 0.5),
    vec2(0.0, 0.5)
);

#if (defined TAA_SHADOW_FILTER || defined WATER_CAUSTICS)
vec2 offsetDist(float x, float s) {
    float n = fract(x * 1.414) * PI;
    return vec2(cos(n), sin(n)) * 1.4 * x / s;
}
#endif

vec3 DistortShadow(vec3 worldPos, float distortFactor) {
    worldPos.xy /= distortFactor;
    worldPos.z *= 0.2;
    return worldPos * 0.5 + 0.5;
}

vec3 SampleBasicShadow(vec3 shadowPos, float subsurface) {
    float shadow0 = shadow2D(shadowtex0, vec3(shadowPos.xy, shadowPos.z)).x;

    vec3 shadowCol = vec3(0.33);

    #ifdef COLORED_SHADOWS
    if (shadow0 < 1.0) {
        shadowCol = texture2D(shadowcolor0, shadowPos.xy).rgb * 1.5 *
        shadow2D(shadowtex1, vec3(shadowPos.xy, shadowPos.z)).x;
    }
    #endif

    shadow0 *= mix(shadow0, 1.0, subsurface);

    return clamp(shadowCol * (1.0 - shadow0) + shadow0, vec3(0.0), vec3(1.5));
}

float ApplyGaussianBlur(vec3 shadowPos, float offset, int kernelSize) {
    float shadowSum = 0.0;
    float weightSum = 0.0;
    float invOffsetSqr = 1.0 / (2.0 * offset * offset);

    for (int i = -kernelSize; i <= kernelSize; i++) {
        for (int j = -kernelSize; j <= kernelSize; j++) {
            vec2 shadowOffset = vec2(float(i), float(j)) * offset;
            float weight = exp(-(shadowOffset.x * shadowOffset.x + shadowOffset.y * shadowOffset.y) * invOffsetSqr);
            shadowSum += weight * shadow2D(shadowtex0, vec3(shadowPos.xy + shadowOffset, shadowPos.z)).x;
            weightSum += weight;
        }
    }

    return shadowSum / weightSum;
}

vec3 SampleFilteredShadow(vec3 shadowPos, float offset, float subsurface, float dither) {
    float shadow0 = 0.0;

    shadow0 = ApplyGaussianBlur(shadowPos, offset, 1);

    for(int i = 0; i < 9; i++) {
        vec2 shadowOffset = shadowOffsets[i] * offset;
        shadow0 += shadow2D(shadowtex0, vec3(shadowPos.xy + shadowOffset, shadowPos.z)).x;
    }
    shadow0 /= 9.0;

    vec3 shadowCol = vec3(0.33);

    #ifdef COLORED_SHADOWS
    if (shadow0 < 1.0) {
        for(int i = 0; i < 9; i++) {
            vec2 shadowOffset = shadowOffsets[i] * offset;
            shadowCol += texture2D(shadowcolor0, shadowPos.xy + shadowOffset).rgb * 1.5 *
                shadow2D(shadowtex1, vec3(shadowPos.xy + shadowOffset, shadowPos.z)).x;
        }
        shadowCol /= 9.0;
    }
    #endif

    shadow0 *= mix(shadow0, 1.0, subsurface);

    return clamp(shadowCol * (1.0 - shadow0) + shadow0, vec3(0.0), vec3(1.5));
}

#ifdef TAA_SHADOW_FILTER

vec3 SampleTAAFilteredShadow(vec3 shadowPos, float offset, float subsurface, float dither) {
    float shadow0 = 0.0;

    shadow0 = ApplyGaussianBlur(shadowPos, offset, 1);

    vec3 shadowCol = vec3(0.33);

    #ifdef COLORED_SHADOWS
    if (shadow0 < 1.0) {
        for(int i = 0; i < 4; i++) {
            vec2 shadowOffset = offsetDist(dither + i, 2) * offset;
            shadowCol += texture2D(shadowcolor0, shadowPos.xy + shadowOffset).rgb * 1.5 *
            shadow2D(shadowtex1, vec3(shadowPos.xy + shadowOffset, shadowPos.z)).x;
        }
        shadowCol /= 4;
    }
    #endif

    shadow0 *= mix(shadow0, 1.0, subsurface);

    return clamp(shadowCol * (1.0 - shadow0) + shadow0, vec3(0.0), vec3(1.5));
}

#endif

#if (defined WATER_CAUSTICS && defined OVERWORLD)
vec3 CausticsFilteredShadow(vec3 shadowPos, float offset, float subsurface, float dither) {
    float shadow0 = 0.0;

    shadow0 = ApplyGaussianBlur(shadowPos, offset, 1);

    vec3 shadowCol = vec3(0.33);

    #ifdef COLORED_SHADOWS
    if (shadow0 < 1.0) {
        for (int i = 0; i < 4; i++) {
            vec2 shadowOffset = offsetDist(dither + i, 1) * offset;
            shadowCol += texture2D(shadowcolor0, shadowPos.xy + shadowOffset).rgb * 1.5 *
                shadow2D(shadowtex1, vec3(shadowPos.xy + shadowOffset, shadowPos.z)).x;
        }
        shadowCol /= 4.0;
    }
    #endif

    shadow0 *= mix(shadow0, 1.0, subsurface);

    return clamp(shadowCol * (1.0 - shadow0) + shadow0, vec3(0.0), vec3(1.5));
}
#endif

vec3 GetShadow(vec3 worldPos, float NoL, float subsurface, float skylight) {
    vec3 shadow = vec3(1.0);

    vec3 shadowPos = WorldToShadow(worldPos);

    float dither = BlueNoise(gl_FragCoord.xy);
    dither = animateDither(dither);

    float distb = sqrt(dot(shadowPos.xy, shadowPos.xy));
    float distortFactor = distb * shadowMapBias + (1.0 - shadowMapBias);
    shadowPos = DistortShadow(shadowPos, distortFactor);

    bool doShadow = shadowPos.x > 0.0 && shadowPos.x < 1.0 &&
    shadowPos.y > 0.0 && shadowPos.y < 1.0;

    #if defined OVERWORLD || defined END
    if (isEyeInWater == 0)
    doShadow = doShadow && skylight > 0.001;
    #endif

    float skylightShadow = smoothstep(0.866, 1.0, skylight);
    if (! doShadow) return vec3(skylightShadow);

    float biasFactor = sqrt(1.0 - NoL * NoL) / NoL;
    float distortBias = distortFactor * shadowDistance / 256.0;
    distortBias *= 8.0 * distortBias;
    float distanceBias = sqrt(dot(worldPos.xyz, worldPos.xyz)) * 0.005;

    float bias = (distortBias * biasFactor + distanceBias + 0.05) / shadowMapResolution;

    float offset = 1.0 / shadowMapResolution;

    if (subsurface > 0.0) {
        float blurFadeIn = clamp(distb * 20.0, 0.0, 1.0);
        float blurFadeOut = 1.0 - clamp(distb * 10.0 - 2.0, 0.0, 1.0);
        float blurMult = blurFadeIn * blurFadeOut * (1.0 - NoL);
              blurMult = blurMult * 1.5 + 1.0;

        offset = 0.0007 * blurMult;
        bias = 0.0002;
    }

    float biasStep = 0.001 * subsurface * (1.0 - NoL);

    shadowPos.z -= bias;

    #if (defined OVERWORLD && defined WATER_CAUSTICS)
    if (isEyeInWater == 1) {
        shadow = CausticsFilteredShadow(shadowPos, offset, subsurface, dither);
    } else {
        #endif

        #ifdef SHADOW_FILTER
        #ifdef TAA_SHADOW_FILTER
        shadow = SampleTAAFilteredShadow(shadowPos, offset, subsurface, dither);
        #else
        shadow = SampleFilteredShadow(shadowPos, offset, subsurface, dither);
        #endif
        #else
        shadow = SampleBasicShadow(shadowPos, subsurface);
        #endif

        #if (defined OVERWORLD && defined WATER_CAUSTICS)
    }
    #endif

    return shadow;
}

vec3 GetSubsurfaceShadow(vec3 worldPos, float subsurface, float skylight) {
    vec3 lowOffset = vec3(0.0);
    vec3 highOffset = vec3(0.0);

    float dither = BlueNoise(gl_FragCoord.xy);
    dither = animateDither(dither);

    vec3 shadowPos = WorldToShadow(worldPos);

    float distb = sqrt(dot(shadowPos.xy, shadowPos.xy));
    float distortFactor = distb * shadowMapBias + (1.0 - shadowMapBias);
    shadowPos = DistortShadow(shadowPos, distortFactor);

    vec3 subsurfaceShadow = vec3(0.0);

    for(int i = 1; i < SSS_QUALITY; i ++ ) {
        dither = fract(dither + 1.618);
        float rot = dither * TAU;
        float dist = (i + dither) / SSS_QUALITY;

        vec2 offset2D = vec2(cos(rot), sin(rot)) * dist;
        float offsetZ = -(dist * dist + 0.025);

        vec3 offsetScale = vec3(0.002 / distortFactor, 0.002 / distortFactor, 0.001) * (subsurface * 0.75 + 0.25);

        lowOffset = vec3(0.0, 0.0, - 0.00025 * (1.0 + dither) * distortFactor);
        highOffset = vec3(offset2D, offsetZ) * offsetScale;

        vec3 offset = vec3(offset2D, offsetZ) * offsetScale;

        vec3 samplePos = shadowPos + offset;
        float shadow0 = shadow2D(shadowtex0, samplePos).x;

        vec3 shadowCol = vec3(0.0);
        #ifdef SHADOW_COLOR
        if (shadow0 < 1.0) {
            shadowCol = texture2D(shadowcolor0, samplePos.xy).rgb *
            shadow2D(shadowtex1, samplePos).x;
        }
        #endif

        subsurfaceShadow += clamp(shadowCol * (1.0 - shadow0) + shadow0, vec3(0.0), vec3(1.0));
    }
    subsurfaceShadow /= SSS_QUALITY;
    subsurfaceShadow *= subsurfaceShadow;

    return subsurfaceShadow;
}