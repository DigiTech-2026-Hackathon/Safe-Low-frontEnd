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
    uniform float viewWidth, viewHeight, aspectRatio;

    #if AA > 1
    uniform int frameCounter;
    uniform float far, near;
    #endif

    uniform sampler2D colortex1;

    #if AA > 0
        #if !defined KEEP_AA_ON_WATER
            uniform sampler2D colortex8;
        #endif
    #endif

    #if AA > 1
    uniform vec3 cameraPosition, previousCameraPosition;

    uniform mat4 gbufferPreviousProjection, gbufferProjectionInverse;
    uniform mat4 gbufferPreviousModelView, gbufferModelViewInverse;

    uniform sampler2D colortex2;
    uniform sampler2D colortex7;
    uniform sampler2D depthtex1;
    #endif

    //Optifine Constants//

    const bool colortex1MipmapEnabled = true;

    //Common Functions//

    #if AA > 1
    float GetLinearDepth(float depth) {
        return (2.0 * near) / (far + near - depth * (far - near));
    }
    #endif

    //Includes//

    #if AA == 2
    #ifdef TAA_VERSION_1
    #include "/lib/antialiasing/taa.glsl"
    #endif

    #elif AA == 3
    #ifdef TAA_VERSION_1
    #include "/lib/antialiasing/taa.glsl"
    #endif

    #elif AA == 4
    #ifdef TAA_VERSION_2
    #include "/lib/antialiasing/taa.glsl"
    #endif

    #elif AA == 5
    #ifdef TAA_VERSION_2
    #include "/lib/antialiasing/taa.glsl"
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

        #if (AA == 2 || AA == 3 || AA == 4 || AA == 5)
        vec4 temp = vec4(texelFetch(colortex2, texelCoord, 0).r, 0.0, 0.0, 0.0);
        if (! water) {
            TAA(color, temp);
        }
        #endif

        /* RENDERTARGETS: 1 */
        gl_FragData[0] = vec4(color, 1.0);

        #if AA > 1

        /* RENDERTARGETS: 1,2 */
        gl_FragData[1] = vec4(temp);

        #endif
    }

#endif