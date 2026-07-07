#include "/settings/color/endColorSettings.glsl"
/*
END COLOR
*/
vec4 endColSqrt = vec4(vec3(END_R, END_G, END_B) / 255.0, 1.0) * END_I;
vec4 endCol = endColSqrt * endColSqrt;

/*
END LOST GLARE COLOR
*/
vec4 endColSqrt2 = vec4(vec3(G_END_R, G_END_G, G_END_B) / 255.0, 1.0) * LOST_GLARE_INTENSITY;

/*
END LIGHT_SHAFT COLOR
*/
vec4 endColSqrt3 = vec4(vec3(L_END_R, L_END_G, L_END_B) / 255.0, 1.0) * LIGHT_SHAFT_INTENSITY_END;

/*
END SKY COLOR CUSTOM
*/
vec4 endColSqrt4 = vec4(vec3(S_END_R, S_END_G, S_END_B) / 255.0, 1.0) * S_END_I;
vec4 endColCustom = endColSqrt4 * endColSqrt4;

/*
VORTEX COLOR
*/
vec4 endColoSqrt5 = vec4(vec3(V_END_R, V_END_G, V_END_B) / 255.0, 1.0);
vec4 endColVortex = endColoSqrt5 * endColoSqrt5;