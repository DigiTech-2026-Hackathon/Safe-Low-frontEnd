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

	uniform sampler2D colortex0;

	#ifdef DOF_IS_ON
		uniform float viewWidth, viewHeight, aspectRatio;

		#if AA > 1
			uniform int frameCounter;
			uniform float frameTimeCounter;
			uniform sampler2D noisetex;
		#endif

		#ifdef DISTANCE_BLUR
			uniform ivec2 eyeBrightnessSmooth;
		#endif

		#ifdef DOF
			uniform float centerDepthSmooth;
		#endif

		uniform mat4 gbufferProjection;

		uniform sampler2D depthtex1;

		#ifdef DISTANCE_BLUR
			uniform float rainFactor;
		#endif

	//Optifine Constants//

		const bool colortex0MipmapEnabled = true;

	//Common Functions//

		#if AA > 1
			mat2 Rotate(float angle) {
				return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
			}
		#endif

		#ifdef DISTANCE_BLUR
			float eBS = eyeBrightnessSmooth.y / 240.0;
		#endif

		float GetCircleDOF(float z1) {
			float DISTANCE_BLUR_STRENGTH = 0.0;
			float DOF_STRENGTH = 0.0;
			float cocDOF = 0.0;
			float cocDIST = 0.0;

			#if defined (NETHER)
				DISTANCE_BLUR_STRENGTH = NETHER_DISTANCE_BLUR_STRENGTH;
				DOF_STRENGTH = NETHER_DOF_STRENGTH;
			#elif defined (OVERWORLD)
				DISTANCE_BLUR_STRENGTH = OVERWORLD_DISTANCE_BLUR_STRENGTH;
				DOF_STRENGTH = OVERWORLD_DOF_STRENGTH;
			#elif defined (END)
				DISTANCE_BLUR_STRENGTH = END_DISTANCE_BLUR_STRENGTH;
				DOF_STRENGTH = END_DOF_STRENGTH;
			#endif

			#if defined (DOF)
				cocDOF = abs(z1 - centerDepthSmooth) * 1.25;
			#endif

			#if defined (DISTANCE_BLUR)
				cocDIST = abs(z1) * 0.001 * DISTANCE_BLUR_STRENGTH * (1.0 + (rainFactor * eBS * RAIN_BLUR_MULT));
			#endif

			float coc = max(cocDOF, cocDIST);

			float fcoc = coc / (1.0 / DOF_STRENGTH + coc) * gbufferProjection[1][1] * 0.7462686567164179 * 0.05;

			return fcoc;
		}

	//Includes//

		#if AA > 1
			#include "/lib/util/dither.glsl"
		#endif

	//Common Variables//

		const vec2 dofOffsets[18] = vec2[18](
									vec2( 0.0    ,  0.25  ),
									vec2(-0.2165 ,  0.125 ),
									vec2(-0.2165 , -0.125 ),
									vec2( 0      , -0.25  ),
									vec2( 0.2165 , -0.125 ),
									vec2( 0.2165 ,  0.125 ),
									vec2( 0      ,  0.5   ),
									vec2(-0.25   ,  0.433 ),
									vec2(-0.433  ,  0.25  ),
									vec2(-0.5    ,  0     ),
									vec2(-0.433  , -0.25  ),
									vec2(-0.25   , -0.433 ),
									vec2( 0      , -0.5   ),
									vec2( 0.25   , -0.433 ),
									vec2( 0.433  , -0.2   ),
									vec2( 0.5    ,  0     ),
									vec2( 0.433  ,  0.25  ),
									vec2( 0.25   ,  0.433 )
		);

	//Common Functions//

		vec3 DepthOfField(vec3 color, float z1) {

			vec3 dof = vec3(0.0);
			vec3 dofSample = vec3(0.0);

			#if AA > 1
				float noise = InterleavedGradientNoise();
				mat2 rotation = Rotate(noise * TAU);
			#endif

			float coc = GetCircleDOF(z1);

			if (coc < 1.0 / max(viewWidth, viewHeight)) return color;

			float hand = float(z1 < 0.56);
			float totalWeight = 0.0;

			float chromaOffset = CHROMA_STRENGTH * 0.25 * coc;

			if (hand < 0.5){

				for(int i = 0; i < 18; i++) {

					vec2 offset = dofOffsets[i] * coc;

					#if AA > 1
						offset = rotation * offset;
					#endif

						offset /= vec2(aspectRatio, 1.0);

					#if CHROMATIC_ABERRATION == 1
						#if ((defined CHROMATIC_ABERRATION_O && defined OVERWORLD) || (defined CHROMATIC_ABERRATION_N && defined NETHER) || (defined CHROMATIC_ABERRATION_E && defined END))
							dofSample = vec3(textureLod(colortex0, texCoord + offset + vec2(chromaOffset, 0.0), 0).r,
											 textureLod(colortex0, texCoord + offset, 0).g,
											 textureLod(colortex0, texCoord + offset - vec2(chromaOffset, 0.0), 0).b);
						#endif
					#else
						dofSample = textureLod(colortex0, texCoord + offset, 0).rgb;
					#endif

					float dofDepth  = texture2D(depthtex1, texCoord + offset).x;
					float dofCoc    = GetCircleDOF(dofDepth);
					float dofWeight = pow(2.0, -distance(coc, dofCoc) * 360.0);
					totalWeight     += dofWeight;
					dofSample       *= dofWeight;

					dof += dofSample;
				}
				dof /= totalWeight;
			} else {

			dof = color;

			}

			return dof;
		}

	//Includes//

		#ifdef BLACK_OUTLINE
		#include "/lib/outline/outlineOffset.glsl"
		#include "/lib/outline/outlineDepth.glsl"
		#endif

	//Program//
	#endif

	void main(){
		vec3 color = textureLod(colortex0, texCoord, 0).rgb;
		#ifdef DOF_IS_ON
			float z1   = texture2D(depthtex1, texCoord).x;

			#ifdef BLACK_OUTLINE
				DepthOutline(z1);
			#endif

			#if (defined DOF || defined DISTANCE_BLUR || CHROMATIC_ABERRATION == 1)
				color = DepthOfField(color, z1);
			#endif
		#endif

		/* RENDERTARGETS: 0 */
		gl_FragData[0] = vec4(color, 1.0);
	}

#endif