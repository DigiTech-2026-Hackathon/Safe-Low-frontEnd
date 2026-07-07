bool isLightHandledLeft(){
    return (heldItemId2==13001|| //Glowstone, Torch, Jack'o Lantern, Lantern, Campfire, Shroomlight, Lava Bucket, Blaze Rod
            heldItemId2==13002|| //Beacon
            heldItemId2==13003|| //Redstone Torch
            heldItemId2==13004|| //Soul Lantern, Soul Campfire, Soul Torch
            heldItemId2==13005|| //Sea Lantern
            heldItemId2==13006|| //End Rod, Crying Obsidian, End Crystal, Nether Star
            heldItemId2==13007|| //Sea Pickle
            heldItemId2==13008|| //Conduit
            heldItemId2==13009|| //Froglight ochre
            heldItemId2==13010|| //Froglight Verdant
            heldItemId2==13011|| //Froglight pearl
            heldItemId2==13012); //Magma Block
}
bool isLightHandledRight(){
    return (heldItemId==13001|| //Glowstone, Torch, Jack'o Lantern, Lantern, Campfire, Shroomlight, Lava Bucket, Blaze Rod
            heldItemId==13002|| //Beacon
            heldItemId==13003|| //Redstone Torch
            heldItemId==13004|| //Soul Lantern, Soul Campfire, Soul Torch
            heldItemId==13005|| //Sea Lantern
            heldItemId==13006|| //End Rod, Crying Obsidian, End Crystal, Nether Star
            heldItemId==13007|| //Sea Pickle
            heldItemId==13008|| //Conduit
            heldItemId==13009|| //Froglight ochre
            heldItemId==13010|| //Froglight Verdant
            heldItemId==13011|| //Froglight pearl
            heldItemId==13012); //Magma Block
}

bool isLightHandledLeft1(){
    return (heldItemId2==13003|| //Redstone Torch
            heldItemId2==13007|| //Sea Pickle
            heldItemId2==13008|| //Conduit
            heldItemId2==13012); //Magma Block
}
bool isLightHandledRight1(){
    return (heldItemId==13003|| //Redstone Torch
            heldItemId==13007|| //Sea Pickle
            heldItemId==13008|| //Conduit
            heldItemId==13012); //Magma Block
}

bool isLightHandled(){
    return isLightHandledLeft() || isLightHandledRight();
}

bool isLightHandledLow(){
    return isLightHandledLeft1() || isLightHandledRight1();
}

float handlightGetLuminance(vec3 color){
        return dot(color,vec3(0.299, 0.587, 0.114));
    }

vec3 colorLumSat(vec3 color, float luminance, float saturation){
    vec3 grey = vec3(handlightGetLuminance(color));
    vec3 greyedColor = mix(grey, color, saturation);
    if(luminance<0.5){
        return mix(vec3(0.0), greyedColor, clamp01(luminance * 2.0));
    }else{
        return mix(vec3(1.0), greyedColor, clamp01((1.0 - luminance) * 2.0));
    }
}

void getHandLightColor(inout vec3 lightingColor, int heldItem) {

    if (heldItem == 13002) {
        lightingColor = vec3(0.4863, 0.7686, 0.9882);
        lightingColor = colorLumSat(lightingColor, BEACON_LUM, BEACON_SAT);
    } else if (heldItem == 13003) {
        lightingColor = vec3(0.8863, 0.0235, 0.0235);
        lightingColor = colorLumSat(lightingColor, REDSTONE_LUM, REDSTONE_SAT);
    } else if (heldItem == 13004) {
        lightingColor = vec3(0.0, 0.1843, 1.0);
        lightingColor = colorLumSat(lightingColor, SOUL_LUM, SOUL_SAT);
    } else if (heldItem == 13005) {
        lightingColor = vec3(0.0, 0.8549, 0.6667);
        lightingColor = colorLumSat(lightingColor, SEA_LANTERN_LUM, SEA_LANTERN_SAT);
    } else if (heldItem == 13006) {
        lightingColor = vec3(0.9765, 0.3412, 1.0);
        lightingColor = colorLumSat(lightingColor, END_LUM, END_SAT);
    } else if (heldItem == 13007) {
        lightingColor = vec3(0.8275, 0.8314, 0.4118);
        lightingColor = colorLumSat(lightingColor, PICKLE_LUM, PICKLE_SAT);
    } else if (heldItem == 13008) {
        lightingColor = vec3(0.9922, 0.9255, 0.7059);
        lightingColor = colorLumSat(lightingColor, CONDUIT_LUM, CONDUIT_SAT);
    } else if (heldItem == 13009) {
        lightingColor = vec3(0.8275, 0.8314, 0.4118);
        lightingColor = colorLumSat(lightingColor, OCHRE_LUM, OCHRE_SAT);
    } else if (heldItem == 13010) {
        lightingColor = vec3(0.4941, 0.8314, 0.4118);
        lightingColor = colorLumSat(lightingColor, VERDANT_LUM, VERDANT_SAT);
    } else if (heldItem == 13011) {
        lightingColor = vec3(0.7294, 0.5412, 0.9725);
        lightingColor = colorLumSat(lightingColor, PEARL_LUM, PEARL_SAT);
    } else if (heldItem == 13012) {
        lightingColor = vec3(1.0, 0.2353, 0.0);
        lightingColor = colorLumSat(lightingColor, MAGMA_LUM, MAGMA_SAT);
    } else if (heldItem == 13001) {
        lightingColor = vec3(1.0, 0.3686, 0.0);
        lightingColor = colorLumSat(lightingColor, TORCH_LUM, TORCH_SAT);
    }
}

void changeLightingColorByHand(inout vec3 lightingColor) {
    vec3 leftLightingColor = vec3(0.0);
    vec3 rightLightingColor = vec3(0.0);
    float xpos = (gl_FragCoord.x / viewWidth) * 2.0 - 1.0;
    float fade = (clamp(xpos * 2.0, - 1.0, 1.0) + 1.0) * 0.5;

    if (isLightHandledLeft() || isLightHandledLeft1()) {
        getHandLightColor(leftLightingColor, heldItemId2);
    }
    if (isLightHandledRight() || isLightHandledRight1()) {
        getHandLightColor(rightLightingColor, heldItemId);
    }

    if ((isLightHandledLeft() || isLightHandledLeft1()) && (isLightHandledRight() || isLightHandledRight1())) {
        lightingColor = mix(leftLightingColor, rightLightingColor, fade);
    } else if ((isLightHandledLeft() || isLightHandledLeft1())) {
        lightingColor = leftLightingColor;
    } else if ((isLightHandledRight() || isLightHandledRight1())) {
        lightingColor = rightLightingColor;
    }
}
