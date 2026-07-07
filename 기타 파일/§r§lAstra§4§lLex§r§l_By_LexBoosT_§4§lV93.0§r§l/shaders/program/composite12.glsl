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
    uniform float viewWidth, viewHeight;

    uniform sampler2D colortex1;

    #if AA > 0
        #if !defined KEEP_AA_ON_WATER
            uniform sampler2D colortex8;
        #endif
    #endif

    //Includes//

    #if AA == 1
    #ifdef FXAA_VERSION_1
    #include "/lib/antialiasing/fxaa.glsl"
    #endif

    #elif AA == 3
    #ifdef FXAA_VERSION_2
    #include "/lib/antialiasing/fxaa.glsl"
    #endif

    #elif AA == 4
    #ifdef FXAA_VERSION_2
    #include "/lib/antialiasing/fxaa.glsl"
    #endif
    #endif

    //Program//
    void main() {
        vec3 color = texelFetch(colortex1, texelCoord, 0).rgb;
        bool water = false;

            #if AA > 0
                #if !defined KEEP_AA_ON_WATER
                    water = texelFetch(colortex8, texelCoord, 0).r > 0.5;
                #endif
            #endif

            #if (AA == 1 || AA == 3 || AA == 4)
            if (! water)
            FXAA311(color);
            #endif

            /* RENDERTARGETS: 1 */
        gl_FragData[0] = vec4(color, 1.0);
    }

#endif