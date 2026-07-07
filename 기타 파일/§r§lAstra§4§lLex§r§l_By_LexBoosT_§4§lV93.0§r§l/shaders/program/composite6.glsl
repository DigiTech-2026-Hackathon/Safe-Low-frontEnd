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
    #if (defined FROSTED_LENS && defined OVERWORLD)
        uniform float viewWidth, viewHeight;
    #endif

    #if (defined FROSTED_LENS && defined FROSTED_LENS_DYNAMIC_HAND_LIGHT && defined DYNAMIC_HAND_LIGHT && defined OVERWORLD)
	    uniform int heldItemId, heldItemId2;
        #include "/settings/color/handlightColorSettings.glsl"
        #include "/lib/lighting/colorLighting.glsl"
	#endif

    uniform sampler2D colortex0;
    uniform sampler2D colortex12;

    #if (defined FROSTED_LENS && defined FROSTED_LENS_ONLY_RAIN && defined OVERWORLD)
	    uniform float rainFactor;
    #endif

    #if (defined FROSTED_LENS && defined OVERWORLD)
        uniform float biomeHasSnow;
        uniform ivec2 eyeBrightnessSmooth;
    #endif

    //Common Functions//
    #if (defined FROSTED_LENS && defined OVERWORLD)
        float eBS2 = clamp01((eyeBrightnessSmooth.y - 220) * 0.0666);
    #endif

    #if (defined FROSTED_LENS && defined OVERWORLD)

        float rand(vec2 uvFL) {

        uvFL = floor(uvFL * pow(10.0, 2.5)) / pow(10.0, 2.5);

        float a = dot(uvFL, vec2(92.0, 80.0));
        float b = dot(uvFL, vec2(41.0, 62.0));

        float x = sin(a) + cos(b) * 51.0;
        return fract(x);
        }

        void GetFrostedLens(out vec4 FrozenLensCol){

            	vec4 handLightColFL = vec4(0.5255, 0.5255, 0.5255, 0.5);

				#if defined FROSTED_LENS_DYNAMIC_HAND_LIGHT && defined DYNAMIC_HAND_LIGHT
                    if (isLightHandled()){

					#ifdef COLORED_DYNAMIC_HAND_LIGHT
                        changeLightingColorByHand(handLightColFL.rgb);
                        handLightColFL.a = 1.0;
					#endif
				}
				#endif


                float frozenVisibility = eBS2;
                      frozenVisibility *= biomeHasSnow;

                #ifdef FROSTED_LENS_ONLY_RAIN
                      frozenVisibility *= rainFactor;
                #endif

                if (frozenVisibility < 0.1)
                frozenVisibility = 0.0;
                {
                vec4 frost = vec4(0.0);

                //Noise
                vec2 uvFL=gl_FragCoord.xy / vec2(viewWidth, viewHeight);

                frost = texture2D(colortex12, uvFL) * frozenVisibility;

                vec2 rnd = vec2(rand(uvFL + frost.r * 0.5), rand(uvFL + frost.b * 0.5));

                //Vignette
                vec2 lens = vec2(0.5 * 7.5, 0.05);
                float dist = distance(uvFL.xy, vec2(0.5, 0.5));
                float vignette = pow(1.0 - smoothstep(lens.x, lens.y, dist), 3.0);

                //Rendu Final
                rnd *= frost.rg * vignette * FROSTYNESS;
                rnd *= 1.0 - floor(vignette);

                uvFL += rnd;

                //Coloration Vignette
                FrozenLensCol = mix(texture2D(colortex0, uvFL), handLightColFL, COLORIZE * vec4(rnd.r));
                }
        }
    #endif

    //Program//
    void main(){

        vec4 color = texture2D(colortex0, texCoord);

        #if (defined FROSTED_LENS && defined OVERWORLD)
        GetFrostedLens(color);
        #endif

        /* RENDERTARGETS: 0 */
        gl_FragData[0] = vec4(color);

    }

#endif