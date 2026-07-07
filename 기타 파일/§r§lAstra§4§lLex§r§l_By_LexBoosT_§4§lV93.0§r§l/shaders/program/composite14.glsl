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
    uniform sampler2D colortex1;

    #ifdef SHARPEN_AA
    uniform float viewWidth, viewHeight;
    #endif

    //Common Functions//

    #ifdef SHARPEN_AA
        #if AA > 1
            const ivec2 sharpenOffsets[4] = ivec2[4](
                                            ivec2( 1.0,  0.0),
                                            ivec2( 0.0,  1.0),
                                            ivec2(-1.0,  0.0),
                                            ivec2( 0.0, -1.0)
            );

            void SharpenFilter(inout vec4 color, in vec2 texCoord) {
                float mult = MC_RENDER_QUALITY * 0.0625;
                vec2 view = 1.0 / vec2(viewWidth, viewHeight);

                color *= MC_RENDER_QUALITY * 0.25 + 1.0;

                for (int i = 0; i < 4; i ++) {
                    vec2 offset = sharpenOffsets [i] * view;
                    color -= texelFetch(colortex1, ivec2(texelCoord + offset), 0) * mult;
                }
            }
        #endif
    #endif

        //Program//
    void main() {
        vec4 color = texelFetch(colortex1, texelCoord, 0);

        #ifdef SHARPEN_AA
            #if AA > 1
                SharpenFilter(color, texCoord);
            #endif
        #endif

        /* RENDERTARGETS: 1 */
        gl_FragData[0] = vec4(color);

    }

#endif