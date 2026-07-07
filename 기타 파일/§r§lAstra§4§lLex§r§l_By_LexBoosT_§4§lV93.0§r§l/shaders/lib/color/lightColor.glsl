#include "/settings/color/lightColorSettings.glsl"

#if ((defined MOON_PHASE_LIGHTING || defined NEWMOON_DISABLER_STUFF) && !defined UNIFORM_MOONPHASE)
#define UNIFORM_MOONPHASE
uniform int moonPhase;
#endif

#ifndef MOON_PHASE_LIGHTING
	float nightBrightnessF = NIGHT_BRIGHTNESS;
#else
	float nightBrightnessF = moonPhase == 0 ? NIGHT_BRIGHTNESS * NIGHT_LIGHTING_FULL_MOON : moonPhase != 4 ? NIGHT_BRIGHTNESS * NIGHT_LIGHTING_PARTIAL_MOON : NIGHT_BRIGHTNESS * NIGHT_LIGHTING_NEW_MOON;
#endif

vec3 lightMorning = vec3(LIGHT_MR, LIGHT_MG, LIGHT_MB) * LIGHT_MI / 255.0;

vec3 lightDay = vec3(LIGHT_DR, LIGHT_DG, LIGHT_DB) * LIGHT_DI / 255.0;
vec3 lightEvening = vec3(LIGHT_ER, LIGHT_EG, LIGHT_EB) * LIGHT_EI / 255.0;
vec3 lightNight = vec3(LIGHT_NR, LIGHT_NG, LIGHT_NB) * LIGHT_NI * (screenBrightness2 * 0.125 + 0.80) * 0.4 / 255.0 * nightBrightnessF;

vec3 ambientMorning = vec3(AMBIENT_MR, AMBIENT_MG, AMBIENT_MB) * AMBIENT_MI * 1.1 / 255.0;
vec3 ambientDay = vec3(AMBIENT_DR, AMBIENT_DG, AMBIENT_DB) * AMBIENT_DI * 1.1 / 255.0;
vec3 ambientEvening = vec3(AMBIENT_ER, AMBIENT_EG, AMBIENT_EB) * AMBIENT_EI * 1.1 / 255.0;
vec3 ambientNight = vec3(AMBIENT_NR, AMBIENT_NG, AMBIENT_NB) * AMBIENT_NI * (screenBrightness2 * 0.20 + 0.70) * 0.495 / 255.0 * nightBrightnessF;

#ifdef WEATHER_PERBIOME

	uniform float isDesert, isMesa, isSnowy, isSwamp, isMushroom, isSavanna;

	vec4 weatherRain = vec4(vec3(WEATHER_RR, WEATHER_RG, WEATHER_RB) / 255.0, 1.0) * WEATHER_RI;

	#if USE_COLD == 1
	vec4 weatherCold = vec4(vec3(WEATHER_CR, WEATHER_CG, WEATHER_CB) / 255.0, 1.0) * WEATHER_CI;
	#else
	vec4 weatherCold = vec4(0.0);
	#endif

	#if USE_DESERT == 1
	vec4 weatherDesert = vec4(vec3(WEATHER_DR, WEATHER_DG, WEATHER_DB) / 255.0, 1.0) * WEATHER_DI;
	#else
	vec4 weatherDesert = vec4(0.0);
	#endif

	#if USE_MESA == 1
	vec4 weatherBadlands = vec4(vec3(WEATHER_BR, WEATHER_BG, WEATHER_BB) / 255.0, 1.0) * WEATHER_BI;
	#else
	vec4 weatherBadlands = vec4(0.0);
	#endif

	#if USE_SWAMP == 1
	vec4 weatherSwamp = vec4(vec3(WEATHER_SR, WEATHER_SG, WEATHER_SB) / 255.0, 1.0) * WEATHER_SI;
	#else
	vec4 weatherSwamp = vec4(0.0);
	#endif

	#if USE_MUSHROOM == 1
	vec4 weatherMushroom = vec4(vec3(WEATHER_MR, WEATHER_MG, WEATHER_MB) / 255.0, 1.0) * WEATHER_MI;
	#else
	vec4 weatherMushroom = vec4(0.0);
	#endif

	#if USE_SAVANNA == 1
	vec4 weatherSavanna = vec4(vec3(WEATHER_VR, WEATHER_VG, WEATHER_VB) / 255.0, 1.0) * WEATHER_VI;
	#else
	vec4 weatherSavanna = vec4(0.0);
	#endif

	float weatherWeight = isSnowy * USE_COLD + isDesert * USE_DESERT + isMesa * USE_MESA +
	isSwamp * USE_SWAMP + isMushroom * USE_MUSHROOM + isSavanna * USE_SAVANNA;

	vec4 weatherCol = mix(weatherRain, (weatherCold * isSnowy * USE_COLD + weatherDesert * isDesert * USE_DESERT +
			weatherBadlands * isMesa * USE_MESA + weatherSwamp * isSwamp * USE_SWAMP +
		weatherMushroom * isMushroom * USE_MUSHROOM + weatherSavanna * isSavanna * USE_SAVANNA) /
		max(weatherWeight, 0.0001), weatherWeight);

#else

	vec4 weatherCol = vec4(vec3(WEATHER_RR, WEATHER_RG, WEATHER_RB) / 255.0, 1.0) * WEATHER_RI;

#endif

float mefade = 1.0 - clamp(abs(timeAngle - 0.5) * 8.0 - 1.5, 0.0, 1.0);
float dfade = 1.0 - dayFactor;
float dfade2 = SATURATION_SUNSET_SUNRISE - dayFactor;
float dfadeM2 = 1.0 - dfade * sqrt(dfade);
float dfadeM2_2 = 1.0 - dfade2 * sqrt(dfade2);

vec3 lightSun = mix(mix(lightMorning, lightEvening, mefade), lightDay, dfadeM2_2);

vec3 ambientSun = mix(mix(ambientMorning, ambientEvening, mefade), ambientDay, dfade);

vec3 meL = mix(lightMorning, lightEvening, mefade);
vec3 dayAllL = mix(meL, lightDay, dfadeM2);
vec3 cL = mix(lightNight, dayAllL, sunVisibility);

/*
SunGlare
*/
vec3 cL2Day = mix(dayAllL, dot(dayAllL, vec3(0.299, 0.587, 0.114)) * weatherCol.rgb * (screenBrightness2 * 0.1 + 0.9), rainFactor * 0.6);
vec3 lightColDay = cL2Day * cL2Day;

/*
MoonGlare
*/
vec3 cL2Night = mix(lightNight, dot(lightNight, vec3(0.299, 0.587, 0.114)) * weatherCol.rgb * (screenBrightness2 * 0.1 + 0.9), rainFactor * 0.6);
vec3 lightColNight = cL2Night * cL2Night;

vec3 cL2 = mix(cL, dot(cL, vec3(0.299, 0.587, 0.114)) * weatherCol.rgb * (screenBrightness2 * 0.1 + 0.9), rainFactor * 0.6);
vec3 lightCol = cL2 * cL2;

vec3 meA = mix(ambientMorning, ambientEvening, mefade);
vec3 dayAllA = mix(meA, ambientDay, dfadeM2);
vec3 cA = mix(ambientNight, dayAllA, sunVisibility);
vec3 cA2 = mix(cA, dot(cA, vec3(0.299, 0.587, 0.114)) * weatherCol.rgb * (screenBrightness2 * 0.1 + 0.9), rainFactor * 0.6);
vec3 ambientCol = cA2 * cA2;

vec3 ambientCol2 = mix(mix(ambientSun, weatherCol.rgb, mefade), ambientNight, dfade);

/*////////////////////////////////////
/////Weather Rain / Snow Color///////
//////////////////////////////////*/

vec4 RainSnowColSqrt = vec4(vec3(RS_R, RS_G, RS_B) / 255.0, 1.0) * RS_I;
vec4 finalRainSnowCol = RainSnowColSqrt * RainSnowColSqrt;