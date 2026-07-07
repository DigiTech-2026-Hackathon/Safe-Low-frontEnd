/*#############################################
#    _   ___ _____ ___    _   _    _____  __  #
#   /_\ / __|_   _| _ \  /_\ | |  | __\ \/ /  #
#  / _ \\__ \ | | |   / / _ \| |__| _| >  <   #
# /_/ \_\___/ |_| |_|_\/_/ \_\____|___/_/\_\  #
#											  #
#############################################*/

//Settings//////////////////Settings///////////////////Settings///////////////////Settings//
#include "/settings/about.glsl"
#include "/lib/util/functions.glsl"
#include "/settings/globalSettings.glsl"
#include "/settings/finalSettings.glsl"
#include "/settings/optifineMenu.glsl"

//Varying////////////////////Varying////////////////////Varying////////////////////Varying//
varying vec2 texCoord;
varying vec3 sunVec, upVec, uSunVec;

#ifdef DISTORTION
	varying vec3 vUV;
	varying vec2 vUVDot;
#endif

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

	//Uniforms//
	#ifdef DISTORTION
		uniform int isEyeInWater;
		uniform float aspectRatio;
		uniform mat4 gbufferProjection;
	#endif

	//Common Variables//

	#ifdef DISTORTION
		const float strength=FOV_DISTORTION_STRENGTH;
	#endif

	//Program//
	void main(){
		texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

		gl_Position = ftransform();
		/*////////////////////////////////////////////////////////////////////////
		//////////////////////////////MAIN_DISTORTIONVSH/////////////////////////
		//////////////////////////////////////////////////////////////////////*/

		#ifdef DISTORTION
			float fov = atan(1.0 / gbufferProjection [1][1]);

			if (float(isEyeInWater) > 0.9)
				fov *= 0.85;

			float height = tan(fov / aspectRatio * 0.5);
			float scaledHeight = strength * height;
			float cylAspectRatio = aspectRatio;
			float aspectDiagSq = pow2(aspectRatio) + 1.0;
			float diagSq = pow2(scaledHeight) * aspectDiagSq;
			vec2 signedUV = (2.0 * texCoord.xy + vec2(- 1.0, - 1.0));

			float z = 0.5 * sqrt(diagSq + 1.0) + 0.5;
			float ny = (z - 1.0) / (pow2(cylAspectRatio) + 1.0);

			vUVDot = sqrt(ny) * vec2(cylAspectRatio, 1.0) * signedUV;
			vUV = vec3(0.5, 0.5, 1.0) * z + vec3(- 0.5, - 0.5, 0.0);
			vUV.xy += texCoord.xy;
		#endif

		upVec =normalize(gbufferModelView[1].xyz);
		uSunVec = GetuSunVec();
		sunVec = GetSunVec(uSunVec);

	}

#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

	//Uniforms//
	uniform sampler2D noisetex;
	uniform sampler2D colortex1;

	uniform float aspectRatio;
	uniform float frameTimeCounter;
	uniform float viewWidth, viewHeight;
	uniform float blindness;
	uniform float screenBrightness;

	#if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
			uniform float darknessFactor;
			uniform float darknessLightFactor;
	#endif

	#ifdef HIT_RED_VIGNETTE
		uniform float touchmybody;
	#endif

	#if ((defined CONCENTRATION) || (defined BANDES && defined CONCENTRATION))
		uniform float sneakSmooth;
	#endif

	#ifdef BURNING_EFFECT
		uniform float burningSmooth;
	#endif

	uniform float rainStrength;
	uniform float rainFactor;

	uniform float biomeHasNoRain;
	uniform float biomeHasNoSnow;

	#if (defined DESERT_REFRACT && defined OVERWORLD)
		uniform float biomeHasHeatDesert;
	#endif

	#if (defined MESA_REFRACT && defined OVERWORLD)
		uniform float biomeHasHeatMesa;
	#endif

	#if (defined NETHER_REFRACT && defined NETHER)
		uniform float biomeHasNoHeatValley;
	#endif

	#if (defined ARC_EN_CIEL && defined OVERWORLD)

		uniform mat4 gbufferProjectionInverse;
		uniform sampler2D depthtex0;
		uniform float wetness;

		#ifdef UNDERGROUND_SKY
			uniform float isEyeInCave;
		#endif

		uniform vec3 sunPosition;
		uniform vec3 cameraPosition;
		vec3 sunPosNorm=normalize(sunPosition);

		#ifdef FIXED_RAINBOW
			uniform mat4 gbufferModelView, gbufferModelViewInverse;
		#endif

	#endif

	#ifdef BARREL
		uniform mat4 gbufferProjection;
	#endif

	#if defined VISEUR
		uniform int heldItemId;
	#endif

	#ifdef COLOR_START
		uniform float starter;
	#endif

	uniform ivec2 eyeBrightnessSmooth;
	uniform ivec2 eyeBrightness;

	uniform int isEyeInWater;

	//Optifine Constants//
	/*
	const int colortex0Format   =R11F_G11F_B10F;  //main scene
	const int colortex1Format   =RGB8;            //raw translucent, bloom, final scene, fresnel
	const int colortex2Format   =RGBA16;          //temporal data
	const int colortex3Format   =RGB8;            //specular data
	const int gaux1Format       =R8;              //cloud alpha
	const int gaux2Format       =RGBA16;          //reflection image
	const int gaux3Format       =RG16_SNORM;      //normals
	const int gaux4Format       =R8;              //noTAA
	const int colortex14Format  =RGBA16;          //Refraction
	*/

/*///////////////////////////////////////////////////////////////////////////////////////////
////CONSTANTES//////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////*/

    const bool colortex0Clear     = true;  //gcolor
    const bool colortex1Clear     = true;  //gdepth
    const bool colortex2Clear     = false; //gnormal
    const bool colortex3Clear     = true;  //composite
    const bool gaux1Clear         = true;  //gaux1
    const bool gaux2Clear         = false; //gaux2
    const bool gaux3Clear         = false; //gaux3
    const bool gaux4Clear         = true;  //gaux4
    const bool colortex8Clear     = true;  //mask

    const float ambientOcclusionLevel  = 0.7; //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
    const float centerDepthHalflife    = 2.0; //[0.0 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0 2.2 2.4 2.6 2.8 3.0 3.2 3.4 3.6 3.8 4.0]
    const float shadowDistanceRenderMul= 1.0;
    const float entityShadowDistanceMul= 0.125;
    const float wetnessHalflife        = 500.0; //[100.0 200.0 300.0 400.0 500.0 600.0 700.0 800.0 900.0 1000.0]
    const float drynessHalflife        = 50.0; //[50.0 100.0 125.0 150.0 175.0 200.0 225.0 250.0 275.0 300.0]
    const int noiseTextureResolution   = 128;

	//Common Functions//
	float eBS               = eyeBrightnessSmooth.y / 240.0;
	float eBS2              = clamp01((eyeBrightnessSmooth.y - 220) * 0.0666);
	float sunVisibility     = clamp00125(dot( sunVec,upVec) + 0.0625) * 8.0;
	float screenBrightness2 = clamp01(screenBrightness);

	#ifdef BARREL
		vec2 distortBarrel(vec2 coord, float strength) {
			coord -= vec2(0.5);
			coord *= 1.0 - strength * dot(coord, coord);
			return coord + vec2(0.5);
		}
	#endif

	//Includes//

	#if (defined ARC_EN_CIEL && defined OVERWORLD)
	#include "/lib/color/dimensionColor.glsl"
	#endif

	#ifdef DITHERING_SCREEN
	#include "/lib/util/lexClosest.glsl"
	#endif

	/*///////////////////////////////////////////////////////////////////////////
	////////////////////////////UNDERWATER_REFRACT//////////////////////////////
	/////////////////////////////////////////////////////////////////////////*/

	vec2 underwaterRefraction(vec2 coord) {

	if (isEyeInWater > 0 && isEyeInWater < 3) {

		#ifdef MOUVEMENT_EAU
			const float refractionMultiplier = RMULTIPLIER;
			const float refractionSpeed = RSPEED;

			vec2 refractCoord = vec2(sin(frameTimeCounter * refractionSpeed + coord.x * 20.0 + coord.y * 17.5), 0.0);

			return bool(float(isEyeInWater) > 0.9) ? coord + refractCoord * refractionMultiplier : coord;
		#endif
	}

	return coord;
}

	/*///////////////////////////////////////////////////////////////////////////
	//////////////////////////////RAIN_DROPS////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////*/

	#include "/lib/atmospherics/raindrop.glsl"

	/*///////////////////////////////////////////////////////////////////////////
	//////////////////////////////BIOMES & BURNING REFACT///////////////////////
	/////////////////////////////////////////////////////////////////////////*/

	#include "/lib/others/refraction.glsl"

	/*///////////////////////////////////////////////////////////////////////////
	//////////////////////////////BLINDNESS_EFFECT//////////////////////////////
	/////////////////////////////////////////////////////////////////////////*/

	vec3 blindnessEffect(vec3 clr) {

	const float blindnessAmount = 0.9;

	float dist = min(pow(distance(texCoord.xy, vec2(0.5)), 1.4) * 1.4, 1.0);

	return mix(clr, vec3(0.0), blindness * dist);

	}

	/*///////////////////////////////////////////////////////////////////////
	///////////////////////////////////SCANLINE_BAND////////////////////////
	/////////////////////////////////////////////////////////////////////*/

	#ifdef SCANLINE_BAND
		float sinEsp(float a, float esp) {

			float cycle = mod(a / TAU, esp);
			if (cycle <= 0.5) {
				return sin(a);
			} else {
				return 0.0;
			}

		}
	#endif

	/*///////////////////////////////////////////////////////////////////////
	////////////////////////////////////Tube Border/////////////////////////
	/////////////////////////////////////////////////////////////////////*/

	#ifdef CRT_BORDER

		float tubeBorder(float crtBorder) {
			vec2 a = texCoord.xy * (1.0 - texCoord.xy) * (crtBorder + texCoord.xy);
			return mix(2.0 - pow(a.x * a.y, 0.25), 1.0, 0.9);
		}

		void calculateBorder(inout vec3 color) {
			float crtStrength = 0.0;

			#if CRT_BORDER_STRENGTH==1
			crtStrength = 75.0;
			#elif CRT_BORDER_STRENGTH==2
			crtStrength = 55.0;
			#elif CRT_BORDER_STRENGTH==3
			crtStrength = 35.0;
			#elif CRT_BORDER_STRENGTH==4
			crtStrength = 25.0;
			#endif

			color *= smoothstep(1.0, 0.95, tubeBorder(crtStrength));
		}
	#endif

	/*////////////////////////////////////////////////////////////////////////
	/////////////////////////////////VISEUR//////////////////////////////////
	//////////////////////////////////////////////////////////////////////*/

	#ifdef VISEUR

		void aim(inout vec4 color) {

		if (abs(texCoord.s - 0.4875) < 0.0005 && abs(texCoord.t - 0.45) < 0.1)
			color = vec4(1.0) - color;
		if (abs(texCoord.s - 0.5125) < 0.0005 && abs(texCoord.t - 0.45) < 0.1)
			color = vec4(1.0) - color;
		if (abs(texCoord.t - 0.45) < 0.0008 && abs(texCoord.s - 0.5) < 0.0075)
			color = vec4(1.0) - color;
		if (abs(texCoord.t - 0.4) < 0.0008 && abs(texCoord.s - 0.5) < 0.005)
			color = vec4(1.0) - color;
		if (abs(texCoord.t - 0.35) < 0.0008 && abs(texCoord.s - 0.5) < 0.0025)
			color = vec4(1.0) - color;
		if (abs(texCoord.t - 0.3) < 0.0008 && abs(texCoord.s - 0.5) < 0.001)
			color = vec4(1.0) - color;
		}
	#endif

	/*////////////////////////////////////////////////////////////////////////
	//////////////////////////ULTRA_VIGNETTE/////////////////////////////////
	//////////////////////////////////////////////////////////////////////*/

	#ifdef ULTRA_VIGNETTE
		void ultraVignette(inout vec4 vignColor) {
			vec2 uv = texCoord.xy;

			vec2 curve = pow(abs(uv * 2.0 - 1.0), vec2(1.0 / VIGNETTE_CURVATURE));

			float edge = pow(length(curve), VIGNETTE_CURVATURE);

			float vignette = 1.0 - VIGNETTE_STRENGTH * smoothstep(VIGNETTE_INNER, VIGNETTE_OUTER, edge);

			vignColor *= vignette;
		}
	#endif

	#if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)

		#if SCREEN_DIMMING == 1
			float screenDimming = 1.0;

		#elif SCREEN_DIMMING == 2
			float screenDimming = 1.5;

		#elif SCREEN_DIMMING == 3
			float screenDimming = 2.0;
		#endif

	void ColorDarknessBeat(inout vec4 ColorDarkness) {
		ColorDarkness *= (1.0 - darknessLightFactor * screenDimming);
	}
	#endif

	/*////////////////////////////////////////////////////////////////////////
	//////////////////////////////////DAMAGE/////////////////////////////////
	//////////////////////////////////////////////////////////////////////*/

	#ifdef HIT_RED_VIGNETTE
		vec3 damage_visual(vec3 color) {

			return color + (vec3(1.0, 0.0, 0.0) * pow(distance(texCoord.xy, vec2(0.5)), 2.0) * touchmybody);

		}
	#endif

	/*/////////////////////////////////////////////////////////////////////
	/////////////////////////////////MAIN/////////////////////////////////
	///////////////////////////////////////////////////////////////////*/


	//Program//
	void main(){

		vec2 newtex=texCoord.xy;

		#if (defined ARC_EN_CIEL && defined OVERWORLD)
		float sunDot = 0.0;
		#endif

		#if (defined BANDES || defined CONCENTRATION)
		float bottom = 0.0;
		float top = 0.0;
		float bottomplus = 0.0;
		float topplus = 0.0;
		#endif

		#ifdef COLOR_START
		float animate = 0.0;
		#endif

		#if (defined DITHERING_SCREEN || defined DOWNSCALE)
			vec2 baseRes = vec2(viewWidth, viewHeight);
			vec2 scaleBaseRes = baseRes * RESOLUTION_SCALE;
		#endif

		#if defined DISTORTION
			vec3 distort=dot(vUVDot, vUVDot)*vec3(-0.5, -0.5, -1.0)+vUV;
			     newtex =distort.xy/distort.z;
		#endif

		vec2 newtexcoord=raindropRefraction(underwaterRefraction(newtex));
		     newtexcoord=biomeRefraction(newtexcoord);

		vec4 color = textureLod(colortex1, newtexcoord, 0).rgba;

		#if (defined DITHERING_SCREEN || defined DOWNSCALE)
			vec2 downscale=floor(newtexcoord * (scaleBaseRes - 1) + 0.5) / (scaleBaseRes - 1);
		#endif

		/*////////////////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////////////DOWNSCALE///////////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////*/

		#ifdef DOWNSCALE
			color = textureLod(colortex1, downscale, 0).rgba;
		#endif

		#if CHROMATIC_ABERRATION == 2 && defined DOF_IS_ON
			float caStrength =0.005 * CHROMA_STRENGTH;
			vec2 caScale = vec2(1.0 / aspectRatio, 1.0);
			color *= vec4(0.0,1.0,0.0,1.0);
			color += textureLod(colortex1, mix(newtexcoord, vec2(0.5), caScale * -caStrength), 0).rgba * vec4(1.0,0.0,0.0,1.0);
			color += textureLod(colortex1, mix(newtexcoord, vec2(0.5), caScale * -caStrength * 0.5), 0).rgba * vec4(0.5,0.5,0.0,1.0);
			color += textureLod(colortex1, mix(newtexcoord, vec2(0.5), caScale * caStrength * 0.5), 0).rgba * vec4(0.0,0.5,0.5,1.0);
			color += textureLod(colortex1, mix(newtexcoord, vec2(0.5), caScale * caStrength), 0).rgba * vec4(0.0,0.0,1.0,1.0);

			color /= vec4(1.5, 2.0, 1.5, 1.0);
		#endif

		/*/////////////////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////MAIN_ULTRA_VIGNETTE//////////////////////////////////////////////
		///////////////////////////////////////////////////////////////////////////////////////////////*/

		#ifdef ULTRA_VIGNETTE
			ultraVignette(color.rgba);
		#endif

		#if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
			ColorDarknessBeat(color.rgba);
		#endif

		/*////////////////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////////BLINDNESS_EFFECT////////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////*/

		color.rgb = blindnessEffect(color.rgb);

		/*////////////////////////////////////////////////////////////////////////////////////////////////
		////////////////////////////////MAIN_DITHERING_SCREEN//////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////*/

		#ifdef DITHERING_SCREEN
			color.rgb = lexClosest(color.rgb, vec2(downscale.x, downscale.y / aspectRatio) * scaleBaseRes.x, DITHERING_SAMPLES);
		#endif

		/*////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////MAIN_POSTERIZATION////////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////*/

		#ifdef POSTERIZATION
			color.rgb = pow(color.rgb, vec3(1.0 / 2.2));

			if (length(color.rgb) < 0.5)
				color.rgb = floor(normalize(color.rgb) * POSTERIZATION_LIMIT * 2.0) / POSTERIZATION_LIMIT / 2.0 * floor(length(color.rgb * POSTERIZATION_LIMIT)) / POSTERIZATION_LIMIT;
			if (length(color.rgb) > 0.5)
				color.rgb = ceil(normalize(color.rgb) * POSTERIZATION_LIMIT * 2.0) / POSTERIZATION_LIMIT / 2.0 * ceil(length(color.rgb * POSTERIZATION_LIMIT)) / POSTERIZATION_LIMIT;
				color.rgb = pow(color.rgb, vec3(2.2));

		#endif

		/*////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////MAIN_ARC_EN_CIEL//////////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////*/

		#if (defined ARC_EN_CIEL && defined OVERWORLD)
			vec4 fragposition = gbufferProjectionInverse * (vec4(newtex.xy, texture2D(depthtex0, newtex.xy).x, 1.0) * 2.0 - 1.0);
			fragposition /= fragposition.w;

			#ifndef FIXED_RAINBOW
				sunDot = dot(sunPosNorm, normalize(fragposition.xyz)) * 0.5 + 0.5;
			#else
				vec3 newSunPosView = (gbufferModelViewInverse * vec4(sunPosNorm, 0.0)).xyz * vec3(100.0, 0.01, 100.0);
				newSunPosView.y += FIXED_RAINBOW_POS;
				vec3 newSunPosWorld = (gbufferModelView * vec4(newSunPosView, 0.0)).xyz;
				sunDot = dot(normalize(newSunPosWorld), normalize(fragposition.xyz)) * 0.50 + 0.50;
			#endif

			float fragpositionLength = length(fragposition.xyz);
			if (fragpositionLength > DISTANCE_ARC_EN_CIEL && isEyeInWater == 0 && worldTime > 1000.0 && worldTime < 12000.0) {
				float rainbowStrength = (wetness - rainFactor) * 0.015 * RAINBOW_INTENSITY;
				float rainbowHue = (sunDot - 0.05 * DIAMETRE_ARC_EN_CIEL) * -50.0 / EPAISSEUR_ARC_EN_CIEL;

				if (rainbowStrength > 0.01 && rainbowHue > 0.0 && rainbowHue < 1.0) {
					rainbowHue *= 6.0;
					vec3 rainbowColor = vec3(0.0);

					rainbowColor.r = clamp(1.5 - abs(rainbowHue - 1.5), 0.0, 1.0) * rainbowStrength;
					rainbowColor.g = clamp(2.0 - abs(rainbowHue - 3.0), 0.0, 1.0) * rainbowStrength;
					rainbowColor.b = clamp(1.5 - abs(rainbowHue - 4.5), 0.0, 1.0) * rainbowStrength;

					#if MC_VERSION >= 11800
						rainbowColor.rgb *= clamp01((cameraPosition.y + 70.0) * 0.125);
					#else
						rainbowColor.rgb *= clamp01((cameraPosition.y + 6.0) * 0.125);
					#endif

					#if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
						rainbowColor.rgb *= 1.0 - darknessFactor;
					#endif

					#ifdef UNDERGROUND_SKY
						rainbowColor.rgb *= 1.0 - isEyeInCave;
					#endif

					color.rgb += rainbowColor.rgb;
				}
			}
		#endif

		/*////////////////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////////////MAIN_DAMAGE/////////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////*/

		#ifdef HIT_RED_VIGNETTE
			color.rgb = damage_visual(color.rgb);
		#endif

		/*////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////MAIN_SCANLINE/////////////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////*/

		#if (defined SCANLINE || defined SCANLINE_BAND)
			float scanline        =0.0;
		#endif

		#ifdef CRT
		float scanlineY=0.0;
		float scanlineX=0.0;

			scanlineY = sin(newtex.y * viewHeight * 2.0 / EPAISSEUR_CRT);
			scanlineX = sin(newtex.x * viewWidth * 2.0 / EPAISSEUR_CRT);
			color.rgb *= 1.0 + scanlineY * FORCE_CRT * 0.1 + scanlineX * FORCE_CRT * 0.1;
		#endif

		#ifdef SCANLINE
			scanline  =sin(newtex.y * viewHeight * 2.0 / EPAISSEUR_SCANLINE + frameTimeCounter * VITESSE_SCANLINE);
			color.rgb*=1.0 + scanline * FORCE_SCANLINE * 0.1;
		#endif

		#ifdef SCANLINE_BAND
			scanline  =sinEsp(newtex.y * viewHeight * 2.0 / EPAISSEUR_BAND + frameTimeCounter * VITESSE_BAND,INTERVAL_BAND);
			color.rgb/=1.0 + scanline * FORCE_BAND * 0.5;
		#endif

		/*////////////////////////////////////////////////////////////////////////////////////////////////
		//////////////////////////////////////MAIN_CRT_BORDER////////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////*/

		#ifdef CRT_BORDER
			calculateBorder(color.rgb);
		#endif

		/*////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////MAIN_VISEUR///////////////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////*/

		#ifdef VISEUR
			if(heldItemId == 10261 || heldItemId == 10262 || heldItemId == 10344 || heldItemId == 10332 || heldItemId == 19999)aim(color.rgba);
		#endif

		/*////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////MAIN BANDES & CONCENTRATION///////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////*/

		#if (defined BANDES || defined CONCENTRATION)

			#if (defined BANDES || (defined CONCENTRATION && defined BANDES))
				bottom = BOTTOMBAND;
				top = TOPBAND;
			#endif

			#if (defined CONCENTRATION && !defined BANDES)
				bottom = 0.0;
				top = 0.0;
			#endif

			#if (defined CONCENTRATION && defined BANDES)
				bottomplus = mix(bottom, BOTTOMBAND + BAND_ADDITION, sneakSmooth);
				topplus = mix(top, TOPBAND + BAND_ADDITION, sneakSmooth);
			#endif

			#if (defined CONCENTRATION && !defined BANDES)
				bottomplus = mix(bottom, CONCENTRATION_BAND, sneakSmooth);
				topplus = mix(top, CONCENTRATION_BAND, sneakSmooth);
			#endif

			#if (!defined CONCENTRATION && defined BANDES)
				bottomplus = bottom;
				topplus = top;
			#endif

			float bottombandfade = clamp01((newtex.t - bottomplus) / 0.003);
			float topbandfade = clamp01((1.0 - newtex.t - topplus) / 0.003);

			if(bottomplus < 0.001) bottombandfade = 1.0;

			if(topplus < 0.001) topbandfade = 1.0;

			color.rgb = mix(vec3(0.0), color.rgb, bottombandfade * topbandfade);

		#endif

		/*////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////MAIN BARREL///////////////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////*/

		#ifdef BARREL
			vec2 barrelTex = texCoord;
				 barrelTex = distortBarrel(barrelTex, -0.2 * 0.5);

			float bottombandfade2 = clamp01((barrelTex.y) * 333.33);
			float topbandfade2 = clamp01((1.0 - barrelTex.y) * 333.33);

			float leftbandfade2 = clamp01((barrelTex.x) * 333.33);
			float rightbandfade2 = clamp01((1.0 - barrelTex.x) * 333.33);

			color.rgb = mix(vec3(0.0), color.rgb, bottombandfade2 * topbandfade2 * leftbandfade2 * rightbandfade2);

		#endif

		/*////////////////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////////////BW_START////////////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////*/

		#ifdef COLOR_START
		#include "/lib/color/starterColor.glsl"

			#ifdef ANIM_MOVE
			animate = min(starter, 0.1) * 10.0;
			#endif

			vec3 start = vec3(starterColor.rgb);
			color.rgb = mix(start, color.rgb, animate);
		#endif

		/*////////////////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////////////END_MAIN///////////////////////////////////////////////
		///////////////////////////////////////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////////////////*/


		/* RENDERTARGETS: 1 */
		gl_FragData[0] = vec4(color);
	}

#endif