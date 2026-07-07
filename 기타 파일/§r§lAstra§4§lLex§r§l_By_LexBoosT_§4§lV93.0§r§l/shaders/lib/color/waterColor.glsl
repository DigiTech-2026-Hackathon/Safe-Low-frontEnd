#include "/settings/color/waterColorSettings.glsl"

vec4 rawWaterColor = clamp(vec4(pow(fogColor, vec3(UNDERWATER_R, UNDERWATER_G, UNDERWATER_B)) * UNDERWATER_I * 0.2, 1.0), 0.0, 1.0);
vec4 rawWaterColorSqrt = rawWaterColor * rawWaterColor;
vec4 rawWaterColorLightshaft = clamp(vec4(pow(fogColor * 0.25, vec3(UNDERWATERL_R, UNDERWATERL_G, UNDERWATERL_B)) * UNDERWATERL_I * 0.2, 1.0), 0.0, 1.0);
vec4 waterColor = clamp(vec4(WATER_R, WATER_G, WATER_B, 255.0) * WATER_I / 255.0, 0.0, 1.0);
vec4 vanillaWaterColorAbs = clamp(vec4(VANILLA_WATER_ABS_R, VANILLA_WATER_ABS_G, VANILLA_WATER_ABS_B, 255.0) * VANILLA_WATER_ABS_I / 255.0, 0.0, 1.0);
vec4 waterColorSqrt = waterColor * waterColor;

const float waterAlpha = WATER_A;
const float waterFogRange = 128.0 / WATER_FOG_DENSITY;