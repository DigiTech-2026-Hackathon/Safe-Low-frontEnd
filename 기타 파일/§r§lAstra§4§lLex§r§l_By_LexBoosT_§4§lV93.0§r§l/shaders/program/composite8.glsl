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

    uniform sampler2D colortex0;

    #ifndef UNDERWATER_NO_BLUR_HAND
    uniform sampler2D depthtex1;
    #endif

    #ifdef UNDERWATER_BLUR
    uniform float viewWidth, viewHeight;
    uniform int isEyeInWater;
    #endif

    //Common Functions//

    #ifndef UNDERWATER_NO_BLUR_HAND
        bool IsHand(float z) {
            return z < 0.56;
        }
    #endif

    #ifdef UNDERWATER_BLUR
    vec4 underwaterBlur(out vec4 waterBlurCol, float z1) {

        vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);

        vec4 color = texture2D(colortex0, uv);

        const float Size = UNDERWATER_BLUR_FACTOR;

        vec2 Radius = Size / vec2(viewWidth, viewHeight);

        #ifndef UNDERWATER_NO_BLUR_HAND
            if (IsHand(z1))
                return waterBlurCol = color;
        #endif

        for (float d = 0.0; d < TAU; d += TAU * 0.0625) {

            color += texture2D(colortex0, uv + vec2(cos(d), sin(d)) * Radius);

        }

        color *= 0.0625;

        return waterBlurCol = color;

    }
    #endif

    //Program//
    void main() {
        vec4 color = texture2D(colortex0, texCoord);
        float z1 = 0.0;

        #ifndef UNDERWATER_NO_BLUR_HAND
            z1 = texture2D(depthtex1, texCoord).x;
        #endif

        #ifdef UNDERWATER_BLUR
            if (isEyeInWater == 1) {
                underwaterBlur(color, z1);
            }
        #endif

        /* RENDERTARGETS: 0 */
        gl_FragData[0] = vec4(color);

    }

#endif