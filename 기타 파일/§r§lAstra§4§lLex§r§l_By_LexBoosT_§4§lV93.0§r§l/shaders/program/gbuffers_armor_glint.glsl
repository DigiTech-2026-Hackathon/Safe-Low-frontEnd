/*#############################################
#    _   ___ _____ ___    _   _    _____  __  #
#   /_\ / __|_   _| _ \  /_\ | |  | __\ \/ /  #
#  / _ \\__ \ | | |   / / _ \| |__| _| >  <   #
# /_/ \_\___/ |_| |_|_\/_/ \_\____|___/_/\_\  #
#											  #
#############################################*/

//Settings//////////////////Settings///////////////////Settings///////////////////Settings//

//#define DEBUG_ARMOR_GLINT

#include "/lib/util/functions.glsl"

#include "/settings/globalSettings.glsl"

//Varying////////////////////Varying////////////////////Varying////////////////////Varying//
varying vec2 texCoord;
varying vec3 sunVec, upVec;
varying vec4 color;

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

    //Uniforms//
    uniform mat4 gbufferModelViewInverse;

    uniform float frameTimeCounter;

    #if MOUVEMENT_CAM > 0
	uniform float onGroundSmooth;
	#endif

    //Includes//
    #ifdef WORLD_CURVATURE
        #include "/lib/vertex/worldCurvature.glsl"
    #endif

    //Program//
    void main(){
            texCoord=(gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

            float angle = PI * GLINT_DIRECTION / 180;
            vec2 nativeDirectionApprox = vec2(0.07655, -0.266);
            vec2 additionnalDirection = vec2(sin(angle),cos(angle));
            texCoord += frameTimeCounter * (additionnalDirection * GLINT_SPEED * 0.265 + nativeDirectionApprox);

            color=gl_Color;

            vec4 position=gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

            vec4 temppos=gl_ProjectionMatrix * gbufferModelView * position;

            if((temppos.z/temppos.w) < 0.56)//hand
            {

                #ifdef MOUVEMENTS_MAINS
                    position-=vec4(0.03 * sin(frameTimeCounter * 3.0 * SPEED_MOOVE), 0.015 * cos(frameTimeCounter * 4.0 * SPEED_MOOVE), 0.0, 0.0) * gbufferModelView;
                #endif

                #ifdef MOUVEMENTS_MAINS_2
                    position.y+=sin(frameTimeCounter * 3.0 * SPEED_MOOVE) * 0.015;
                    position.z-=cos(frameTimeCounter * 4.0 * SPEED_MOOVE) * 0.0015;
                #endif

                position=gbufferModelView * position;

                position.z-=ADVANCE_HAND_POS;
                position.y+=ADVANCE_HAND_POS2;
                position.x+=DECALLAGE_MAINS;

                gl_Position=gl_ProjectionMatrix * position;
            }
            else
            {
                #ifdef WORLD_CURVATURE
                    if (gl_ProjectionMatrix[2][2] < -0.5) position.y -= WorldCurvature(position.xz);
                    gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
                #else
                    gl_Position = ftransform();
                #endif

                #if MOUVEMENT_CAM > 0
                    gl_Position += vec4(0.03 * sin(frameTimeCounter * 3.0 * SPEED_MOOVE), 0.015 * cos(frameTimeCounter * 4.0 * SPEED_MOOVE), 0.0, 0.0) * gl_ProjectionMatrix * onGroundSmooth;
                #endif
            }

    }
#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

    //Uniforms//
    uniform ivec2 eyeBrightnessSmooth;
    uniform sampler2D texture;
    uniform float frameTimeCounter;

    //Includes//
    #ifdef MAGICAL_GLINT
        #include "/lib/color/hue.glsl"
    #endif

    float eBS = eyeBrightnessSmooth.y / 240.0;
    float sunVisibility=clamp00125(dot( sunVec, upVec) + 0.0625) * 8.0;

    //Program//
    void main(){
        vec4 albedo = texture2D(texture, texCoord);
        vec4 multiplier = albedo * color;

        #ifdef MAGICAL_GLINT
            multiplier = vec4(hue2(frameTimeCounter * 0.1 * 4.154), 1.0);
            albedo.rgb = vec3((albedo.r + albedo.g + albedo.b) / 2.2);
            albedo *= multiplier;
        #endif

        vec4 albedoNight = pow(albedo * 0.1, vec4(1.6));
        vec4 albedoSun = pow(albedo * 0.2, vec4(1.6)) / (3.5 - 2.0 * eBS);

        float intensity = GLINT_INTENSITY * 2.0;
        float FinalIntensity = mix(intensity * 0.5, intensity * 3.0, sunVisibility);

        #if (MC_VERSION >= 11904 && !defined RP_COMPATIBILITY)
            FinalIntensity *= 2.5;
        #endif

        vec4 finalAlbedo = mix(albedoNight, albedoSun, sunVisibility);

        finalAlbedo *= FinalIntensity;
        finalAlbedo = clamp01(finalAlbedo);

        albedo = clamp01(finalAlbedo);

        /* RENDERTARGETS: 0 */
        #ifdef DEBUG_ARMOR_GLINT
            gl_FragData[0]=vec4(0.898, 1.0, 0.0, 0.75);
        #else
            gl_FragData[0] = clamp01(albedo);
        #endif

    }

#endif