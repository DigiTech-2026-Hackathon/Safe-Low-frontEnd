#include "/settings/color/sunraysColorSettings.glsl"

vec3 rayColCustomSqrt = vec3(SRC_R, SRC_G, SRC_B) * vec3(2.2) * SRC_I / 255.0;
vec3 rayColCustom = rayColCustomSqrt * rayColCustomSqrt;

vec3 rayLColSqrt = vec3(SRL2_R, SRL2_G, SRL2_B) * vec3(2.2) * SRL2_I / 255.0;
vec3 rayLCol = rayLColSqrt * rayLColSqrt;