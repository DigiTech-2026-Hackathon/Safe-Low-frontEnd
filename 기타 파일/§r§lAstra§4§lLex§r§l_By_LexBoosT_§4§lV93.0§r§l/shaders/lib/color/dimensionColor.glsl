#include "/settings/minlightSettings.glsl"

#if defined(OVERWORLD)
#include "lightColor.glsl"
#elif defined(NETHER)
#include "netherColor.glsl"
#elif defined(END)
#include "endColor.glsl"
#endif

vec3 minLightColSqrt = vec3(MINLIGHT_R, MINLIGHT_G, MINLIGHT_B) / 255.0;
vec3 minLightCol = minLightColSqrt * minLightColSqrt * 0.04;