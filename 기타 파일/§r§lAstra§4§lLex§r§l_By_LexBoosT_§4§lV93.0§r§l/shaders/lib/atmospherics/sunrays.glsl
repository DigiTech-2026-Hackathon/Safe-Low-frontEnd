#include "/lib/color/sunraysColor.glsl"

float line(vec2 A, vec2 B, vec2 C, float thickness, float distmult) {
    vec2 AB = B - A;
    vec2 AC = C - A;

    float t = dot(AC, AB) / dot(AB, AB);
    t = min(0.7, max(0.0, t));

    vec2 Q = A + t * AB;

    float dist = length(Q - C) * distmult;
    return smoothstep(0.0, - dist, - thickness) * 0.2 + smoothstep(0.0, dist, thickness) * 0.1;
}

vec3 sunRays(vec3 raysColor, vec3 worldPos, float NdotU) {
    float UoL = dot(upVec, sunVec);
    float sunSize = SUNSIZE;
    vec3 sunraysVec = mat3(gbufferModelViewInverse) * sunVec;
    vec2 sunCoord = sunraysVec.xz / (sunraysVec.y + length(sunraysVec));
    vec2 planeCoord = worldPos.xz / (worldPos.y + length(worldPos)) - sunCoord;
    vec3 rayColor = clamp01(sunCol);
    vec3 color = vec3(0.0);

    #ifdef REAL_SUNSIZE
    sunSize *= 0.333;
    #endif

    if (sunVisibility > 0.0) {
        if (length(planeCoord) < (0.10 + 0.3 * (RAY_DIST_AMPLITUDE1 + RAY_DIST_AMPLITUDE2)) * sqrt(6000.0 / sunSize)) {

            for(int i = 0; i < NUM_RAYS; ++ i) {
                float r1 = 0.5 + RAY_DIST_AMPLITUDE1 + sin(frameTimeCounter * RAY_MOVE_SPEED + float(i) * PI * 2.851) * RAY_DIST_AMPLITUDE1;
                float r2 = 1.5 * r1 + RAY_DIST_AMPLITUDE2 + sin(frameTimeCounter * RAY_MOVE_SPEED + float(i) * PI * 5.247) * RAY_DIST_AMPLITUDE2;
                float angle = frameTimeCounter * RAY_ROTATION_SPEED + float(i + 1) * 2.0 / float(NUM_RAYS) * PI;

                vec2 dir = vec2(cos(angle), sin(angle));

                float coeff = mix(1.4, 1.0, UoL) * sqrt(6000.0 / sunSize);
                vec2 A = - dir * r1 * 0.07 * SUN_RAYS_DISTANCE * coeff;
                vec2 B = - dir * r2 * 0.08 * SUN_RAYS_DISTANCE * coeff;

                #if SUNRAYS_COLOR == 1
                rayColor = rayColCustom * 4.0;
                #endif

                color += line(A, B, planeCoord, 0.005, 8.0) * rayColor * mix(3.5, 0.0, rainStrength);
                color += line(A, B, planeCoord, 0.0025, 12.0) * rayLCol * mix(100.0, 0.0, rainStrength);
            }

            color = color * 0.8 + sqrt(pow2(color) / pow2((color) + 0.1));

            float sunsetFade = max(dayFactor + 0.1, (0.4 * sunVisibility));

            float horizonFactor = 1.0;
            #ifdef HORIZON_SUN_MOON
            horizonFactor = clamp01((NdotU + 0.0025) * 20.0);
            #endif

            raysColor = mix(raysColor, min(color, vec3(2.0)), clamp01(length(color * 0.1) * 10.0) * SUN_RAYS_I * (1.0 - rainStrength) * sunsetFade * horizonFactor);

        }
    }
    return raysColor;
}