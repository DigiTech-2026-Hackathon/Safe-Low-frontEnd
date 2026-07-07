float GetNoHSquared(float radiusTan, float NoL, float NoV, float VoL) {
    float radiusCos = 1.0 / sqrt(1.0 + radiusTan * radiusTan);

    float RoL = 2.0 * NoL * NoV - VoL;
    if (RoL >= radiusCos)
    return 1.0;

    float rOverLengthT = radiusCos * radiusTan / sqrt(1.0 - RoL * RoL);
    float NoTr = rOverLengthT * (NoV - RoL * NoL);
    float VoTr = rOverLengthT * (2.0 * NoV * NoV - 1.0 - RoL * VoL);

    float triple = sqrt(clamp01(1.0 - NoL * NoL - NoV * NoV - VoL * VoL + 2.0 * NoL * NoV * VoL));

    float NoBr = rOverLengthT * triple, VoBr = rOverLengthT * (2.0 * triple * NoV);
    float NoLVTr = NoL * radiusCos + NoV + NoTr, VoLVTr = VoL * radiusCos + 1.0 + VoTr;
    float p = NoBr * VoLVTr, q = NoLVTr * VoLVTr, s = VoBr * NoLVTr;
    float xNum = q * (- 0.5 * p + 0.25 * VoBr * NoLVTr);
    float xDenom = p * p + s * ((s - 2.0 * p)) + NoLVTr * ((NoL * radiusCos + NoV) * VoLVTr * VoLVTr +
    q * (- 0.5 * (VoLVTr + VoL * radiusCos) - 0.5));
    float twoX1 = 2.0 * xNum / (xDenom * xDenom + xNum * xNum);
    float sinTheta = twoX1 * xDenom;
    float cosTheta = 1.0 - twoX1 * xNum;
    NoTr = cosTheta * NoTr + sinTheta * NoBr;
    VoTr = cosTheta * VoTr + sinTheta * VoBr;

    float newNoL = NoL * radiusCos + NoTr;
    float newVoL = VoL * radiusCos + VoTr;
    float NoH = NoV + newNoL;
    float HoH = 2.0 * newVoL + 2.0;
    return clamp01(NoH * NoH / HoH);
}

float GGXTrowbridgeReitz(float NoHsqr, float roughness) {
    float roughnessSqr = roughness * roughness;
    float distr = NoHsqr * (roughnessSqr - 1.0) + 1.0;
    return roughnessSqr / (PI * distr * distr);
}

float SchlickGGX(float NoL, float NoV, float roughness) {
    float k = roughness * 0.5;

    float smithL = 0.5 / (NoL * (1.0 - k) + k);
    float smithV = 0.5 / (NoV * (1.0 - k) + k);

    return smithL * smithV;
}

vec3 SphericalGaussianFresnel(float HoL, vec3 baseReflectance) {
    float fresnel = exp2(((- 5.55473 * HoL) - 6.98316) * HoL);
    return fresnel * (1.0 - baseReflectance) + baseReflectance;
}

vec3 GGX(vec3 normal, vec3 viewPos, vec3 lightVec, float smoothness, vec3 baseReflectance, float sunSize) {
    float roughness = max(1.0 - smoothness, 0.025);
    roughness *= roughness;
    viewPos = -viewPos;

    vec3 halfVec = normalize(lightVec + viewPos);

    float HoL = clamp01(dot(halfVec, lightVec));
    float NoL = clamp01(dot(normal, lightVec));
    float NoV = clampInv11(dot(normal, viewPos));
    float VoL = dot(lightVec, viewPos);

    float NoHsqr = GetNoHSquared(sunSize, NoL, NoV, VoL);
    if (NoV < 0.0) {
        NoHsqr = dot(normal, halfVec);
        NoHsqr *= NoHsqr;
    }
    NoV = Max0(NoV);

    float D = GGXTrowbridgeReitz(NoHsqr, roughness);
    vec3 F = SphericalGaussianFresnel(HoL, baseReflectance);
    float G = SchlickGGX(NoL, NoV, roughness);

    float Fl = max(length(F), 0.001);
    vec3 Fn = F / Fl;

    float specular = D * Fl * G;
    vec3 specular3 = specular / (1.0 + 0.03125 / 4.0 * specular) * Fn * NoL;

    if (sunVisibility == 0.0) {
        specular *= float(moonPhase == 0) * 2.0 + 0.65 - float(moonPhase == 4) * 0.65;
    } else {
        specular *= 1.5;
    }

    #ifndef SPECULAR_HIGHLIGHT_ROUGH
    specular3 *= 1.0 - roughness * roughness;
    #endif

    return max(specular3 * (1.0 - isEyeInWater * 0.75), vec3(0.0));

}

vec3 GetSpecularHighlight(vec3 normal, vec3 viewPos, vec3 lightVec, float smoothness, vec3 baseReflectance, vec3 specularColor, vec3 shadow, float smoothLighting) {

    float specCheck = dot(shadow, shadow);

    specCheck *= dot(normal, lightVec);

    if (specCheck < 0.001)
    return vec3(0.0);

    #ifndef SPECULAR_HIGHLIGHT_ROUGH
    if (smoothness < 0.00002) {
        return vec3(0.0);
    }
    #endif

    smoothLighting *= smoothLighting;

    smoothness *= 0.95;

    float sunSize = 2500 / SUNSIZE * 0.333;
    float moonSize = 2500 / SUNSIZE;
    float realSunSize = moonSize;

    #ifdef REAL_SUNSIZE
    realSunSize = mix(moonSize, sunSize, sunVisibility);
    #endif

    vec3 specular = GGX(normal, normalize(viewPos), lightVec, smoothness, baseReflectance, (0.025 * sunVisibility + 0.06) * realSunSize);
    specular *= shadow * shadowFade * smoothLighting;
    specular *= sqrt1inv(rainFactor);

    #ifdef NEWMOON_DISABLER_STUFF
    if (sunVisibility == 0.0) {
        specular *= float(moonPhase == 0) * 2.0 + 0.65 - float(moonPhase == 4) * 0.65;
    }
    #endif

    #if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
    if (darknessFactor > 0.001) {
        specular *= 0.1;
    }
    #endif

    specular *= mix(MOON_REF * 2.0, SUN_REF * 2.0, sunVisibility);

    #ifndef SUN_MOON_REFLECTION
    specular = vec3(0.0);
    #endif

    return max(specular * specularColor, vec3(0.0));
}