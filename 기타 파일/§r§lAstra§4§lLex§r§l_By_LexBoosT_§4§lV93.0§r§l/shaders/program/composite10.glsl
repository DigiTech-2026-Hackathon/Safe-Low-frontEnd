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
void main() {
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    gl_Position = ftransform();
}

#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

    //Uniforms//
    #ifdef HYPER_SPEED
        #ifdef ONLY_SPRINT
            uniform float sprintingSmooth;
        #endif
    uniform float effectStrength;
    uniform sampler2D depthtex1;
    uniform sampler2D noisetex;
    uniform int frameCounter;
    #include "/lib/util/dither.glsl"
    #endif

    uniform sampler2D colortex0;

    //Program//
    void main() {

        vec4 color = textureLod(colortex0, texCoord, 0);

        #ifdef HYPER_SPEED
            #ifndef ONLY_SPRINT
            float sprintingSmooth = 1.0;
            #endif

            float z = texelFetch(depthtex1, texelCoord, 0).x;
            float hand = float(z < 0.56);

            float dither = textureLod(colortex0, texCoord.xy * 0.0625, 0).r;

            if (hand < 0.5) {

                for (int i = 0; i < 16; i ++) {
                    float f = float(i) + dither;
                    float weight = 1.0 - abs(f * 0.125 - 1.0);
                    vec3 hyperSpeedSample = textureLod(colortex0, mix(texCoord, vec2(0.5), f * 0.03125 * sprintingSmooth * effectStrength * HYPERSPEED_MULTIPLIER), 0).rgb;
                    color.rgb += pow2(hyperSpeedSample) * weight;
                    color.a += weight;
                }

                color.rgb *= (effectStrength + 1.0);
                color.rgb = color.rgb;
                } else {
                    color = texelFetch(colortex0, texelCoord, 0);
                }

        #endif

        /* RENDERTARGETS: 0 */
        gl_FragData[0] = vec4(color);
    }

#endif