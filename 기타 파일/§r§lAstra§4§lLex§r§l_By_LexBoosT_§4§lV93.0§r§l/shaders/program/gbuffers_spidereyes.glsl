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
varying vec4 color;

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

	//Uniforms//

	uniform mat4 gbufferModelViewInverse;

	#if MOUVEMENT_CAM > 0
	uniform float frameTimeCounter;
	uniform float onGroundSmooth;
	#endif

	//Includes//

	#ifdef WORLD_CURVATURE
	#include "/lib/vertex/worldCurvature.glsl"
	#endif

	//Program//
	void main(){
		texCoord=(gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

		color = gl_Color;

		vec4 position=gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

		#ifdef WORLD_CURVATURE
			position.y -= WorldCurvature(position.xz);
			gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
		#else
			gl_Position = ftransform();
		#endif

		#if MOUVEMENT_CAM > 0
			gl_Position += vec4(0.03 * sin(frameTimeCounter * 3.0 * SPEED_MOOVE), 0.015 * cos(frameTimeCounter * 4.0 * SPEED_MOOVE), 0.0, 0.0) * gl_ProjectionMatrix * onGroundSmooth;
		#endif
	}

#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

	//Uniforms//
	uniform sampler2D texture;
	uniform int entityId;

	//Program//
	void main(){
		vec4 albedo = texture2D(texture, texCoord) * color;

		albedo.rgb = pow(albedo.rgb,vec3(2.2));

		#ifdef WHITE_WORLD
			#ifdef SPIDER_EYESW
				albedo.rgb = vec3(2.0);
			#endif
		#endif

		#ifdef COLORED_EYES
		if (entityId != 18214){
			#if SPIDER_EYES == 1
				albedo.rgb = vec3(1.0, 0.0, 0.0);
			#elif SPIDER_EYES == 2
				albedo.rgb = vec3(0.749, 0.0, 1.0);
			#elif SPIDER_EYES == 3
				albedo.rgb = vec3(0.0, 0.0157, 1.0);
			#elif SPIDER_EYES == 4
				albedo.rgb = vec3(0.0, 0.1333, 0.0235);
			#elif SPIDER_EYES == 5
				albedo.rgb = vec3(1.0, 0.9333, 0.0078);
			#endif
		}
		#endif

		#ifndef COLORED_EYES
			albedo.rgb *= pow2(1.0 + albedo.b + 0.5 * albedo.g) * 1.5;
		#endif

		if (entityId == 18214) albedo.a*=0.8;

		/* RENDERTARGETS: 0 */
		gl_FragData[0] = albedo;

		#ifdef ADVANCED_MATERIALS
			/* RENDERTARGETS: 0,3,6,1 */
			gl_FragData[1]=vec4(0.0, 0.0, 0.0, 1.0);
			gl_FragData[2]=vec4(0.0, 0.0, 0.0, 1.0);
			gl_FragData[3]=vec4(0.0, 0.0, 0.0, 1.0);
		#endif
	}

#endif