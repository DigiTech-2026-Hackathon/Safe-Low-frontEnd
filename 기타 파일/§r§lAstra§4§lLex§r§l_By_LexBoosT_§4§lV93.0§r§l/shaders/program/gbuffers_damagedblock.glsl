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

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

	//Uniforms//
	#if AA > 1
		uniform int frameCounter;
		uniform float viewWidth,viewHeight;
	#endif

	#if MOUVEMENT_CAM > 0
	uniform float frameTimeCounter;
	uniform float onGroundSmooth;
	#endif
	uniform mat4 gbufferModelViewInverse;

	//Includes//
	#if AA > 1
	#include "/lib/util/jitter.glsl"
	#endif

	#ifdef WORLD_CURVATURE
	#include "/lib/vertex/worldCurvature.glsl"
	#endif

	//Program//
	void main(){
		texCoord=(gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

		#ifdef WORLD_CURVATURE
		vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
			 position.y -= WorldCurvature(position.xz);
			gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
		#else
			gl_Position = ftransform();
		#endif

		#if MOUVEMENT_CAM > 0
			gl_Position += vec4(0.03 * sin(frameTimeCounter * 3.0 * SPEED_MOOVE), 0.015 * cos(frameTimeCounter * 4.0 * SPEED_MOOVE), 0.0, 0.0) * gl_ProjectionMatrix * onGroundSmooth;
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

	//Program//
	void main(){

		vec4 albedo = texture2D(texture, texCoord);
		albedo.rgb = pow(albedo.rgb,vec3(2.2)) * 2.25;

		#ifdef WHITE_WORLD
			#ifdef DAMAGED_BLOCKW
				albedo.a = 0.0;
			#endif
		#endif

		#ifndef RETIRE_TEXTURE_CASSE
			albedo.a = 0.0;
		#endif

		/* RENDERTARGETS: 0 */
		gl_FragData[0] = vec4(albedo);
	}

#endif