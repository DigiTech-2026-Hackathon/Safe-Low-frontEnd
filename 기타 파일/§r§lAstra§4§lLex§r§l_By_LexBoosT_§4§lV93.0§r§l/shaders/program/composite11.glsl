/*#############################################
#    _   ___ _____ ___    _   _    _____  __  #
#   /_\ / __|_   _| _ \  /_\ | |  | __\ \/ /  #
#  / _ \\__ \ | | |   / / _ \| |__| _| >  <   #
# /_/ \_\___/ |_| |_|_\/_/ \_\____|___/_/\_\  #
#											  #
#############################################*/

//Settings//////////////////Settings///////////////////Settings///////////////////Settings//

#include "/lib/util/functions.glsl"

#include "/settings/globalSettings.glsl"

#include "/settings/color/colorGradingSettings.glsl"

//Varying////////////////////Varying////////////////////Varying////////////////////Varying//
varying vec2 texCoord;
varying vec3 sunVec, upVec, uSunVec;

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

	//Program//
	void main(){
		texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

		gl_Position=ftransform();

        upVec=normalize(gbufferModelView[1].xyz);
		uSunVec = GetuSunVec();
		sunVec = GetSunVec(uSunVec);
	}

#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

	//Uniforms//
	uniform sampler2D colortex0;
    uniform sampler2D colortex2;
    uniform sampler2D depthtex0;
	uniform sampler2D noisetex;

	#ifdef FILM_GRAINS
	uniform float frameTimeCounter;
	#endif

    uniform float viewWidth, viewHeight, aspectRatio;
    uniform float rainFactor;
	uniform float screenBrightness;
	uniform int frameCounter;
    uniform int isEyeInWater;
    uniform int moonPhase;
	#define UNIFORM_MOONPHASE

    #if (defined LENS_FLARE && defined OVERWORLD)
		uniform float blindFactor;
		uniform vec3 sunPosition;
		uniform mat4 gbufferProjection;
	#endif

	#ifdef UNDERGROUND_SKY
	    uniform float isEyeInCave;
	#endif

    #ifdef AUTO_EXPOSURE
		const bool colortex0MipmapEnabled = true;
	#endif

    #if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
		uniform float darknessFactor;
	#endif

    uniform ivec2 eyeBrightnessSmooth;

    //Common Variables//
	float eBS              =eyeBrightnessSmooth.y / 240.0;
	float sunVisibility    =clamp00125(dot( sunVec,upVec) + 0.0625) * 8.0;
	float moonVisibility   =clamp00125(dot( -sunVec,upVec) + 0.0625) * 8.0;
	float screenBrightness2=clamp01(screenBrightness);
	float pw               =1.0 / viewWidth;
	float ph               =1.0 / viewHeight;

	//Common Functions//
	float BlueNoise(vec2 coord) {
    	return texelFetch(noisetex, ivec2(coord)% 64, 0).b;
	}

	#ifdef FILM_GRAINS
		float hash13(vec3 p3){
			p3  = fract(p3 * 443.8975);
			p3 += dot(p3, p3.yzx + 19.19);
			return fract((p3.x + p3.y) * p3.z);
		}

		vec3 applyGrain(vec2 vUV, vec3 col, float amount){
			float h = hash13(vec3(vUV, frameTimeCounter));

			col *= (h * 2.0 - 1.0) * amount + (1.0 -amount);

			return col;
		}
	#endif

    void AutoExposure(inout vec3 color, inout float exposure, float tempExposure) {
	float exposureLod = log2(viewWidth * AUTO_EXPOSURE_RADIUS);

	exposure = length(textureLod(colortex0, vec2(0.5), exposureLod).rgb);
	exposure = max(exposure, 0.0001);

	color /= 2.0 * tempExposure + 0.125;
	}

	void ColorGrading(inout vec3 color) {
	vec3 cgColor = pow(color.r, CG_RC) * pow(vec3(CG_RR, CG_RG, CG_RB) / 255.0, vec3(2.2)) +
				   pow(color.g, CG_GC) * pow(vec3(CG_GR, CG_GG, CG_GB) / 255.0, vec3(2.2)) +
				   pow(color.b, CG_BC) * pow(vec3(CG_BR, CG_BG, CG_BB) / 255.0, vec3(2.2));
	vec3 cgMin = pow(vec3(CG_RM, CG_GM, CG_BM) / 255.0, vec3(2.2));
	color = (cgColor * (1.0 - cgMin) + cgMin) * vec3(CG_RI, CG_GI, CG_BI);

	vec3 cgTint = pow(vec3(CG_TR, CG_TG, CG_TB) / 255.0, vec3(2.2)) * GetLuminance(color) * CG_TI;
	color = mix(color, cgTint, CG_TM);
	}

	void LexTonemap(inout vec3 color) {
    color = mix(color, pow(color, vec3(BLACK_CURVE)), 0.5);
	color = mix(color, vec3(1.0), WHITE_CURVE);
	color = exp(-1.0 / ( 3.22 * color + 0.05));
    vec3 mixFactors = mix(vec3(TONEMAP_UPPER_CURVE), vec3(TONEMAP_LOWER_CURVE), sqrt(color));
    color = pow(color, mixFactors);
	color = pow(color, vec3(1.0 / GAMMA));
	color *= pow(2.0, EXPOSURE);
	}

	void Aces_Approx(inout vec3 color) {
		color = Max0(color);
		color *= 0.6;
		float a = 2.51;
		float b = 0.03;
		float c = 2.43;
		float d = 0.59;
		float e = 0.14;
		color = clamp01((color * (a * color + b)) / (color * (c * color + d) + e));
	}

	void ColorSaturation(inout vec3 color) {
		float grayVibrance = dot(vec3(0.333), color);
		float graySaturation = grayVibrance;

		if (SATURATION < 1.00) {
			graySaturation = GetLuminance(color);
		}

		float mn = min(min(color.r, color.g), color.b);
		float mx = max(max(color.r, color.g), color.b);
		float d = mx - mn;
		float sat = (1.0 - (mx - mn)) * (1.0 - mx) * grayVibrance * 5.0;
		vec3 lightness = vec3((mn + mx) * 0.5);

		color = mix(color, mix(color, lightness, 1.0 - VIBRANCE), sat);
		color = mix(color, lightness, (1.0 - lightness) * (2.0 - VIBRANCE) / 2.0 * abs(VIBRANCE - 1.0));
		color = color * SATURATION - graySaturation * (SATURATION - 1.0);
	}

    #if (defined LENS_FLARE && defined OVERWORLD)
		vec2 GetLightPos(){
			vec4 tpos     =gbufferProjection * vec4(sunPosition, 1.0);
				 tpos.xyz/=tpos.w;
			return tpos.xy / tpos.z * 0.5;
		}
	#endif

	//Includes//
	#include "/lib/util/dither.glsl"

    #if (defined LENS_FLARE && defined OVERWORLD)
        #include "/lib/color/lightColor.glsl"
		#include "/lib/post/lensFlare.glsl"
	#endif

	//Program//
	void main(){
		vec4 color = texelFetch(colortex0, texelCoord, 0);

        #ifdef AUTO_EXPOSURE
			float tempExposure = texture2D(colortex2, vec2(pw, ph)).r;
		#endif

        #if (defined LENS_FLARE && defined OVERWORLD)
			float tempVisibleSun = texture2D(colortex2, vec2(3.0 * pw, ph)).r;
		#endif

        vec3 temporalColor = vec3(0.0);

		#if AA > 1
			temporalColor = texelFetch(colortex2, texelCoord, 0).gba;
		#endif

        #ifdef AUTO_EXPOSURE
			float exposure = 1.0;
			AutoExposure(color.rgb, exposure, tempExposure);
		#endif

        #ifdef COLOR_GRADING
			ColorGrading(color.rgb);
		#endif

		LexTonemap(color.rgb);

		#ifdef ACES
			Aces_Approx(color.rgb);
		#endif

		#if (defined LENS_FLARE && defined OVERWORLD)

			vec2 lightPos = GetLightPos();

			float truePos = sign(sunVec.z);

			float moonPhaseOffsetLensFlare = 1.0;

			#ifdef NEWMOON_DISABLER_STUFF
				moonPhaseOffsetLensFlare = 1.0 - (float((moonPhase == 4)) * (1.0 - sunVisibility));
			#endif

			float visibleSun = float(texture2D(depthtex0, lightPos + 0.5).r >= 1.0);
				  visibleSun *= max(1.0 - isEyeInWater, eBS) * (1.0 - blindFactor) * (1.0 - rainFactor);

			#ifdef UNDERGROUND_SKY
				visibleSun *= 1.0 - isEyeInCave;
			#endif

			#if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
					visibleSun *= 1.0 - darknessFactor;
			#endif

			float multiplier=0.0;

			multiplier = mix(mix(multiplier, tempVisibleSun * LENS_FLARE_STRENGTH_NIGHT * 0.6, 1.0) * moonPhaseOffsetLensFlare,
							 mix(multiplier, tempVisibleSun * LENS_FLARE_STRENGTH_DAY * 0.5, 1.0),
							 sunVisibility);

			if (multiplier > 0.001) LensFlare(color.rgb, lightPos, truePos, multiplier);
		#endif

		float temporalData=0.0;

		#ifdef AUTO_EXPOSURE
			if (texCoord.x < 2.0 * pw && texCoord.y < 2.0 * ph)
				temporalData=mix(tempExposure, sqrt(exposure), AUTO_EXPOSURE_SPEED);
		#endif

		#if (defined LENS_FLARE && defined OVERWORLD)
			if (texCoord.x > 2.0 * pw && texCoord.x < 4.0 * pw && texCoord.y < 2.0 * ph)
				temporalData=mix(tempVisibleSun, visibleSun, 0.1);
		#endif

        color.rgb = pow(color.rgb, vec3(1.0 / 2.2));

		ColorSaturation(color.rgb);

		#ifdef BSL_VIGNETTE
			color.rgb*=1.0 - length(texCoord.xy - 0.5) * FORCE_BSL_VIGNETTE * (1.0 - GetLuminance(color.rgb));
		#endif

		#ifdef FILM_GRAINS
			vec2 uv = vec2(viewWidth, viewHeight);
			vec2 vUV = gl_FragCoord.xy / uv;
			color.rgb = applyGrain(vUV, color.rgb, FORCE_DU_GRAIN);
		#endif

		float dither = BlueNoise(gl_FragCoord.xy);
		#if AA > 0
			  dither = animateDither(dither);
		#endif
		float filmGrain = dither;
		color.rgb += vec3((filmGrain - 0.25) * 0.0078125);

		/* RENDERTARGETS: 1,2*/
		gl_FragData[0] = color;
        gl_FragData[1] = vec4(temporalData, temporalColor);
	}

#endif