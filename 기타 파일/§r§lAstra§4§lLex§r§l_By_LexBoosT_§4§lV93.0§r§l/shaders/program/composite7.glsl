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
    #ifdef CORRUPTION
    uniform sampler2D noisetex;

    uniform float frameTimeCounter;
    uniform float touchmybody;
    #endif

    uniform sampler2D colortex0;

    //Common Functions//

    #ifdef CORRUPTION
        void corruption(inout vec4 corruptColor) {

            vec2 uv = texCoord;
            vec2 block = floor(texCoord.xy / vec2(64.0));
            vec2 uv_noise = block / vec2(256.0);
            uv_noise += floor(vec2(frameTimeCounter) * vec2(1234.0, 3543.0)) / vec2(256.0);

            float block_thresh = pow(fract(frameTimeCounter * 1236.0453), 5.0) * 0.4 * (touchmybody * 2.0);
            float line_thresh = pow(fract(frameTimeCounter * 2236.0453), 6.0) * 0.9 * (touchmybody * 2.0);

            vec2 uv_r = uv, uv_g = uv, uv_b = uv;

            if (texture2D(noisetex, uv_noise).r < block_thresh ||
                texture2D(noisetex, vec2(uv_noise.y, 0.0)).g < line_thresh) {

                vec2 dist = (fract(uv_noise) - 0.5) * 0.3;
                uv_r += dist * 0.1;
                uv_g += dist * 0.2;
                uv_b += dist * 0.125;
            }

            corruptColor.r = texture2D(colortex0, uv_r).r;
            corruptColor.g = texture2D(colortex0, uv_g).g;
            corruptColor.b = texture2D(colortex0, uv_b).b;

            if (texture2D(noisetex, uv_noise).g < block_thresh)
                corruptColor.rgb = corruptColor.ggg;

        }
    #endif

    //Program//
    void main() {

        vec4 color = texelFetch(colortex0, texelCoord, 0);

        #ifdef CORRUPTION
        corruption(color);
        #endif

        /* RENDERTARGETS: 0 */
        gl_FragData[0] = vec4(color);

    }

#endif