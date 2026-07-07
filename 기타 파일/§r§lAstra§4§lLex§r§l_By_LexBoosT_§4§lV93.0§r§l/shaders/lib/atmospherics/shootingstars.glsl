vec3 DrawShootingStar(vec3 color, vec3 worldPosition, float variation, float dither) {
    float frameShootingStar = frameTimeCounter / SPEED_SHOOTING;
    float visibility = 1.0;

    #ifdef OVERWORLD
    visibility = moonVisibility * (1.0 - rainFactor);
    #endif

    float sectorTime = mod(frameShootingStar, 1.0);

    float limit1 = 49.0 * variation;
    float limit2 = 69.0 * variation;

    float time1 = mod(floor(frameShootingStar), limit1) / limit1;
    float time2 = mod(floor(frameShootingStar), limit2) / limit2;

    vec3 worldPos = vec3(gbufferModelViewInverse * vec4(worldPosition, 1.0));

    vec3 starPos1Start = texture2D(noisetex, vec2(time1, time2)).rgb;
    starPos1Start.xz = (starPos1Start.xz * 2.0) - 1.0;
    starPos1Start.y = (starPos1Start.y * 0.9) + 0.1;

    vec3 starPos2Start = texture2D(noisetex, vec2(1.0 - time1, 1.0 - time2)).rgb;
    starPos2Start.xz = (starPos2Start.xz * 2.0) - 1.0;
    starPos2Start.y = (starPos2Start.y * 0.9) + 0.1;

    float isShooting = texture2D(noisetex, vec2(time2, time1)).r;

    starPos1Start = normalize(starPos1Start);
    starPos2Start = normalize(starPos2Start);

    if (length(starPos1Start - starPos2Start) > 0.7 && visibility > 0.0 && isShooting < SHOW_DELAY) {
        vec3 starPos1;
        vec3 starPos2;

        if (sectorTime < 0.5) {
            starPos1 = mix(starPos2Start, starPos1Start, sectorTime * 2.0);
            starPos2 = starPos2Start;
        } else {
            starPos1 = starPos1Start;
            starPos2 = mix(starPos1Start, starPos2Start, (1.0 - sectorTime) * 2.0);
        }

        starPos1 = normalize(starPos1);
        starPos2 = normalize(starPos2);
        worldPos = normalize(worldPos);

        float starThickness = STAR_THICKNESS * 0.01;

        float length1 = length(starPos1 - worldPos);
        float length2 = length(starPos2 - worldPos);
        float length3 = length(starPos1 - starPos2);

        if (length3 < starThickness) {
            length3 = starThickness;
        }

        float length4 = length(((starPos1 + starPos2) / 2.0) - worldPos);

        vec3 crossProduct = cross(starPos1, starPos2);
        crossProduct = normalize(crossProduct);
        float distance = dot(worldPos, crossProduct);

        if (distance < 0) {
            distance = -distance;
        }

        if ((distance < starThickness && length3 > length1 && length3 > length2) || length1 < starThickness) {
            float t1 = 1.0 - (distance / starThickness);
            float t2 = 1.0 - (length1 / length3);
            t2 = pow(t2, SHOOTING_STARS_FADE);
            float t = t1 * t2 * dither;
            float fade = clamp01((1.0 - sectorTime));
            fade = clamp01(pow(fade, 30.0) * 700.0);

            color = clamp01(mix(color, vec3(SHOOTING_INTENSITY) * 30.0 * visibility, t * fade));
        }
    }

    return color;
}