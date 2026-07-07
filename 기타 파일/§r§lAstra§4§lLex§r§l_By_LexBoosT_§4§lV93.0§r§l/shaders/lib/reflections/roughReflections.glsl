vec4 RaytraceRough(sampler2D depthtex, vec3 viewPos, vec3 normal, float dither, out float border) {
    vec3 pos = vec3(0.0);
    float dist = 0.0;

    vec3 start = viewPos + normal * 0.150;
    vec3 vector = reflect(normalize(viewPos), normalize(normal));
    viewPos += vector;
    vec3 tvector = vector;

    int sr = 0;

    for(int i = 0; i < 30; i ++ ) {
        pos = nvec3(gbufferProjection * nvec4(viewPos)) * 0.5 + 0.5;
        if (pos.x < - 0.05 || pos.x > 1.05 || pos.y < - 0.05 || pos.y > 1.05)
        break;

        vec3 rfragpos = vec3(pos.xy, texture2D(depthtex, pos.xy).r);
        rfragpos = nvec3(gbufferProjectionInverse * nvec4(rfragpos * 2.0 - 1.0));
        dist = length(start - rfragpos);

        float err = length(viewPos - rfragpos);
        float lVector = length(vector);
        if (lVector > 1.0)
        lVector = pow(lVector, 1.14);

        if (err < lVector) {
            sr ++ ;
            if (sr >= 6)
            break;
            tvector -= vector;
            vector *= 0.1;
        }

        vector *= 2.0;
        tvector += vector * (dither * 0.02 + 1.0);
        viewPos = start + tvector;
    }

    border = cdist(pos.xy);

    return vec4(pos, dist);
}

vec4 RoughReflection(vec3 viewPos, vec3 normal, float dither, float smoothness) {
    vec4 color = vec4(0.0);
    float border = 0.0;

    vec4 pos = RaytraceRough(depthtex0, viewPos, normal, dither, border);
    border = clamp01(1.0 - pow(cdist(pos.xy), 50.0));

    if (pos.z < 1.0 - EPS) {
        float lod = 0.0;
        #ifdef REFLECTION_ROUGH
        float dist = 1.0 - exp(-0.125 * (1.0 - smoothness) * pos.a);
        lod = log2(viewHeight / 8.0 * (1.0 - smoothness) * dist) * 0.35;
        #endif

        float check = float(textureLod(depthtex0, pos.xy, 0).r < 1.0 - EPS);
        if (lod < 1.0) {
            color.a = check;
            if (color.a > 0.1)
                color.rgb = textureLod(colortex0, pos.xy, 0).rgb;
        } else {
            float alpha = check;
            if (alpha > 0.1) {

                #ifdef ROUGH_REF_BLUR
                    vec3 blurredColor = vec3(0.0);
                    float blurStrength = 0.0015;

                    for (int i = -1; i <= 1; i++) {
                        for (int j = -1; j <= 1; j++) {
                            vec2 offset = vec2(float(i), float(j)) * blurStrength;
                            vec2 samplePos = pos.xy + offset;
                            blurredColor += textureLod(colortex0, samplePos, Max0(lod - 1.0)).rgb;
                        }
                    }

                    blurredColor /= 9.0;

                    color.rgb += blurredColor;
                #else
                    color.rgb += textureLod(colortex0, pos.xy, Max0(lod - 1.0)).rgb;
                #endif

                color.a += alpha;
            }
        }

        color *= color.a;
        color.a *= border;
    }
    color.rgb *= 1.8 * (1.0 - 0.065 * min(length(color.rgb), 10.0));

    return color;
}