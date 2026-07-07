float GetOutlineMask() {
    #if defined OUTLINE_TRIPWIRE
    return 1.0;
    #endif

    float viewHeight = 720.0;
    float aspectRatio = 16.0 / 9.0;

    float ph = ceil(viewHeight / 720.0) * 0.5 / viewHeight;
    float pw = ph / aspectRatio;

    float mask = 0.0;
    int offsetSample = 12;

    #if !defined OUTLINE_TRIPWIRE
    offsetSample = 22;
    #endif

    for(int i = 0; i < offsetSample; i ++ ) {

        vec2 offset = vec2(pw, ph) * outlineOffsets[i];

        #if !defined OUTLINE_TRIPWIRE
        if (textureLod(colortex8, texCoord + offset, 0).g > 0.5) {
            return 0.0;
        }
        #endif

        float depth0 = texture2D(depthtex0, texCoord + offset).r;
        float depth1 = texture2D(depthtex1, texCoord + offset).r;
        mask += step(depth0, depth1) * 2.0 - 1.0;
    }

    return step(0.0, mask);
}