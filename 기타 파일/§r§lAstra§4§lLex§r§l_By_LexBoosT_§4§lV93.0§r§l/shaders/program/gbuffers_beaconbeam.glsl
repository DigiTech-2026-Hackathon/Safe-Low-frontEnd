/*#############################################
#    _   ___ _____ ___    _   _    _____  __  #
#   /_\ / __|_   _| _ \  /_\ | |  | __\ \/ /  #
#  / _ \\__ \ | | |   / / _ \| |__| _| >  <   #
# /_/ \_\___/ |_| |_|_\/_/ \_\____|___/_/\_\  #
#											  #
#############################################*/

//Settings//////////////////Settings///////////////////Settings///////////////////Settings//

//#define DEBUG_BEACON_BEAM

#include "/lib/util/functions.glsl"

#include "/settings/globalSettings.glsl"

//Varying////////////////////Varying////////////////////Varying////////////////////Varying//
varying vec2 texCoord;
varying vec4 color;

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

	//Uniforms//
	uniform mat4 gbufferModelViewInverse;

	#if AA > 1
		uniform int frameCounter;
		uniform float viewWidth;
		uniform float viewHeight;
	#endif

	//Includes//
	#if AA > 1
	#include "/lib/util/jitter.glsl"
	#endif

	#ifdef WORLD_CURVATURE
	#include "/lib/vertex/worldCurvature.glsl"
	#endif

	//Program//
	void main(){
		texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

		color=gl_Color;

		#ifdef WORLD_CURVATURE
			vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
			if (gl_ProjectionMatrix[2][2] < -0.5) position.y -= WorldCurvature(position.xz);
			gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
		#else
			gl_Position = ftransform();
		#endif

		#if AA > 1
			gl_Position.xy=TAAJitter(gl_Position.xy, gl_Position.w);
		#endif
	}

#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

	//Uniforms//
	uniform sampler2D texture;
	uniform int frameCounter;
	uniform float viewWidth, viewHeight;
	uniform mat4 gbufferProjectionInverse;
	uniform mat4 gbufferModelViewInverse;
	uniform mat4 shadowModelView;
	uniform mat4 shadowProjection;

	//Includes//
	#include "/lib/color/blocklightColor.glsl"
	#include "/lib/util/spaceConversion.glsl"

	#if AA > 1
		#include "/lib/util/jitter.glsl"
	#endif

	//Program//
	void main(){
		if (!gl_FrontFacing) discard;

		vec4 albedoT = texture2D(texture, texCoord);
		vec4 albedo = albedoT * color;

		vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
		#if AA > 1
			vec3 viewPos = ScreenToView(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
		#else
			vec3 viewPos = ScreenToView(screenPos);
		#endif

		float lViewPos = length(viewPos);

		albedo.rgb = pow(albedo.rgb, vec3(2.2));

		#ifdef WHITE_WORLD
			#ifdef BEACONW
				albedo.rgb = vec3(2.0);
			#endif
		#endif

		#ifdef BLACK_WORLD
			#ifdef BEACONW
				albedo.rgb = vec3(0.0);
			#endif
		#endif

		#ifdef EMISSIVE_BEACON_BEAM
			float emission = 0.0;
			float emissiveBeamMultiplier = 0.0;

			#if defined (OVERWORLD)
				emissiveBeamMultiplier = BEACON_BEAM_EMISSIVE_OVERWORLD;
			#elif defined (NETHER)
				emissiveBeamMultiplier = BEACON_BEAM_EMISSIVE_NETHER;
			#elif defined (END)
				emissiveBeamMultiplier = BEACON_BEAM_EMISSIVE_ENDER;
			#endif

			emission = length(albedoT.rgb);
			emission *= emission;
			emission *= emission;
			if (color.a < 0.5) emission = pow4(emission) * 0.01;
			else emission = emission * 0.1;

			vec3 beaconLighting = albedo.rgb * emission * 8.0 * emissiveBeamMultiplier * 0.25;

			albedo.rgb *= beaconLighting;

		#endif

			albedo.rgb *= 0.5 + 0.5 * exp(- lViewPos * 0.04);

			#if BEACON_BEAM_LAYER == 0

				#ifdef EMISSIVE_BEACON_BEAM
					albedo.a *= albedo.a;
					albedo.a *= albedo.a + 0.05;
				#else
					albedo.a *= albedo.a * 2.0;
				#endif

			#elif BEACON_BEAM_LAYER == 1
				albedo.a *= albedo.a;
				albedo.a *= albedo.a;
				albedo.a *= albedo.a;
			#endif

			#ifndef EMISSIVE_BEACON_BEAM
				albedo.rgb *= albedo.rgb;
			#endif

		/* RENDERTARGETS: 0,3 */
		#ifdef DEBUG_BEACON_BEAM
            gl_FragData[0]=vec4(0.2824, 1.0, 0.0, 0.75);
		#else
			gl_FragData[0] = vec4(Max0(albedo));
		#endif

		#ifdef EMISSIVE_BEACON_BEAM
			gl_FragData[1]=vec4(0.0, 0.0, 0.0, 1.0);
		#endif

		#ifdef ADVANCED_MATERIALS
		/* RENDERTARGETS: 0,3,6,1 */
			#ifndef EMISSIVE_BEACON_BEAM
				gl_FragData[1]=vec4(0.0, 0.0, 0.0, 1.0);
			#endif

			gl_FragData[2]=vec4(0.0, 0.0, float(gl_FragCoord.z<1.0), 1.0);
			gl_FragData[3]=vec4(0.0, 0.0, 0.0, 1.0);
		#endif
	}

#endif