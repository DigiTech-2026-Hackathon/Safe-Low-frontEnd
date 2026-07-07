#include "/settings/color/auroraEndColorSettings.glsl"

vec3 auroraEndLowColSqrt = vec3(AURORAEND_LR, AURORAEND_LG, AURORAEND_LB) * AURORAEND_LI / 255.0;
vec3 auroraEndLowCol = auroraEndLowColSqrt * auroraEndLowColSqrt;
vec3 auroraEndHighColSqrt = vec3(AURORAEND_HR, AURORAEND_HG, AURORAEND_HB) * AURORAEND_HI / 255.0;
vec3 auroraEndHighCol = auroraEndHighColSqrt * auroraEndHighColSqrt;
