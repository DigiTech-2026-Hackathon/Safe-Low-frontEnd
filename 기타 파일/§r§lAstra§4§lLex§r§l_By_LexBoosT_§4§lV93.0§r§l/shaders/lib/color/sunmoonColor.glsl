#include "/settings/color/sunmoonColorSettings.glsl"

vec3 sunColSqrt = vec3(SUN_R, SUN_G, SUN_B) * vec3(2.2) / 255.0;
vec3 sunCol = sunColSqrt * sunColSqrt;

vec3 moonColSqrt = vec3(MOON_R, MOON_G, MOON_B) * vec3(2.2) / 255.0;
vec3 moonCol = moonColSqrt * moonColSqrt;
