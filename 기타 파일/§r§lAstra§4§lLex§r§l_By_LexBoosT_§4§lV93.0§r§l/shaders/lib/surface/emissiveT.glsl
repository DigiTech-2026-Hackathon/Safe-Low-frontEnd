#include "/settings/glowingBlocksSettings.glsl"

void getEmissiveT(in vec3 viewPos, inout float emission, in vec4 detectcolor, inout vec4 albedo, inout vec2 lightmap, inout bool doLighting, inout bool coloredHandlight) {

    float lengthAlbedo = clamp01(length(albedo.rgb));

    /*
    Redstone
    */
    if (mat > 3.98 && mat < 4.02) {

        #if defined (NETHER)
        emission = REDSTONE_BLOCK_BRIGHTNESS_NETHER * 0.25;
        #elif defined (END)
        emission = REDSTONE_BLOCK_BRIGHTNESS_ENDER * 0.25;
        #elif defined (OVERWORLD)
        emission = REDSTONE_BLOCK_BRIGHTNESS_OVERWORLD * 0.25;
        #endif
        if(emission > 0.25) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Lapis Lazuli
    */
    else if (mat > 4.98 && mat < 5.02) {

        #if defined (NETHER)
        emission = LAPIS_BLOCK_BRIGHTNESS_NETHER ;
        #elif defined (END)
        emission = LAPIS_BLOCK_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission = LAPIS_BLOCK_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Candle
    */
    else if (mat > 5.98 && mat < 6.02) {
        emission = pow4(lengthAlbedo) * 0.01;
        #if defined (NETHER)
        emission *= 1.0 + CANDLE_BRIGHTNESS_NETHER;
        #elif defined (END)
        emission *= 1.0 + CANDLE_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission *= 1.0 + CANDLE_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    #ifdef GLOW_BERRIES
        if (mat > 6.98 && mat < 7.02) {
            if (detectcolor.r > 0.5 && detectcolor.g > 0.5 && detectcolor.b > 0.10 && detectcolor.g < detectcolor.r) {

                #if defined (NETHER)
                emission += GLOW_BERRIES_GLOWING_POWER_NETHER * 5.0;
                #elif defined (END)
                emission += GLOW_BERRIES_GLOWING_POWER_ENDER * 5.0;
                #elif defined (OVERWORLD)
                emission += GLOW_BERRIES_GLOWING_POWER * 5.0;
                #endif
                if(emission > 0.5) doLighting = false;
            }
            coloredHandlight = false;
        }
    #endif

    #ifdef GLOW_SPORE_BLOSSOM
        if (mat > 7.98 && mat < 8.02) {
            if (detectcolor.r > 0.1 && detectcolor.g > 0.20 && detectcolor.b < 0.32 && detectcolor.g < detectcolor.r) {

                #if defined (NETHER)
                emission += GLOW_SPORE_BLOSSOM_GLOWING_POWER_NETHER * 5.0;
                #elif defined (END)
                emission += GLOW_SPORE_BLOSSOM_GLOWING_POWER_ENDER * 5.0;
                #elif defined (OVERWORLD)
                emission += GLOW_SPORE_BLOSSOM_GLOWING_POWER * 5.0;
                #endif
                if(emission > 0.5) doLighting = false;
            }
            coloredHandlight = false;
        }
    #endif

    /*
    Lantern
    */
    else if (mat > 8.98 && mat < 9.02) {
        emission = float(lengthAlbedo > 0.9) * 0.25;

        #if defined (NETHER)
        emission *= 1.0 + LANTERN_BRIGHTNESS_NETHER * 4.0;
        #elif defined (END)
        emission *= 1.0 + LANTERN_BRIGHTNESS_ENDER * 4.0;
        #elif defined (OVERWORLD)
        emission *= 1.0 + LANTERN_BRIGHTNESS_OVERWORLD * 4.0;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Soul Lantern
    */
    else if (mat > 9.98 && mat < 10.02) {
        emission = float(lengthAlbedo > 0.9) * 0.125;

        #if defined (NETHER)
        emission *= 1.0 + SOUL_LANTERN_BRIGHTNESS_NETHER * 8.0;
        #elif defined (END)
        emission *= 1.0 + SOUL_LANTERN_BRIGHTNESS_ENDER * 8.0;
        #elif defined (OVERWORLD)
        emission *= 1.0 + SOUL_LANTERN_BRIGHTNESS_OVERWORLD * 8.0;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    #ifdef GLOW_LICHEN
        if (mat > 10.98 && mat < 11.02) {
            if (detectcolor.r > 0.25 && detectcolor.b > 0.15 && detectcolor.g > 0.10 && detectcolor.b < detectcolor.r) {

                #if defined (NETHER)
                emission += GLOW_LICHEN_GLOWING_POWER_NETHER;
                #elif defined (END)
                emission += GLOW_LICHEN_GLOWING_POWER_ENDER;
                #elif defined (OVERWORLD)
                emission += GLOW_LICHEN_GLOWING_POWER;
                #endif
                if(emission > 0.5) doLighting = false;
            }
            coloredHandlight = false;
        }
    #endif

    #ifdef GLOW_PICKLE
        if (mat > 11.98 && mat < 12.02) {
            if (detectcolor.g > 0.8) {
                albedo.rgb = vec3(0.7725, 0.902, 0.5373);

                #if defined (NETHER)
                emission += GLOW_PICKLE_GLOWING_POWER_NETHER;
                #elif defined (END)
                emission += GLOW_PICKLE_GLOWING_POWER_ENDER;
                #elif defined (OVERWORLD)
                emission += GLOW_PICKLE_GLOWING_POWER * (1.0 - moonVisibility * 0.8);
                #endif
                if(emission > 0.5) doLighting = false;
            }
            coloredHandlight = false;
        }
    #endif

    /*
    Beacon
    */
    else if (mat > 12.98 && mat < 13.02) {

        #if defined (NETHER)
        emission += BEACON_LANTERN_BRIGHTNESS_NETHER;
        #elif defined (END)
        emission += BEACON_LANTERN_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission += BEACON_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.0) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Small Ametyst
    */
    else if (mat > 13.98 && mat < 14.02) {

        #if defined (NETHER)
        emission += SMALL_AMETYST_BRIGHTNESS_NETHER * 0.1;
        #elif defined (END)
        emission += SMALL_AMETYST_BRIGHTNESS_ENDER * 0.1;
        #elif defined (OVERWORLD)
        emission += SMALL_AMETYST_BRIGHTNESS_OVERWORLD * 0.1;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Medium Ametyst
    */
    else if (mat > 14.98 && mat < 15.02) {

        #if defined (NETHER)
        emission += MEDIUM_AMETYST_BRIGHTNESS_NETHER * 0.1;
        #elif defined (END)
        emission += MEDIUM_AMETYST_BRIGHTNESS_ENDER * 0.1;
        #elif defined (OVERWORLD)
        emission += MEDIUM_AMETYST_BRIGHTNESS_OVERWORLD * 0.1;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Large Ametyst
    */
    else if (mat > 15.98 && mat < 16.02) {

        #if defined (NETHER)
        emission += LARGE_AMETYST_BRIGHTNESS_NETHER * 0.1;
        #elif defined (END)
        emission += LARGE_AMETYST_BRIGHTNESS_ENDER * 0.1;
        #elif defined (OVERWORLD)
        emission += LARGE_AMETYST_BRIGHTNESS_OVERWORLD * 0.1;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Cluster Ametyst
    */
    else if (mat > 16.98 && mat < 17.02) {

        #if defined (NETHER)
        emission += AMETYST_CLUSTER_BRIGHTNESS_NETHER * 0.1;
        #elif defined (END)
        emission += AMETYST_CLUSTER_BRIGHTNESS_ENDER * 0.1;
        #elif defined (OVERWORLD)
        emission += AMETYST_CLUSTER_BRIGHTNESS_OVERWORLD * 0.1;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Enchanted Table Emissivness
    */
    else if (mat > 17.98 && mat < 18.02) {

        #if defined (NETHER)
        emission += ENCHANTED_TABLE_BRIGHTNESS_NETHER;
        #elif defined (END)
        emission += ENCHANTED_TABLE_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission += ENCHANTED_TABLE_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Magma Block
    */
    else if (mat > 18.98 && mat < 19.02) {

        #if defined (NETHER)
        emission += MAGMA_BRIGHTNESS_NETHER;
        #elif defined (END)
        emission += MAGMA_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission += MAGMA_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Sculk Catalyst
    */
    else if (mat > 19.98 && mat < 20.02) {

        #if defined (NETHER)
        emission += SCULK_CATALYST_BRIGHTNESS_NETHER;
        #elif defined (END)
        emission += SCULK_CATALYST_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission += SCULK_CATALYST_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Sculk Vein
    */
    else if (mat > 20.98 && mat < 21.02) {

        #if defined (NETHER)
        emission += SCULK_VEIN_BRIGHTNESS_NETHER;
        #elif defined (END)
        emission += SCULK_VEIN_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission += SCULK_VEIN_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Sculk Shrieker
    */
    else if (mat > 21.98 && mat < 22.02) {

        #if defined (NETHER)
        emission += SCULK_SHRIEKER_BRIGHTNESS_NETHER;
        #elif defined (END)
        emission += SCULK_SHRIEKER_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission += SCULK_SHRIEKER_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Sculk
    */
    else if (mat > 22.98 && mat < 23.02) {

        #if defined (NETHER)
        emission += SCULK_BRIGHTNESS_NETHER;
        #elif defined (END)
        emission += SCULK_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission += SCULK_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Sculk Sensor
    */
    else if (mat > 23.98 && mat < 24.02) {

        #if defined (NETHER)
        emission += SCULK_SENSOR_BRIGHTNESS_NETHER;
        #elif defined (END)
        emission += SCULK_SENSOR_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission += SCULK_SENSOR_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Fire / Soul Fire
    */
    else if (mat > 24.98 && mat < 25.02) {
        emission = pow4(lengthAlbedo) * 0.001;

        #if defined (NETHER)
        emission *= 1.0 + FIRE_BRIGHTNESS_NETHER * 200;
        #elif defined (END)
        emission *= 1.0 + FIRE_BRIGHTNESS_ENDER * 200;
        #elif defined (OVERWORLD)
        emission *= 1.0 + FIRE_BRIGHTNESS_OVERWORLD * 200;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Shroom Light
    */
    else if (mat > 25.98 && mat < 26.02) {

        #if defined (NETHER)
        emission += SHROOMLIGHT_BRIGHTNESS_NETHER;
        #elif defined (END)
        emission += SHROOMLIGHT_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission += SHROOMLIGHT_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Redstone Lamp
    */
    else if (mat > 26.98 && mat < 27.02) {

        #if defined (NETHER)
        emission += REDSTONE_LAMP_BRIGHTNESS_NETHER;
        #elif defined (END)
        emission += REDSTONE_LAMP_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission += REDSTONE_LAMP_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Sea Lantern
    */
    else if (mat > 27.98 && mat < 28.02) {
        emission = min(lengthAlbedo * 2.0, 0.1);

        #if defined (NETHER)
        emission *= 1.0 + SEA_LANTERN_BRIGHTNESS_NETHER * 10.0;
        #elif defined (END)
        emission *= 1.0 + SEA_LANTERN_BRIGHTNESS_ENDER * 10.0;
        #elif defined (OVERWORLD)
        emission *= 1.0 + SEA_LANTERN_BRIGHTNESS_OVERWORLD * 10.0;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    GlowStone
    */
    else if (mat > 28.98 && mat < 29.02) {

        #if defined (NETHER)
        emission += GLOWSTONE_BRIGHTNESS_NETHER * 5.0;
        #elif defined (END)
        emission += GLOWSTONE_BRIGHTNESS_ENDER * 5.0;
        #elif defined (OVERWORLD)
        emission += GLOWSTONE_BRIGHTNESS_OVERWORLD * 10.0;
        #endif
        coloredHandlight = false;
    }

    /*
    Jack'o Lantern
    */
    else if (mat > 29.98 && mat < 30.02) {

        #if defined (NETHER)
        emission += JACKOLANTERN_BRIGHTNESS_NETHER;
        #elif defined (END)
        emission += JACKOLANTERN_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission += JACKOLANTERN_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Torch / End_Rod
    */
    else if (mat > 30.98 && mat < 31.02) {
        emission = pow4(lengthAlbedo) * 0.001;
        #if defined (NETHER)
        emission += TORCH_ENDROD_BRIGHTNESS_NETHER;
        #elif defined (END)
        emission += TORCH_ENDROD_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission += TORCH_ENDROD_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Campfire
    */
    else if (mat > 31.98 && mat < 32.02) {

        #if defined (NETHER)
        emission += CAMPFIRE_BRIGHTNESS_NETHER;
        #elif defined (END)
        emission += CAMPFIRE_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission += CAMPFIRE_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Soul CampFire / Soul Fire / Soul Torch
    */
    else if (mat > 32.98 && mat < 33.02) {

        #if defined (NETHER)
        emission += SCAMPFIRE_BRIGHTNESS_NETHER;
        #elif defined (END)
        emission += SCAMPFIRE_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission += SCAMPFIRE_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Frog Light
    */
    else if (mat > 33.98 && mat < 34.02) {

        #if defined (NETHER)
        emission += FROGLIGHT_BRIGHTNESS_NETHER;
        #elif defined (END)
        emission += FROGLIGHT_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission += FROGLIGHT_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Copper_bulb / Waxed_copper_bulb:lit=true
    */
    else if (mat > 34.98 && mat < 35.02) {
        #if defined (NETHER)
        emission += COPPER_LAMP_BRIGHTNESS_NETHER;
        #elif defined (END)
        emission += COPPER_LAMP_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission += COPPER_LAMP_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }
    /*
    Exposed_copper_bulb / Waxed_exposed_copper_bulb
    */
    else if (mat > 35.98 && mat < 36.02) {
        #if defined (NETHER)
        emission += COPPER_LAMP_BRIGHTNESS_NETHER1;
        #elif defined (END)
        emission += COPPER_LAMP_BRIGHTNESS_ENDER1;
        #elif defined (OVERWORLD)
        emission += COPPER_LAMP_BRIGHTNESS_OVERWORLD1;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }
    /*
    weathered_copper_bulb / Waxed_weathered_copper_bulb
    */
    else if (mat > 36.98 && mat < 37.02) {
        #if defined (NETHER)
        emission += COPPER_LAMP_BRIGHTNESS_NETHER2;
        #elif defined (END)
        emission += COPPER_LAMP_BRIGHTNESS_ENDER2;
        #elif defined (OVERWORLD)
        emission += COPPER_LAMP_BRIGHTNESS_OVERWORLD2;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }
    /*
    Oxidized_copper_bulb / Waxed_oxidized_copper_bulb
    */
    else if (mat > 37.98 && mat < 38.02) {
        #if defined (NETHER)
        emission += COPPER_LAMP_BRIGHTNESS_NETHER3;
        #elif defined (END)
        emission += COPPER_LAMP_BRIGHTNESS_ENDER3;
        #elif defined (OVERWORLD)
        emission += COPPER_LAMP_BRIGHTNESS_OVERWORLD3;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }
    /*
    Crying Obsidian and Respawn Anchor
    */
    else if (mat > 40.98 && mat < 41.02) {
        emission = (detectcolor.b - detectcolor.r) * detectcolor.r;
        #if defined (NETHER)
        emission += emission * CO_RA_BRIGHTNESS_NETHER * 10.0;
        #elif defined (END)
        emission += emission * CO_RA_BRIGHTNESS_ENDER * 10.0;
        #elif defined (OVERWORLD)
        emission += emission * CO_RA_BRIGHTNESS_OVERWORLD * 10.0;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Sculk Sensor
    */
    else if (mat > 41.98 && mat < 42.02) {
        emission = min(lengthAlbedo, 0.1);
        #if defined (NETHER)
        emission += SCULK_SENSOR_BRIGHTNESS_NETHER;
        #elif defined (END)
        emission += SCULK_SENSOR_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission += SCULK_SENSOR_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Calibrated Sculk Sensor
    */
    else if (mat > 42.98 && mat < 43.02) {
        emission = min(lengthAlbedo, 0.01);
        #if defined (NETHER)
        emission += SCULK_SENSOR_BRIGHTNESS_NETHER;
        #elif defined (END)
        emission += SCULK_SENSOR_BRIGHTNESS_ENDER;
        #elif defined (OVERWORLD)
        emission += SCULK_SENSOR_BRIGHTNESS_OVERWORLD;
        #endif
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Brewing Stand
    */
    else if (mat > 45.98 && mat < 46.02) {
        emission = float(albedo.r > 0.5 && albedo.b < 0.4) * 0.3;
        coloredHandlight = false;
    }

    /*
    Torch Flower
    */
    else if (mat > 46.98 && mat < 47.02) {
        emission = float(albedo.r > 0.5 && albedo.b < 0.4) * 0.1;
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    /*
    Lava
    */
    else if (mat > 98.98 && mat < 99.02) {
        emission = float(albedo.r > 0.5 && albedo.b < 0.4) * 0.1;
        if(emission > 0.5) doLighting = false;
        coloredHandlight = false;
    }

    #if (defined CHORUS_EMISSIVE_O || defined CHORUS_EMISSIVE_N || defined CHORUS_EMISSIVE_E)
        float emissive_chorus_strength = 0.0;
        #if defined(OVERWORLD) && defined CHORUS_EMISSIVE_O
        emissive_chorus_strength= CHORUS_EMISSIVE_STRENGTH_O;
        #elif defined(NETHER) && defined CHORUS_EMISSIVE_N
        emissive_chorus_strength= CHORUS_EMISSIVE_STRENGTH_N;
        #elif defined(END) && defined CHORUS_EMISSIVE_E
        emissive_chorus_strength= CHORUS_EMISSIVE_STRENGTH_E;
        #endif

        if (mat > 104.98 && mat < 105.02) { // Chorus
            emission = pow8(albedo.g) * emissive_chorus_strength;
            if(emission > 0.1) doLighting = false;
        }
    #endif

    /*
    Emissive Ores
    */
    #ifdef EMISSIVE_ORES
            float oresEmission = 0.0;
            float detectOre = 0.0;
            float stoneDetect = 0.0;
            float emissiveMult = EMISSIVE_ORES_BRIGHTNESS_STRENGTH;

        if (mat > 139.98 && mat < 140.02 || mat > 140.98 && mat < 141.02 || mat > 141.98 && mat < 142.02 || mat > 142.98 && mat < 143.02 || mat > 143.98 && mat < 144.02) {

            float stoneDetect = max(abs(detectcolor.r - detectcolor.g), max(abs(detectcolor.r - detectcolor.b), abs(detectcolor.g - detectcolor.b)));

            float ores = Max0(Max0(stoneDetect - 0.175));
            oresEmission = ores * 2.0;

            if (mat > 140.98 && mat < 141.02) {// only gold
                emissiveMult *= 0.7;
            }
            if (mat > 141.98 && mat < 142.02) { // only iron
                emissiveMult *= 3.0;
            }
            if (mat > 142.98 && mat < 143.02) {// only emerald
                emissiveMult *= 0.5;
            }
            if (mat > 143.98 && mat < 144.02) {// only redstone
                emissiveMult *= 0.5;
            }
        }

        else if (mat > 105.98 && mat < 106.02) { // Nether Quartz Ore

        detectOre = pow4(albedo.g) * 0.3;
        oresEmission = detectOre * 2.0;
        emissiveMult *= 0.75;
        }

        else if (mat > 106.98 && mat < 107.02) { // Nether Gold Ore
            detectOre = float(albedo.r > 0.2 && albedo.b < 0.8 && albedo.g > 0.4) * 0.5;
            oresEmission = detectOre * 2.0;
            emissiveMult *= 0.5;
        }

            #if PICKAXE_REVEAL > 0
            if ((heldItemId == 11000 || heldItemId2 == 11000)) {
                #if PICKAXE_REVEAL > 1

                float oscillation = 0;
                oscillation = sin(frameTimeCounter * 0.75);
                oscillation = pow2(oscillation);

                emission += oresEmission * emissiveMult * oscillation;

                #else

                emission += oresEmission * emissiveMult;

                #endif
            }
            #else
                emission += oresEmission * emissiveMult;
            #endif
    #endif

    #if defined OVERWORLD && EMISSIVE_FLOWERS == 1
        if (isPlant > 0.98 && isPlant < 1.02) { // Flowers
            if (albedo.b > albedo.g || albedo.r > albedo.g && albedo.r > 0.8) {
                #if WEATHER_EMISSIVE_FLOWERS == 0
                emission = (lengthAlbedo * 0.4) * (1.0 - rainFactor);
                #else
                emission = lengthAlbedo * 0.4;
                #endif
                emission *= 2.0 - clamp(length(viewPos) * 0.2, 0.0, 1.0);
                emission *= 0.5 + clamp(sin(frameTimeCounter) * cos(frameTimeCounter * 0.5), 0.0, 0.2);
                emission *= 1.0 - lightmap.y * 0.75;
                emission *= FLOWERS_EMISSIVE_STRENGTH * 0.25;
                if(emission > 0.25) doLighting = false;
            }
        }
        else if (isPlant > 1.98 && isPlant < 2.02) { // white tulip/lily of the valley
            if (albedo.b > albedo.g * 0.5|| albedo.r > albedo.g && albedo.r > 0.8) {
                #if WEATHER_EMISSIVE_FLOWERS == 0
                emission = min(lengthAlbedo * 0.4, 0.4) * (1.0 - rainFactor);
                #else
                emission = min(lengthAlbedo * 0.4, 0.4);
                #endif
                emission *= 2.0 - clamp(length(viewPos) * 0.2, 0.0, 1.0);
                emission *= 0.5 + clamp(sin(frameTimeCounter) * cos(frameTimeCounter * 0.5), 0.0, 0.2);
                emission *= 1.0 - lightmap.y * 0.75;
                emission *= FLOWERS_EMISSIVE_STRENGTH * 0.25;
                if(emission > 0.25) doLighting = false;
            }
        }
    #endif
}
