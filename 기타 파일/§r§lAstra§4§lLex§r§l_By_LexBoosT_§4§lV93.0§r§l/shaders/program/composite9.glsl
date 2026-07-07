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

    const float n = float((KUWAHARA_RADIUS + 1.0) * (KUWAHARA_RADIUS + 1.0));

    vec3 kuwastep(vec3 m, float s, ivec2 dir){
        vec3 newm = vec3(0.0);
        vec3 news = vec3(0.0);
        vec3 c;

        for(int i =0; i<=KUWAHARA_RADIUS; i++){
            for(int j =0; j<=KUWAHARA_RADIUS; j++){
                c = texelFetch(colortex0, texelCoord + ivec2(i, j) * dir, 0).rgb;
                newm += c;
                news += c * c;
            }
        }
        newm /= n;
        news = abs(news / n - newm * newm);

        float sigma = news.r + news.g + news.b;
        if(sigma < s){
            s = sigma;
            m = newm;
        }
        return m;
    }

    vec3 kuwahara(){

        vec3 color = vec3(0.0);
        float s = 1000.0;

        color = kuwastep(color, s, ivec2(1,1));
        color = kuwastep(color, s, ivec2(1,-1));
        color = kuwastep(color, s, ivec2(-1,-1));
        color = kuwastep(color, s, ivec2(-1,1));

        return color;
    }

    //Program//
    void main() {

        vec4 color = texelFetch(colortex0, texelCoord, 0);

        #ifdef KUWAHARA_FILTER
            color.rgb = kuwahara();
        #endif

        /* RENDERTARGETS: 0 */
        gl_FragData[0] = vec4(color);
    }

#endif