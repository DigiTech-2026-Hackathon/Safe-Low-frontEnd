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

	//Program//
	void main(){
		texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

		gl_Position=ftransform();
	}

#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

	//Uniforms//
	uniform float viewWidth, viewHeight, aspectRatio;
	uniform float frameTime;

	uniform int frameCounter;

	uniform vec3 cameraPosition, previousCameraPosition;

	uniform mat4 gbufferPreviousProjection, gbufferProjectionInverse;
	uniform mat4 gbufferPreviousModelView, gbufferModelViewInverse;

	uniform sampler2D colortex0;

	#if PLAYER_MOTION_BLUR == 0
		uniform sampler2D colortex8;
	#endif

	uniform sampler2D depthtex1;
	uniform sampler2D depthtex0;
	uniform sampler2D noisetex;

	//Common Functions//
	float BlueNoise(vec2 coord) {
    	return texelFetch(noisetex, ivec2(coord)% 64, 0).b;
	}

	vec3 MotionBlur(vec3 color, float z, float dither) {
		float z0 = texelFetch(depthtex0, texelCoord, 0).x;
		float hand = float(z0 < 0.56);

		#if PLAYER_MOTION_BLUR == 0
			bool player = bool(texelFetch(colortex8, texelCoord, 0).g > 0.5);
		#endif

		#if PLAYER_MOTION_BLUR == 0
		if (hand < 0.5 && !player)
		#else
		if (hand < 0.5)
		#endif
		{
			float mbwg = 0.0;
			vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
			vec3 mblur = vec3(0.0);

			vec4 currentPosition = vec4(texCoord, z, 1.0) * 2.0 - 1.0;

			vec4 viewPos = gbufferProjectionInverse * currentPosition;
			viewPos = gbufferModelViewInverse * viewPos;
			viewPos /= viewPos.w;

			vec3 cameraOffset = cameraPosition - previousCameraPosition;

			vec4 previousPosition = viewPos + vec4(cameraOffset, 0.0);
			previousPosition = gbufferPreviousModelView * previousPosition;
			previousPosition = gbufferPreviousProjection * previousPosition;
			previousPosition /= previousPosition.w;

			vec2 velocityMb = (currentPosition - previousPosition).xy;
			velocityMb = velocityMb / (1.0 + length(velocityMb)) * MOTION_BLUR_STRENGTH * 0.1;

			vec2 coord = texCoord.xy - velocityMb * (1.5 + dither);

			for (int i = 0; i < 9; i++) {
				vec2 sampleCoord = clamp(coord + velocityMb * float(i), texel, 1.0 - texel);

				float mask = float(texelFetch(depthtex0, ivec2(sampleCoord * vec2(viewWidth, viewHeight)), 0).r > 0.56);
				#if PLAYER_MOTION_BLUR == 0
					mask *= float(texelFetch(colortex8, ivec2(sampleCoord * vec2(viewWidth, viewHeight)), 0).g < 0.5);
				#endif

				mblur += texelFetch(colortex0, ivec2(sampleCoord * vec2(viewWidth, viewHeight)), 0).rgb * mask;
				mbwg += mask;
			}
			mblur /= max(mbwg, 1.0);

			return mblur;
		} else {
			return color;
		}
	}

	//Includes//
	#include "/lib/util/dither.glsl"

	#ifdef BLACK_OUTLINE
	#include "/lib/outline/outlineOffset.glsl"
	#include "/lib/outline/outlineDepth.glsl"
	#endif

	//Program//
	void main(){
		vec3 color = texelFetch(colortex0, texelCoord, 0).rgb;

		#ifdef MOTION_BLUR
			float z      = texelFetch(depthtex1, texelCoord, 0).x;

			float dither = Bayer8(gl_FragCoord.xy);

		#ifdef BLACK_OUTLINE
			DepthOutline(z);
		#endif

			color = MotionBlur(color, z, dither);
		#endif

		/* RENDERTARGETS: 0 */
		gl_FragData[0] = vec4(color, 1.0);
	}

#endif