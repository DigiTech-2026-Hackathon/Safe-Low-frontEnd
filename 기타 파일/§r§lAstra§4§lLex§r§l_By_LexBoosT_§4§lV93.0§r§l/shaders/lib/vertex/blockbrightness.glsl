#define OVERWORLD_LAVA_BRIGHTNESS 1.00 //[0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00 4.25 4.50 4.75 5.00]
#define NETHER_LAVA_BRIGHTNESS 1.00 //[0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00 4.25 4.50 4.75 5.00]
#define END_LAVA_BRIGHTNESS 1.00 //[0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00 4.25 4.50 4.75 5.00]

// Lava / Flowing Lava
if (mc_Entity.x == 10248) {
	mat = 99.0, lmCoord.x = 0.9, color.a = 1.0,
	#if defined(NETHER)
	color.rgb = normalize(color.rgb) * vec3(NETHER_LAVA_BRIGHTNESS * 2.5);
	#elif defined(END)
	color.rgb = normalize(color.rgb) * vec3(END_LAVA_BRIGHTNESS * 2.5);
	#elif defined(OVERWORLD)
	color.rgb = normalize(color.rgb) * vec3(OVERWORLD_LAVA_BRIGHTNESS * 2.5);
	#endif
}

// Redstone Block
#ifdef REDSTONE_BLOCK_EMISSIVE
else if (mc_Entity.x == 10220 || mc_Entity.x == 10200) {
	mat = 4.0, lmCoord.x = 0.5;
}
#endif

// Lapis Lazuli Block
#ifdef LAPISLAZUL_BLOCK_EMISSIVE
else if (mc_Entity.x == 10221) {
	mat = 5.0, lmCoord.x = 0.5;
}
#endif

// Candle
else if (mc_Entity.x == 10257) {
	mat = 6.0, lmCoord.x = clamp(lmCoord.x, 0.0, 0.87);
}
// Vine Berries
else if (mc_Entity.x == 10256) {
	mat = 7.0, lmCoord.x = 0.855;
}
// Spore_Blossom
else if (mc_Entity.x == 10112) {
	mat = 8.0;
}
// Lantern
else if (mc_Entity.x == 10251 || mc_Entity.x == 10254) {
	mat = 9.0, lmCoord.x = 0.87;
}
// Soul Lantern
else if (mc_Entity.x == 10226 || mc_Entity.x == 10253) {
	mat = 10.0, lmCoord.x = min(lmCoord.x, 0.77);
}
// lichen
else if (mc_Entity.x == 10255) {
	mat = 11.0;
}
// Pickle
else if (mc_Entity.x == 10259) {
	mat = 12.0;
}
// Beacon
else if (mc_Entity.x == 10250) {
	mat = 13.0;
}
// Small Ametyst
else if (mc_Entity.x == 10260) {
	mat = 14.0;
}
// Medium Ametyst
else if (mc_Entity.x == 10261) {
	mat = 15.0;
}
// Large Ametyst
else if (mc_Entity.x == 10262) {
	mat = 16.0;
}
// Ametyst Cluster
else if (mc_Entity.x == 10263) {
	mat = 17.0;
}
// Chain
else if (mc_Entity.x == 10110) {
	lmCoord.x = clamp01(lmCoord.x);
}
// Enchanted Table
else if (mc_Entity.x == 10264) {
	mat = 18.0;
}
// Magma Block
else if (mc_Entity.x == 10216) {
	mat = 19.0, lmCoord.x = 0.855;
}
// Sculk_Catalyst
else if (mc_Entity.x == 10268) {
	mat = 20.0, lmCoord.x = 0.165;
}
// Sculk_Vein
else if (mc_Entity.x == 10271) {
	mat = 21.0, lmCoord.x = 0.165;
}
// Sculk_Shrieker
else if (mc_Entity.x == 10270) {
	mat = 22.0, lmCoord.x = 0.165;
}
// Sculk
else if (mc_Entity.x == 10272) {
	mat = 23.0, lmCoord.x = 0.165;
}
// Sculk_Sensor
else if (mc_Entity.x == 10273) {
	mat = 24.0, lmCoord.x = 0.165;
}
// Fire / Soul Fire
else if (mc_Entity.x == 10249 || mc_Entity.x == 10252) {
	mat = 25.0, lmCoord.x = 0.855;
}
// Shroomlight
else if (mc_Entity.x == 10217) {
	mat = 26.0, lmCoord.x = 0.855;
}
// Redstone Lamp
else if (mc_Entity.x == 10218) {
	mat = 27.0, lmCoord.x = 0.165;
}
// Sea Lantern
else if (mc_Entity.x == 10219) {
	mat = 28.0, lmCoord.x = 0.855;
}
// GlowStone
else if (mc_Entity.x == 10231) {
	mat = 29.0, lmCoord.x = 0.87;
}
// Jack O Lantern
else if (mc_Entity.x == 10222) {
	mat = 30.0, lmCoord.x = 0.8, color.r*=0.8, color.g *= 0.9;
}
// Soul Torch
else if (mc_Entity.x == 10213) {
	mat = 35.0, lmCoord.x = min1(0.8 + 0.3 * pow2(1.0 - signMidCoordPos.y));
}
// Torch / End Rod
else if (mc_Entity.x == 10214) {
	mat = 31.0, lmCoord.x = min1(0.7 + 0.3 * pow2(1.0 - signMidCoordPos.y));
}
// CampFire
else if (mc_Entity.x == 10215) {
	mat = 32.0, lmCoord.x = min1(0.3 + 0.1 * pow2(1.0 - signMidCoordPos.y));
}
// Soul CampFire / Soul Fire
else if (mc_Entity.x == 10210) {
	mat = 33.0, lmCoord.x = min1(0.3 + 0.1 * pow2(1.0 - signMidCoordPos.y));
}
// Froglight
else if (mc_Entity.x == 10265 || mc_Entity.x == 10266 || mc_Entity.x == 10267) {
	mat = 34.0, lmCoord.x = 0.165;
}
// Copper Lamp
else if (mc_Entity.x == 10278) {
	mat = 35.0, lmCoord.x = 0.165;
}
// Copper Lamp
else if (mc_Entity.x == 10279) {
	mat = 36.0, lmCoord.x = 0.165;
}
// Copper Lamp
else if (mc_Entity.x == 10280) {
	mat = 37.0, lmCoord.x = 0.165;
}
// Copper Lamp
else if (mc_Entity.x == 10281) {
	mat = 38.0, lmCoord.x = 0.165;
}
/*
Emissive Ores
*/
#ifdef EMISSIVE_ORES
else if (mc_Entity.x == 11000) {
	mat = 140.0;
}
else if (mc_Entity.x == 11009) {
	mat = 141.0;
}
else if (mc_Entity.x == 11010) {
	mat = 142.0;
}
else if (mc_Entity.x == 11011) {
	mat = 143.0;
}
else if (mc_Entity.x == 11012) {
	mat = 144.0;
}
#endif

// Crying Obs / Resp Anchor
else if (mc_Entity.x == 11013) {
	mat = 41.0;
}

// Sculk Sensor
else if (mc_Entity.x == 10269 || mc_Entity.x == 10273) {
	mat = 42.0, lmCoord.x = 0.165;
}
// Calibrated Sculk Sensor
else if (mc_Entity.x == 10274) {
	mat = 43.0, lmCoord.x = 0.165;
}
// Brewing Stand
else if (mc_Entity.x == 11006) {
	mat = 46.0;
}

// Torch Flower
else if (mc_Entity.x == 10115) {
	mat = 47.0, lmCoord.x = 0.5;
}

#if defined OVERWORLD && EMISSIVE_FLOWERS == 1
else if (mc_Entity.x == 101 || mc_Entity.x == 1011 || mc_Entity.x == 102 || mc_Entity.x == 103) {
	isPlant = 1.0, color.rgb *= 1.225;
}
else if (mc_Entity.x == 104 || mc_Entity.x == 1041) {
	isPlant = 2.0, color.rgb *= 1.225;
}
#endif