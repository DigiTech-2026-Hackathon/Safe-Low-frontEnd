#include "/settings/color/blocklightColorSettings.glsl"

vec3 blocklightColSqrt = vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B) * BLOCKLIGHT_I * 0.33 / 255.0;
vec3 blocklightCol = blocklightColSqrt * blocklightColSqrt;

vec3 HandBlocklightColSqrt = vec3(224.0, 172.0, 136.0) * HAND_BLOCK_LIGHT_STRENGTH / 255.0;
vec3 HandBlocklightCol = HandBlocklightColSqrt * HandBlocklightColSqrt;