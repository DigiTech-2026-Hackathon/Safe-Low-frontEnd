#include "/settings/showDarkZonesSettings.glsl"
vec3 showDarkZones(vec3 albedo) {

    float sdzGradient = 0.0;

    #if SDZ_GRADIENT == 1
    sdzGradient = 0.899999;
    #elif SDZ_GRADIENT == 2
    sdzGradient = 0.788889;
    #elif SDZ_GRADIENT == 3
    sdzGradient = 0.666667;
    #endif

    float lxMin = 0.533334;
    float lxMax = sdzGradient;
    float lyMin = 0.533334;
    float lyMax = sdzGradient;
    float xUnlit = 0.0;
    float yDanger = 0.0;

    if (lmCoord.x < lxMin) {
        xUnlit = 1.0;
    } else if (lmCoord.x < lxMax) {
        xUnlit = 1.0 - clamp01((lmCoord.x - lxMin) / (lxMax - lxMin));
    }

    if (lmCoord.y < lyMin) {
        yDanger = 1.0;
    } else if (lmCoord.y < lyMax) {
        yDanger = 1.0 - clamp01((lmCoord.y - lyMin) / (lyMax - lyMin));
    }

    if (xUnlit > 0.0) {

        float indicateFactor = 1.0;

        vec3 dangerColor = mix(vec3(SLV_R, SLV_G, SLV_B) * SLV_I / 10.0, vec3(SLVD_R, SLVD_G, SLVD_B) * SLVD_I / 10.0, yDanger);

        #if BLINKING > 0
        indicateFactor = abs(fract(frameTimeCounter * 0.3) - 0.5) * 2.0;
        #endif

        albedo.rgb = mix(albedo.rgb, dangerColor, indicateFactor * xUnlit);
    }
    return albedo;
}
