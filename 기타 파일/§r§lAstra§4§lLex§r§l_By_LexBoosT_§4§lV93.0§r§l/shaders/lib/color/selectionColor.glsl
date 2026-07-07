#include "/settings/color/selectionColorSettings.glsl"

vec3 selectionColSqrt = vec3(COMPOSANTE_R, COMPOSANTE_G, COMPOSANTE_B) * COMPOSANTE_I / 255.0;
vec3 selectionCol = selectionColSqrt * selectionColSqrt;