#include "/settings/color/entitiesflashSettings.glsl"

vec3 entitiesFlashColSqrt = vec3(ENTITIESFLASH_R, ENTITIESFLASH_G, ENTITIESFLASH_B) * 2.0 / 255.0;
vec3 entitiesFlashCol = entitiesFlashColSqrt * entitiesFlashColSqrt;