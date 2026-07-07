vec2 biomeRefraction(vec2 coord) {

	#ifdef BURNING_EFFECT

	const float refractionBurningMultiplier = BURNING_STRENGTH_REFRACT;

	float burningVisibility = 1.0;
	burningVisibility *= burningSmooth;

	if (burningVisibility >= 0.1) {
		vec2 aspectcorrectBurn = vec2(aspectRatio, 1.0);
		float noiseBurn, burningRefrac;
		vec2 offset;

		for(float i = 8.0; i >= 1.0; i -= 1.0) {
			offset = vec2(0.0, frameTimeCounter * (i * 0.002));
			noiseBurn = texture2D(noisetex, coord.xy * aspectcorrectBurn * (i * 0.001) - offset).x;
			noiseBurn += texture2D(noisetex, coord.xy * aspectcorrectBurn * ((i - 1.0) * 0.001) - offset).x;
			burningRefrac = clamp((noiseBurn - 1.0) * 4.0, 0.0, 1.0);
			coord -= vec2(0.0, coord.y) * refractionBurningMultiplier * burningRefrac * burningVisibility;
		}
	}

	#endif

	#if (defined NETHER && defined NETHER_REFRACT)

	const float refractionNetherMultiplier = STRENGTH_REFRACT;

	float heatNetherVisibility = 1.0;

	#if NETHER_WEATHER_HEAT == 1
	heatNetherVisibility *= biomeHasNoHeatValley;
	#endif

	if (heatNetherVisibility < 0.1) {
		heatNetherVisibility = 0.0;
	}

	if (heatNetherVisibility >= 0.1) {
		vec2 aspectcorrectNether = vec2(aspectRatio, 1.0);
		vec2 delta = vec2(0.0, coord.y) * refractionNetherMultiplier * heatNetherVisibility;
		float netherfrac, noiseNether;

		for(float i = 0.008; i > 0.001; i -= 0.001) {
			noiseNether = texture2D(noisetex, coord.xy * aspectcorrectNether * i - vec2(0.0, frameTimeCounter * (i + 0.006))).x;
			noiseNether += texture2D(noisetex, coord.xy * aspectcorrectNether * (i - 0.001) - vec2(0.0, frameTimeCounter * (i + 0.006))).x;
			netherfrac = clamp01((noiseNether - 1.0) * 5.0);
			coord -= delta * netherfrac;
		}
	}

	#endif

	#if (defined OVERWORLD && defined DESERT_REFRACT)

	const float refractionDesertMultiplier = STRENGTH_DESERT_REFRACT;

	float heatSmooth = biomeHasHeatDesert;
	float heatDesertVisibility = clamp01(pow(eBS, 4.0));

	#if DESERT_WEATHER_HEAT == 1
	heatDesertVisibility *= heatSmooth * sunVisibility * (1.0 - rainStrength);
	#elif DESERT_WEATHER_HEAT == 2
	heatDesertVisibility *= heatSmooth * sunVisibility;
	#elif DESERT_WEATHER_HEAT == 3
	heatDesertVisibility *= heatSmooth * (1.0 - rainStrength);
	#elif DESERT_WEATHER_HEAT == 4
	heatDesertVisibility *= heatSmooth;
	#endif

	if (heatDesertVisibility < 0.1) {
		heatDesertVisibility = 0.0;
	}

	if (heatDesertVisibility >= 0.1) {
		vec2 aspectcorrectDesert = vec2(aspectRatio, 1.0);
		float noiseDesert, desertfrac;
		vec2 coordOffset = vec2(0.0);

		for(int i = 9; i >= 0; i -- ) {
			noiseDesert = texture2D(noisetex, coord.xy * aspectcorrectDesert * (0.009 - float(i) * 0.001) - vec2(0.0, frameTimeCounter * (0.009 - float(i) * 0.001))).x;
			noiseDesert += texture2D(noisetex, coord.xy * aspectcorrectDesert * (0.008 - float(i) * 0.001) - vec2(0.0, frameTimeCounter * (0.009 - float(i) * 0.001))).x;
			desertfrac = clamp((noiseDesert - 1.0) * 5.0, 0.0, 1.0);
			coordOffset = vec2(0.0, coord.y) * refractionDesertMultiplier * desertfrac * heatDesertVisibility;
			coord -= coordOffset;
		}
	}

	#endif

	#if (defined OVERWORLD && defined MESA_REFRACT)

	const float refractionMesaMultiplier = STRENGTH_MESA_REFRACT;

	float heatSmooth2 = biomeHasHeatMesa;
	float heatMesaVisibility = clamp01(pow(eBS, 4.0));

	#if MESA_WEATHER_HEAT == 1
	heatMesaVisibility *= heatSmooth2 * sunVisibility * (1.0 - rainStrength);
	#elif MESA_WEATHER_HEAT == 2
	heatMesaVisibility *= heatSmooth2 * sunVisibility;
	#elif MESA_WEATHER_HEAT == 3
	heatMesaVisibility *= heatSmooth2 * (1.0 - rainStrength);
	#elif MESA_WEATHER_HEAT == 4
	heatMesaVisibility *= heatSmooth2;
	#endif
	if (heatMesaVisibility < 0.1) {
		heatMesaVisibility = 0.0;
	}

	if (heatMesaVisibility >= 0.1) {
		vec2 aspectcorrectMesa = vec2(aspectRatio, 1.0);
		float noiseMesa, mesafrac;
		for(float i = 9.0; i >= 1.0; i -- ) {
			noiseMesa = texture2D(noisetex, coord.xy * aspectcorrectMesa * (i / 1000.0) - vec2(0.0, frameTimeCounter * (i / 1000.0))).x;
			noiseMesa += texture2D(noisetex, coord.xy * aspectcorrectMesa * ((i - 1.0) / 1000.0) - vec2(0.0, frameTimeCounter * (i / 1000.0))).x;
			mesafrac = clamp((noiseMesa - 1.0) * 5.0, 0.0, 1.0);
			coord -= vec2(0.0, coord.y) * refractionMesaMultiplier * mesafrac * heatMesaVisibility;
		}
	}

	#endif

	return coord;
}