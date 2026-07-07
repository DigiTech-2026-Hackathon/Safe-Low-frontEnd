#include "toitoiles.glsl"
#include "/lib/color/shiningstarsColor.glsl"

vec3 DrawShiningStar(vec3 color, vec3 wpos, vec3 starPos, float dither, float ssIntensityMult) {
    vec3 clr = color;
    vec3 polwpos = polar(wpos);
    vec3 polspos = polar(starPos);

    vec3 poldiff = polwpos - polspos;

    vec3 diff = starPos - wpos;

    float starJitter = 1.0;

    #ifdef SHININGSTARS_JITTER
    float jitterSpeed = mix(3.0, 9.0, abs(starPos.x + starPos.z) / 2.0);
    starJitter = sin(frameTimeCounter * jitterSpeed * SHININGSTARS_JITTER_SPEED) * 0.5 + 0.6;
    #endif

    float thicknessStars = THICKSTARS * 0.001;
    float s0 = Max0((0.007 * SIZESTARS) - length(diff)) * 100.0;
    float s1 = Max0(thicknessStars - abs(poldiff.z)) * 100.0;
    float s2 = Max0(thicknessStars - abs(poldiff.y)) * 100.0;
    float s = max(s1, s2) * s0 * S_SSTARS_INTENSITY * ssIntensityMult * starJitter * dither;

    float s0d = Max0((0.004 * SIZESTARS) - length(diff)) * 100.0;
    float s1d = Max0(thicknessStars - abs(poldiff.z - poldiff.y)) * 100.0;
    float s2d = Max0(thicknessStars - abs(poldiff.z + poldiff.y)) * 100.0;
    float sd = max(s1d, s2d) * s0d * S_SSTARS_INTENSITY * ssIntensityMult * starJitter * dither;

    clr = max(max(s, sd) * shiningStarsColSqrt, clr);
    return mix(color, clr, pow(moonVisibility, 2.0));
}

vec3 DrawLine(vec3 color, vec3 v1, vec3 v2, vec3 wpos) {
    vec3 clr = color;
    float lineThickness = LINE_THICKNESS * 0.001;
    float l1 = length(v1 - wpos);
    float l2 = length(v2 - wpos);
    float l3 = length(v1 - v2);
    if (l3 < lineThickness) {
        l3 = lineThickness;
    }

    vec3 ss3 = cross(v1, v2);
    ss3 = normalize(ss3);
    float dist = dot(wpos, ss3);

    if (dist < 0) {
        dist = - dist;
    }

    if ((dist < lineThickness && l3 > l1 && l3 > l2)) {
        clr = mix(clr, lineColSqrt, LINE_TRANSPARENCY * 0.1);
    }
    return mix(color, clr, moonVisibility);
}

ivec2 getConstell(vec3 viewPos) {
    int minindex1 = 0;
    int minindex2 = 0;
    float minl1 = length(viewPos - centers[0]);
    float minl2 = length(viewPos - centers[0]);
    for(int i = 1; i < numconstell; i ++ ) {
        float l = length(viewPos - centers[i]);
        if (l < minl1) {
            minl2 = minl1;
            minl1 = l;
            minindex2 = minindex1;
            minindex1 = i;
        } else if (l < minl2) {
            minl2 = l;
            minindex2 = i;
        }
    }
    ivec2 indexes = ivec2(minindex1, - 1);
    if (minl2 - minl1 < 0.02) {
        indexes.y = minindex2;
    }
    return indexes;
}

vec3 DrawConstellations(vec3 albedo, vec3 wpos, float dither, float ssIntensityMult) {
    if (moonVisibility > 0.0) {
        ivec2 constell = getConstell(wpos.xyz);

        int linestart = 0;
        int starstart1 = 0;
        int starstart2 = 0;

        if (constell.x == 0) {
            linestart = starstart1 = 0;
        } else {
            linestart = constellations[constell.x - 1].y;
            starstart1 = constellations[constell.x - 1].x;
        }
        int lineend = constellations[constell.x].y;
        int starend1 = constellations[constell.x].x;
        int starend2 = 0;
        if (constell.y >= 0) {
            if (constell.y == 0) {
                starstart2 = 0;
            } else {
                starstart2 = constellations[constell.y - 1].x;
            }
            starend2 = constellations[constell.y].x;
        }

        #ifdef CONSTELLATIONS
        for(int i = linestart; i < lineend; i ++ ) {
            albedo.rgb = DrawLine(albedo.rgb, stars[lines[i].x], stars[lines[i].y], wpos.xyz);
        }
        #endif

        /*
        Test jointures entre constellations (decommenter pour tester)
        if(constell.y >= 0) albedo = vec3(1.0, 0.0, 0.0);
        */
        for(int i = starstart1; i < starend1; i ++ ) {
            albedo.rgb = DrawShiningStar(albedo.rgb, wpos.xyz, stars[i], dither, ssIntensityMult);
        }
        if (constell.y >= 0) {
            for(int i = starstart2; i < starend2; i ++ ) {
                albedo.rgb = DrawShiningStar(albedo.rgb, wpos.xyz, stars[i], dither, ssIntensityMult);
            }
        }
    }

    return albedo.rgb;
}