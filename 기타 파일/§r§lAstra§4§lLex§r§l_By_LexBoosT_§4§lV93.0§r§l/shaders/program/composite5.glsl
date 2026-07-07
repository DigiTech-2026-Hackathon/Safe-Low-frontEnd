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
	uniform sampler2D colortex1;
	uniform sampler2D depthtex0;

	uniform int isEyeInWater;
	uniform int moonPhase;
	#define UNIFORM_MOONPHASE


	uniform float viewWidth, viewHeight, aspectRatio;
	uniform float far;

	uniform mat4 gbufferProjectionInverse;

	#ifdef DIRTY_LENS
		uniform sampler2D depthtex2;
	#endif

	#if (defined COLOR_START || defined BLOOM_START)
		uniform float starter;
	#endif

	#if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
		uniform float darknessFactor;
	#endif

	//Common Functions//

	vec3 GetBloomTile(float lod, vec2 coord, vec2 offset) {
	float scale = exp2(lod);
	float resScale = 1.25 * min(360.0, viewHeight) / viewHeight;
	vec3 bloom = texture2D(colortex1, (coord / scale + offset) * resScale).rgb;
	bloom *= bloom; bloom *= bloom * 32.0;
	return bloom;
	}

	void Bloom(inout vec3 color, vec2 coord, float lViewPos){

				vec3 blur = vec3(0.0);

				float bloomStrength = 0.0;

				vec2 view = vec2(1.0 / viewWidth, 1.0 / viewHeight);
				vec3 blur1 = GetBloomTile(1.0, coord, vec2(0.0      , 0.0   ) + vec2( 0.5, 0.0) * view);
				vec3 blur2 = GetBloomTile(2.0, coord, vec2(0.50     , 0.0   ) + vec2( 4.5, 0.0) * view);
				vec3 blur3 = GetBloomTile(3.0, coord, vec2(0.50     , 0.25  ) + vec2( 4.5, 4.0) * view);
				vec3 blur4 = GetBloomTile(4.0, coord, vec2(0.625    , 0.25  ) + vec2( 8.5, 4.0) * view);
				vec3 blur5 = GetBloomTile(5.0, coord, vec2(0.6875   , 0.25  ) + vec2(12.5, 4.0) * view);
				vec3 blur6 = GetBloomTile(6.0, coord, vec2(0.625    , 0.3125) + vec2( 8.5, 8.0) * view);
				vec3 blur7 = GetBloomTile(7.0, coord, vec2(0.640625 , 0.3125) + vec2(12.5, 8.0) * view);

			#ifdef DIRTY_LENS

				float newAspectRatio =1.777777777777778 / aspectRatio;
				vec2  scale          =vec2(max(newAspectRatio, 1.0), max(1.0 / newAspectRatio, 1.0));
				float dirt           =texture2D(depthtex2, (coord - 0.5) / scale + 0.5).r;
				      dirt          *=length(blur6 / (1.0 + blur6)) * DIRTY_LENS_STRENGTH;
				      blur3 *= dirt *  2.0 + 1.0;
					  blur4 *= dirt *  4.0 + 1.0;
					  blur5 *= dirt *  8.0 + 1.0;
					  blur6 *= dirt * 16.0 + 1.0;
					  blur7 *= dirt * 32.0 + 1.0;
			#endif

			#if BLOOM_RADIUS == 1
				blur = blur1 * 0.667;
			#elif BLOOM_RADIUS == 2
				blur = (blur1 + blur2) * 0.37;
			#elif BLOOM_RADIUS == 3
				 blur = (blur1 + blur2 + blur3) * 0.27;
			#elif BLOOM_RADIUS == 4
				blur = (blur1 + blur2 + blur3 + blur4) * 0.212;
			#elif BLOOM_RADIUS == 5
				blur = (blur1 + blur2 + blur3 + blur4 + blur5) * 0.175;
			#elif BLOOM_RADIUS == 6
				blur = (blur1 + blur2 + blur3 + blur4 + blur5 + blur6) * 0.151;
			#elif BLOOM_RADIUS == 7
				blur = (blur1 + blur2 + blur3 + blur4 + blur5 + blur6 + blur7) * 0.137;
			#endif

			vec3 dirtblur = (blur1 + blur2 + blur3 + blur4 + blur5 + blur6 + blur7) * 0.137;

		#ifndef DIRTY_LENS
			blur = mix(blur, dirtblur, 0.0);
		#else
			blur = mix(blur, dirtblur, dirt);
		#endif

		#ifdef BLOOM
				bloomStrength = BLOOM_MULTIPLIER;

			#if defined (OVERWORLD)
				bloomStrength *= OVERWORLD_BLOOM_STRENGTH;
			#elif defined (NETHER)
				bloomStrength *= NETHER_BLOOM_STRENGTH;
				float netherBloom = lViewPos / max(far, 160.0);
					  netherBloom *= netherBloom;
					  netherBloom *= netherBloom;
					  netherBloom = 1.0 - exp(-8.0 * netherBloom);
				bloomStrength = mix(bloomStrength, bloomStrength, netherBloom);
			#elif defined (END)
				bloomStrength *= END_BLOOM_STRENGTH;
			#endif

		#endif

		#if (defined BLOCK_BLOCK_LIGHT_JITTER && defined BLOOM_JITTER && defined BLOOM)

			const float speed = JITTER_SPEED * 0.5;
				  float t = frameTimeCounter * 1.4 * speed;
				  float jitter1 = 1.0 - sin(t + cos(t * 2.0) - sin(t * 3.0)) * JITTER_STRENGTH1;
				  float jitter2 = 1.0 - sin(t + cos(t * 0.5) - sin(t * 2.25)) * JITTER_STRENGTH2;
				  float jitter3 = 1.0 - sin(t + cos(t * 0.25) - sin(t * 1.25)) * JITTER_STRENGTH3;
			bloomStrength *= jitter1 * jitter2 * jitter3;
		#endif

		#if (defined ENABLE_DARKNESS_EFFECT && MC_VERSION >= 11900)
			bloomStrength = mix(bloomStrength, WARDEN_BLOOM_MULTIPLIER, darknessFactor);
		#endif

		#if (defined BLOOM_START && defined BLOOM)
			float animate = 0.0;

			#ifdef ANIM_MOVE
				animate = min(starter, 0.1) * 10.0;
			#endif

			bloomStrength *= BLOOM_S_STRENGTH;
			bloomStrength = mix(min(bloomStrength, 5.0), 1.0, animate);

		#endif

		#if (defined UNDERWATER_BLUR_BASED_BLOOM && defined BLOOM)
			float underwaterBloomStrength = UNDERWATER_BLUR_BASED_B_BLOOM_STRENGTH;
			float underwaterBlurStrength  = UNDERWATER_BLUR_BASED_B_BLUR_STRENGTH;

			if (isEyeInWater == 1) 	color = mix(color, blur, underwaterBlurStrength) * underwaterBloomStrength;
		#endif

		#if (defined END_CRITICAL_BLUR && defined END)
			float worldBlurStrength  = END_CRITICAL_BLUR_STRENGTH;

			color = mix(color, blur, worldBlurStrength);
		#endif

		if (isEyeInWater == 3) 	color = mix(color, blur, 0.5 * bloomStrength);

		color = mix(color, blur, 0.2 * bloomStrength);
	}

	//Program//
	void main(){
		vec4 color = texelFetch(colortex0, texelCoord, 0);

		float z0 = texture2D(depthtex0, texCoord).r;

		vec4 screenPos = vec4(texCoord, z0, 1.0);
		vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
		viewPos /= viewPos.w;
		float lViewPos = length(viewPos.xyz);

		#ifdef BLOOM
			Bloom(color.rgb, texCoord, lViewPos);
		#endif

		/* RENDERTARGETS: 0 */
		gl_FragData[0] = clamp01(color);
	}

#endif