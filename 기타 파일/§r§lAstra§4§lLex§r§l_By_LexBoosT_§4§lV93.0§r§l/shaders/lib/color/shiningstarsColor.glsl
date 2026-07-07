#include "/settings/color/shiningstarsColorSettings.glsl"

vec3 shiningStarsCol = vec3(R_SSTARS, G_SSTARS, B_SSTARS) * vec3(2.2) * S_SSTARS_INTENSITY * 5.0 / 255.0;
vec3 shiningStarsColSqrt = shiningStarsCol * shiningStarsCol;

vec3 lineCol = vec3(R_LINE, G_LINE, B_LINE) * vec3(2.2) * LINE_INTENSITY / 255.0;
vec3 lineColSqrt = lineCol * lineCol;