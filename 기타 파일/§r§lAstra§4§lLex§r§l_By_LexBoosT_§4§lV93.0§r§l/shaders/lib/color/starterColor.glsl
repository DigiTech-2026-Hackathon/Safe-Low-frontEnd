#include "/settings/color/starterColorSettings.glsl"

vec3 starterColor = vec3(S_RED, S_GREEN, S_BLUE) * GetLuminance(color.rgb) * S_INTENSITY / 255;