float GetPuddles(vec3 worldPos, vec2 coord, float wetness) {
    worldPos = (worldPos + cameraPosition) * 0.005;

    float height = textureGrad(normals, coord, dFdx(coord), dFdy(coord)).a;
    height = mix(1.0, height, PARALLAX_DEPTH);
    height = smoothstep(1.0, 0.95, height) * 0.1 - 0.05;

    vec2 worldPosXZ = worldPos.xz * 0.5;
    float noise = texture2D(noisetex, worldPosXZ).r * 0.375;
    noise += texture2D(noisetex, worldPosXZ * 0.25).r * 0.625;
    noise = noise + (wetness * 1.25 - 0.65) + height;
    noise = max(noise, 0.0);

    return smoothstep(0.4, 0.6, noise);
}

float rand(vec2 worldPos) {
    return fract(sin(dot(worldPos, vec2(12.9898, 4.1414))) * 43758.5453);
}

vec2 getpos(vec2 i) {
    return vec2(rand(i), rand(i + vec2(1.0))) * 0.5 + 0.25;
}

float GetRipple(vec3 worldPos, vec2 offset) {
    vec2 ppos = worldPos.xz + offset * 0.1 + frameTimeCounter * 0.01;
    ppos = vec2(dot(ppos, vec2(0.8, - 0.8)), dot(ppos, vec2(0.8, 0.8)));
    vec2 ppossh = ppos + vec2(fract(0.618 * floor(ppos.y)) * sin(frameTimeCounter * 0.05), 0.0);
    vec2 pposfr = fract(ppossh);
    vec2 pposfl = floor(ppossh);

    vec2 worldPosXZ = ppos * 0.0078125 + frameTimeCounter * 0.007;
    float val = texture2D(noisetex, ppos / 64.0 + frameTimeCounter * 0.007).r * 0.125;
	val += texture2D(noisetex, ppos / 64.0 - frameTimeCounter * 0.005).r * 0.125;

    float seed = rand(pposfl);
    float rippleTime = frameTimeCounter * 1.4 + fract(seed * 1.618);
    float rippleSeed = seed + floor(rippleTime) * 1.618;
    vec2 ripplePos = getpos(pposfl + rippleSeed);
    float rippleDist = length(pposfr - ripplePos);
    float ripple = clamp01(1.0 - 2.0 * rippleDist);
    ripple = clamp01(ripple + fract(rippleTime) - 1.0);
    ripple = sin(min(ripple * 6.0 * PI, 3.0 * PI)) * pow(1.0 - fract(rippleTime), 2.0);
    val += ripple * 0.3;

    return clamp01(val);
}

vec3 GetPuddleNormal(vec3 worldPos, vec3 viewPos, mat3 tbn) {
    vec3 puddlePos = worldPos + cameraPosition;
    const float normalOffset = 0.1;

    float fresnel = pow(clamp01(1.0 + dot(normalize(normal), normalize(viewPos))), 7.5);
    float normalStrength = 0.35 * (1.0 - fresnel);

    float h1 = GetRipple(puddlePos, vec2(normalOffset, 0.0));
    float h2 = GetRipple(puddlePos, vec2(- normalOffset, 0.0));
    float h3 = GetRipple(puddlePos, vec2(0.0, normalOffset));
    float h4 = GetRipple(puddlePos, vec2(0.0, - normalOffset));

    float xDelta = (h2 - h1) / normalOffset;
    float yDelta = (h4 - h3) / normalOffset;

    vec3 normalMap = vec3(xDelta, yDelta, 1.0 - (xDelta * xDelta + yDelta * yDelta));
    normalMap = normalMap * normalStrength + vec3(0.0, 0.0, 1.0 - normalStrength);

    return clampVec3Inv_11(normalize(normalMap * tbn));
}