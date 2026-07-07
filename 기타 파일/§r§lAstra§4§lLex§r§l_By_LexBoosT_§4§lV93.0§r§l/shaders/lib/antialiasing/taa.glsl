vec3 Reprojection(vec3 pos, vec3 cameraOffset) {
	pos = pos * 2.0 - 1.0;

	vec4 viewPosPrev = gbufferProjectionInverse * vec4(pos, 1.0);
	viewPosPrev /= viewPosPrev.w;
	viewPosPrev = gbufferModelViewInverse * viewPosPrev;

	vec4 previousPosition = viewPosPrev + vec4(cameraOffset, 0.0);
	previousPosition = gbufferPreviousModelView * previousPosition;
	previousPosition = gbufferPreviousProjection * previousPosition;
	return previousPosition.xyz / previousPosition.w * 0.5 + 0.5;
}

#if defined (TAA_VERSION_1)
	ivec2 neighbourhoodOffsets[8] =  ivec2[8](ivec2(-1, -1),
											  ivec2( 0, -1),
											  ivec2( 1, -1),
											  ivec2(-1,  0),
											  ivec2( 1,  0),
											  ivec2(-1,  1),
											  ivec2( 0,  1),
											  ivec2( 1,  1)
);
	const int numOffsets = 8;

#elif defined (TAA_VERSION_2)
	ivec2 neighbourhoodOffsets[25] = ivec2[25] (ivec2( 2,  2),
											    ivec2( 1,  2),
											    ivec2( 0,  2),
											    ivec2(-1,  2),
											    ivec2(-2,  2),
											    ivec2( 2,  1),
											    ivec2( 1,  1),
											    ivec2( 0,  1),
											    ivec2(-1,  1),
											    ivec2(-2,  1),
											    ivec2( 2,  0),
											    ivec2( 1,  0),
											    ivec2( 0,  0),
											    ivec2(-1,  0),
											    ivec2(-2,  0),
											    ivec2( 2, -1),
											    ivec2( 1, -1),
											    ivec2( 0, -1),
											    ivec2(-1, -1),
											    ivec2(-2, -1),
											    ivec2( 2, -2),
											    ivec2( 1, -2),
											    ivec2( 0, -2),
											    ivec2(-1, -2),
											    ivec2(-2, -2)
);
	const int numOffsets=25;
#endif

void NeighbourhoodClamping(vec3 color, inout vec3 tempColor, float depth, inout float edge) {
    const int groupSize = 128;
    const int numGroups = (numOffsets + groupSize - 1) / groupSize;

    vec3 minclr = color, maxclr = color;

    for (int groupId = 0; groupId < numGroups; groupId++) {
        int groupStart = groupId * groupSize;
        int groupEnd = min(groupStart + groupSize, numOffsets);
        vec3 groupMin = color, groupMax = color;
        for (int i = groupStart; i < groupEnd; i++) {
            ivec2 texelCoordM = texelCoord + neighbourhoodOffsets[i];
            float depthCheck = texelFetch(depthtex1, texelCoordM, 0).r;
            float diff = abs(GetLinearDepth(depthCheck) - GetLinearDepth(depth));
            edge = mix(edge, 0.25, step(0.09, diff));
            vec3 clr = texelFetch(colortex1, texelCoordM, 0).rgb;
            groupMin = min(groupMin, clr);
            groupMax = max(groupMax, clr);
        }
        minclr = min(minclr, groupMin);
        maxclr = max(maxclr, groupMax);
    }

    tempColor = clamp(tempColor, minclr, maxclr);
}

void TAA(inout vec3 color, inout vec4 temp) {
	float a = 0.0;
	float b = 0.0;
	float c = 0.0;
	float depth = texelFetch(depthtex1, texelCoord, 0).r;
	float noTAA = texelFetch(colortex7, texelCoord, 0).r;
	if (depth < 0.56 || noTAA > 0.5) {
		return;
	}

	vec3 coord = vec3(texCoord, depth);
	vec3 cameraOffset = cameraPosition - previousCameraPosition;
	vec3 prvCoord = Reprojection(coord, cameraOffset);

	vec2 view = vec2(viewWidth, viewHeight);
	vec3 tempColor = texture2D(colortex2, prvCoord.xy).gba;
	if (tempColor == vec3(0.0)) {
		temp = vec4(temp.r, color);
		return;
	}

	float edge = 0.0;
	NeighbourhoodClamping(color, tempColor, depth, edge);

	vec2 velocity = (texCoord - prvCoord.xy) * view;

	#if defined (TAA_VERSION_1)
        a = 0.5;
        b = 0.4;
        c = 0.4;
    #elif defined (TAA_VERSION_2)
        a = 0.3;
        b = 0.6;
        c = 0.6;
    #endif

	float velocityFactor = length(velocity) * 100.0;
    float taaFactor = max(exp(-velocityFactor) * a + b - length(cameraOffset) * edge, c);
    float blendFactor = float(prvCoord.x > 0.0 && prvCoord.x < 1.0 && prvCoord.y > 0.0 && prvCoord.y < 1.0);
    blendFactor *= taaFactor;

	color = mix(color, tempColor, blendFactor);
	temp = vec4(temp.r, color);
}