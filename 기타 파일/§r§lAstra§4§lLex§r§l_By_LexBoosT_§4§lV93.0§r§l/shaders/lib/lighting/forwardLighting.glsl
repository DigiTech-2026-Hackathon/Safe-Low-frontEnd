float BlueNoise(vec2 coord) {
    return texelFetch(noisetex, ivec2(coord)% 64, 0).b;
}

#if (defined OVERWORLD || defined END)
#include "/lib/lighting/shadows.glsl"
#endif

#include "/settings/color/handlightColorSettings.glsl"
#include "/lib/lighting/colorLighting.glsl"

vec3 toLinear(vec3 color) {

    return mix(color / 12.92, pow((color + 0.055) / 1.055, vec3(2.4)), vec3(greaterThan(color, vec3(0.04045))));
}

vec3 BlackBody(float temperature) {
    temperature /= 100.0;
    if (temperature < 66.0) {
        return vec3(
            1.0,
            clamp(0.3900815787690196 * log(temperature) - 0.6318414437886275, 0.0, 1.0),
            clamp(0.543206789110196 * log(temperature - 10.0) - 1.19625408914, 0.0, 1.0)
        );
    } else {
        return vec3(
            clamp(1.292936186062745 * pow(temperature - 60.0, - 0.1332047592), 0.0, 1.0),
            clamp(1.129890860895294 * pow(temperature - 60.0, - 0.0755148492), 0.0, 1.0),
            1.0
        );
    }
}

float CurveBlockLight(const in float blockLight) {

    float concentrateLight = LIGHT_POWER;

    float bdecode = pow(blockLight, concentrateLight);
    #ifdef GBUFFERS_HAND
    bdecode = pow(blockLight, 0.25);
    #endif
    #ifdef BLOCK_LIGHT_JITTER
    const float bspeed = JITTER_SPEED * 0.5;
    float btime = frameTimeCounter * bspeed;
    float bjitter1 = 1.0 - sin(btime * 1.4 + cos(btime * 6.9) - sin(btime * 9.5)) * JITTER_STRENGTH1;
    float bjitter2 = 1.0 - sin(btime * 1.4 + cos(btime * 3.0) - sin(btime * 4.5)) * JITTER_STRENGTH2;
    float bjitter3 = 1.0 - sin(btime * 1.4 + cos(btime * 1.5) - sin(btime * 2.5)) * JITTER_STRENGTH3;
    bdecode *= bjitter1 * bjitter2 * bjitter3;
    #endif

    return bdecode;
}

float CurveBlockLightHand(const in float blockLighthand) {

    float hdecode = pow(blockLighthand, 4.0);
    #ifdef GBUFFERS_HAND
    hdecode = pow(blockLighthand, 0.25);
    #endif
    #ifdef HAND_BLOCK_LIGHT_JITTER
    const float hspeed = JITTER_SPEED * 0.5;
    float htime = frameTimeCounter * hspeed;
    float hjitter1 = 1.0 - sin(htime * 1.3 + cos(htime * 6.7) - sin(htime * 9.4)) * JITTER_STRENGTH1;
    float hjitter2 = 1.0 - sin(htime * 1.3 + cos(htime * 2.8) - sin(htime * 4.4)) * JITTER_STRENGTH2;
    float hjitter3 = 1.0 - sin(htime * 1.3 + cos(htime * 1.3) - sin(htime * 2.4)) * JITTER_STRENGTH3;
    hdecode *= hjitter1 * hjitter2 * hjitter3;
    #endif

    return hdecode;
}

void GetLighting(inout vec3 albedo, out vec3 shadow, vec3 viewPos, vec3 worldPos, vec2 lightmap, float smoothLighting, float NoL, float vanillaDiffuse, float parallaxShadow, float emission, float subsurface, bool activateBlockLighting, bool activateHandLight, bool coloredHandlight, bool foliage){

        #if ((!defined ADVANCED_MATERIALS && EMISSIVE == 1) || EMISSIVE == 0)
            emission = 0.0;
        #endif

        lightmap.x = Max0(lightmap.x * 1.15 - 0.15);
        lightmap.y = sqrt(lightmap.y);
        float shadowMult = 1.0;
        float shadowTime = 1.0;
        float moonPhaseOffsetShadows = 1.0;
        float newLightmap = 0.0;

        vec3 shadowDecider = vec3(0.0);
        vec3 sceneLighting = vec3(0.0);

        #ifdef NEWMOON_DISABLER_STUFF
            moonPhaseOffsetShadows = 1.0 - (float((moonPhase == 4)) * (1.0 - sunVisibility));
        #endif

        #ifndef SSS
            subsurface = 0.0;
        #endif

    #if (defined OVERWORLD || defined END)

            if (NoL > 0.0 || subsurface > 0.0) {
                shadow = GetShadow(worldPos, NoL, subsurface, lightmap.y);
            }

            shadow *= parallaxShadow;
            shadow = max(shadow, vec3(0.0));
            NoL = clamp01(NoL * 1.01 - 0.01);


        #ifdef OVERWORLD
            #ifdef NEWMOON_DISABLER_STUFF
                shadow = mix(shadow, vec3(lightmap.y) * NEWMOON_SHADOWS_LIGHTMAP_CONTROL, (float(moonPhase == 4) * (1.0 - sunVisibility)));
            #else
                shadow *= moonPhaseOffsetShadows;
            #endif
        #endif

        #if defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900
            if (darknessFactor>0.001) shadow *= 0.25;
        #endif

        vec3 fullShadow = max(shadow * NoL, vec3(0.0));

        if (subsurface > 0.0){
            vec3 subsurfaceShadow = GetSubsurfaceShadow(worldPos, subsurface, lightmap.y);

            float VoL = clamp01(dot(normalize(viewPos.xyz), lightVec) * 0.5 + 0.5);

            float scattering = pow(VoL, 6) * (1.0 - rainFactor) * shadowFade * moonPhaseOffsetShadows;

            vec3 subsurfaceColor = albedo;
            subsurfaceColor = mix(subsurfaceColor, vec3(2.0), pow(subsurfaceShadow, vec3(2.0)));
            subsurfaceColor = mix(subsurfaceColor, vec3(4.0), scattering) * sqrt(subsurface);
            subsurfaceColor *= mix(SSS_NIGHT_STRENGTH, SSS_DAY_STRENGTH, sunVisibility);

            fullShadow = mix(subsurfaceColor * subsurfaceShadow, vec3(1.0), fullShadow);
        }

        #if defined (OVERWORLD)

            shadowMult = (1.0 - 0.95 * rainFactor) * shadowFade;
            shadowTime = abs(sunVisibility - 0.5) * 2.0;
            shadowTime *= shadowTime;
            shadowMult *= shadowTime * shadowTime;

            if (isEyeInWater == 1) ambientCol *= pow(lightmap.y, 2.5);

            vec3 lightingCol = pow(lightCol, vec3(1.0 + sunVisibility * 1.0 - 0.5 * dayFactor));

            shadowDecider = fullShadow * shadowMult;

            if (isEyeInWater == 1) shadowDecider *= pow(min(lightmap.y * 0.80, 1.0), 20.0);

            sceneLighting = mix(mix(ambientCol * AMBIENT_MULT_NIGHT * 3.0, lightingCol * LIGHT_MULT_NIGHT * 3.0, shadowDecider),
                            mix(ambientCol * AMBIENT_GROUND_DAY, lightingCol * LIGHT_GROUND_DAY, shadowDecider),
                            sunVisibility);

            #ifdef CLASSIC_EXPOSURE
                sceneLighting *= 4.0 - 3.0 * eBS;
            #endif

            #if defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900
                if (darknessFactor > 0.001) sceneLighting *= 0.2;
            #endif

            float newlightmapy = lightmap.y;

            vec3 fullShadowCausticsUderwater = max(shadow * NoL, vec3(0.0));

            if (isEyeInWater == 1 ){

                #if (defined WATER_CAUSTICS && defined LIGHT_SHAFT)
                if(length(fullShadowCausticsUderwater) > 0.01){
                    newlightmapy += 0.1;
                }
                #endif

            }else{
                sceneLighting *= pow(newlightmapy, 2.5);
            }

        #elif defined (END)
            float brightnessEnd = 0.0;

            vec3 ambientEnd = endCol.rgb * 0.17;
            vec3 lightEnd = endCol.rgb * 0.37;
            shadowDecider = fullShadow;
            sceneLighting = mix(ambientEnd, lightEnd, shadowDecider);
            sceneLighting *= END_BRIGHTNESS * (0.7 + 0.4 * screenBrightness2);
        #endif

    #else
        sceneLighting = netherColSqrt.rgb * 0.07;
    #endif

    //HandLight/////////////////////////////////

    float distMaxLight = 0.0;
    float distDecline = 0.0;
    float maxLight = 0.0;
    float handTorchLightmap = 0.0;
    float handLightFactor = 0.0;
    vec3 handLightCol = vec3(0.0);
    vec3 finalHandLight = vec3(0.0);

    #if !defined DYNAMIC_HAND_LIGHT && defined BLOCKLIGHT_BY_TEMP
        handLightCol = BlackBody(BLOCKLIGHT_TEMP) * BLOCKLIGHT_LUMA;
    #endif

    float handLight = max(float(heldBlockLightValue), float(heldBlockLightValue2));

    //Lighting on GBUFFERS_BLOCK////////////////
    if (activateHandLight){
    handLightFactor = clamp((handLight - 2.0 * length(viewPos)) / 24.0, 0.0, 0.9333);
    }else{
    handLightFactor = clamp((handLight - 2.0 * length(viewPos)) / 30.0, 0.0, 0.9333);
    }
    ////////////////////////////////////////////

    #if defined GBUFFERS_HAND
        handLightFactor = clamp(handLight / 18.0, 0.0, 0.9333);
        if (isEyeInWater > 0)handLightFactor = mix(clamp(handLight / 18.0, 0.0, 0.955), clamp(handLight / 18.0, 0.0, 0.9333), sunVisibility);
    #endif

    lightmap.x = max(lightmap.x, handLightFactor);

    #ifdef GBUFFERS_HAND
        distMaxLight = 1.0;
        distDecline = 1.0;
        maxLight = 0.8;
    #else
        distMaxLight = (isEyeInWater == 1) ? DIST_MAX_LIGHT * 2.0 : DIST_MAX_LIGHT;
        distDecline  = (isEyeInWater == 1) ? DIST_DECLINE * 2.0 : DIST_DECLINE;
        maxLight = MAX_LIGHT;
    #endif

    ////////////////////////////////////////////

    float lightmapX2 = lightmap.x * lightmap.x;
	float lightmapXM1 = pow2(pow2(lightmapX2)) * lightmapX2;
	float lightmapXM2 = max((lightmap.x) * 0.925, 0.0);

	newLightmap = mix(lightmapXM1 * 5.0 + lightmapXM2, lightmapXM1 * 4.0 + lightmapXM2 * LIGHT_CONCENTRATION, screenBrightness2);

    if (isLightHandled()) {

        handTorchLightmap = smoothClamp(1.0 - ((length(viewPos) - distMaxLight) / (distDecline - distMaxLight)), 0.0, maxLight);

        #ifdef COLORED_DYNAMIC_HAND_LIGHT
            changeLightingColorByHand(handLightCol);
        #else
            if (isLightHandledLow()){
                handLightCol = vec3(0.0) * newLightmap;
            }else{
                handLightCol = vec3(1.0) * newLightmap;
            }
        #endif
    }

    #ifndef GBUFFERS_HAND
        #ifdef BLOCKLIGHT_BY_TEMP
        if(activateBlockLighting){
            blocklightCol=BlackBody(BLOCKLIGHT_TEMP) * BLOCKLIGHT_LUMA;
        }
        #endif
    #endif

    handTorchLightmap =CurveBlockLightHand(handTorchLightmap);

    //For disabled Colored Light on Hands///////
    #ifdef DYNAMIC_HAND_LIGHT
        #ifdef GBUFFERS_HAND
            finalHandLight = vec3(0.5) * (handTorchLightmap);
        #else
            if(coloredHandlight)finalHandLight = handLightCol * (handTorchLightmap) * (blocklightCol * maxLight);
            if(isLightHandledLow())finalHandLight = handLightCol * vec3(0.1) * (handTorchLightmap) * (blocklightCol * maxLight);
        #endif
    #else
        finalHandLight = handLightCol * (handTorchLightmap) * blocklightCol;
    #endif

    ////////////////////////////////////////////

    newLightmap=CurveBlockLight(newLightmap);
    vec3 blockLighting = vec3(0.0);

    //Emin Colored Lighting/////////////////////
    #ifdef OVERWORLD
        #ifdef COLORED_LIGHTING
            float CLr = textureLod(noisetex, 0.00009 * (worldPos.xz + cameraPosition.xz), 0).r;
            float CLg = textureLod(noisetex, 0.00012 * (worldPos.xz + cameraPosition.xz), 0).r;
            float CLb = textureLod(noisetex, 0.00018 * (worldPos.xz + cameraPosition.xz), 0).r;
            blocklightCol = vec3(CLr, CLg, CLb) * 2.2;
            blocklightCol *= blocklightCol;
            blocklightCol *= blocklightCol * 0.1;
            blocklightCol *= sqrt(blocklightCol);
        #endif
        blockLighting=max(blocklightCol * pow2(newLightmap), finalHandLight);
    #else
        blockLighting=max(blocklightCol * pow2(newLightmap), finalHandLight);
    #endif
    ////////////////////////////////////////////

    #ifdef GBUFFERS_HAND
        blockLighting=max(HandBlocklightCol * clamp01(pow16(newLightmap)), finalHandLight);
    #endif

    ////////////////////////////////////////////
    float lightFlatten = clamp01(1.0 - pow(1.0 - emission, 128.0));

    vanillaDiffuse = mix(vanillaDiffuse, 1.0, lightFlatten);
    smoothLighting = mix(smoothLighting, 1.0, lightFlatten);
    smoothLighting = clamp01(smoothLighting);

    float shade = pow(vanillaDiffuse, SHADING_STRENGTH);
    if (!foliage) shade = 1.0;

    vec3 emissiveLighting = albedo.rgb * emission * 6.0 / shade * EMISSIVE_MULTIPLIER;
    if (isEyeInWater >= 1) emissiveLighting = clamp01(emissiveLighting);

    float nightVisionLighting = nightVision * 0.25;

    vec3 minLighting = minLightCol * (1.0 - lightmap.y * lightmap.y);
         minLighting *= ((isEyeInWater == 1) ? MINLIGHT_U_I : MINLIGHT_I);

    albedo *= max(sceneLighting + blockLighting + emissiveLighting + nightVisionLighting + minLighting, vec3(0.0));
    albedo *= shade * smoothLighting * smoothLighting;

    #if (defined GBUFFERS_HAND && defined HAND_BLOOM_REDUCTION)
    float strenghtAlbedo = (albedo.r + albedo.g + albedo.b) / HAND_BLOOM_REDUCTION_STRENGTH;
    if (strenghtAlbedo > 1.0)albedo.rgb = albedo.rgb * max(2.0 - strenghtAlbedo, 0.34);
    #endif

    #if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
    albedo *= 1.0 - clamp(darknessLightFactor * (2.0 - emission * 10000.0), 0.0, 1.0);
    #endif

    #if defined NIGHT_DESATURATION && defined OVERWORLD
        float desatAmount = 1.0 - sqrt(max(sqrt(length(fullShadow / 3.0)) * lightmap.y, lightmap.y)) *
                            sunVisibility * (1.0 - rainFactor * 0.7);
            desatAmount*= smoothstep(0.25, 1.0, (1.0 - lightmap.x) * (1.0 - lightmap.x)) * (1.0 - lightFlatten);
            desatAmount = 1.0 - desatAmount;

        vec3 desatNight   = normalize(lightNight * lightNight + 0.000001);
        vec3 desatWeather = normalize(weatherCol.rgb * weatherCol.rgb + 0.000001);

        float desatNWMix  = (1.0 - sunVisibility) * (1.0 - rainFactor);

        vec3 desatColor = mix(desatWeather, desatNight, desatNWMix);
        desatColor = mix(vec3(0.5), desatColor, sqrt(lightmap.y)) * 1.5;
        vec3 desatAlbedo = mix(albedo, GetLuminance(albedo) * desatColor, 1.0 - DESATURATION_FACTOR * 0.4);

        albedo = mix(desatAlbedo, albedo, desatAmount);
    #endif
}