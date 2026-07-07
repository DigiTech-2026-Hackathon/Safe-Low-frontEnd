vec3 drawBirdLine(vec3 color, vec3 worldPos, vec3 v1, vec3 v2, float size) {

    float l1 = length(v1 - worldPos);
    float l2 = length(v2 - worldPos);
    float l3 = length(v1 - v2);
    if (l3 < BIRD_LINE_THICKNESS * size) {
        l3 = BIRD_LINE_THICKNESS * size;
    }

    vec3 ss3 = cross(v1, v2);
    ss3 = normalize(ss3);
    float dist = dot(worldPos, ss3);

    if (dist < 0) {
        dist = - dist;
    }

    if ((dist < BIRD_LINE_THICKNESS * size && l3 > l1 && l3 > l2)) {
        color = vec3(0.0);
    }
    return color;

}

vec3 drawBird(vec3 color, vec3 worldPos, vec3 birdPos, float dir, float numBird, float size, float wingdecal) {

    vec3 birdColor = color;
    vec3 nWorldPos = normalize(worldPos);
    vec3 nBirdPos = normalize(birdPos);
    vec3 VcrossB = cross(nWorldPos, nBirdPos);

    float cosb = dot(nWorldPos, nBirdPos);
    float sinb = length(VcrossB);

    if (sinb < 0.018 && cosb > 0.0) {

        float decal = sin((frameTimeCounter + wingdecal) * 4.0) * size;

        vec3 BcrossU = cross(nBirdPos, vec3(0.0, 1.0, 0.0));
        vec3 midPos = normalize(nBirdPos + vec3(0.0, 0.005, 0.0) * decal);
        vec3 leftPos = normalize(nBirdPos + normalize(BcrossU) * 0.0125 * dir * size - vec3(0.0, 0.005, 0.0) * decal);
        vec3 rightPos = normalize(nBirdPos - normalize(BcrossU) * 0.0075 * dir * size - vec3(0.0, 0.005, 0.0) * decal);

        float cosm = dot(nWorldPos, midPos);
        float sinm = length(cross(nWorldPos, midPos));

        float cosl = dot(nWorldPos, leftPos);
        float sinl = length(cross(nWorldPos, leftPos));

        float cosr = dot(nWorldPos, rightPos);
        float sinr = length(cross(nWorldPos, rightPos));
        if (sinm < BIRD_LINE_THICKNESS * size && cosm > 0.0)
        birdColor = vec3(0.0);
        if (sinl < BIRD_LINE_THICKNESS * size && cosl > 0.0)
        birdColor = vec3(0.0);
        if (sinr < BIRD_LINE_THICKNESS * size && cosr > 0.0)
        birdColor = vec3(0.0);

        birdColor = drawBirdLine(birdColor, nWorldPos, leftPos, midPos, size);
        birdColor = drawBirdLine(birdColor, nWorldPos, rightPos, midPos, size);
    }

    return birdColor;
}

vec4 getBirdPos1(vec3 worldPos, float dir, float decal) {
    float f = 0.2 * (frameTimeCounter + decal) * dir;
    float rotAngle = mod(0.2 * f * TAU / 12.0, TAU);
    float worAngle = atan(worldPos.z, worldPos.x);
    float totAngle = worAngle - rotAngle;

    float rWorAngle = round(worAngle * 12.0 / TAU) * TAU / 12.0;
    float rRotAngle = round(rotAngle * 12.0 / TAU) * TAU / 12.0;
    float rTotAngle = mod(round(totAngle * 12.0 / TAU) * TAU / 12.0, TAU);

    float numBird = rTotAngle * 12.0 / TAU;
    if (numBird < 0)
    numBird += 12.0;

    float modRotAngle = mod(rotAngle - rRotAngle, TAU / 12.0);

    if (modRotAngle > 0.0) {
        modRotAngle -= TAU / 12.0;
    }

    float tUpDown = numBird * 54.3 + f * 6.1 + 1.2;
    float tLeftRight = numBird * 78.7 + f * 5.6 + 3.05;

    float testAngle = rWorAngle + modRotAngle + 0.2 * (TAU / 48.0) * sin(tLeftRight);

    vec3 bpos = vec3(cos(testAngle), BIRDS_HEIGHT + BIRDS_AMPLITUDE * sin(tUpDown), sin(testAngle));

    return vec4(normalize(bpos), numBird);
}

vec4 getBirdPos2(vec3 worldPos, float dir, float decal) {
    float f = 0.2 * (frameTimeCounter + decal) * dir;
    float rotAngle = mod(0.2 * f * TAU / 12.0, TAU);
    float worAngle = atan(worldPos.z, worldPos.x);
    float totAngle = worAngle - rotAngle;

    float rWorAngle = round(worAngle * 12.0 / TAU) * TAU / 12.0;
    float rRotAngle = round(rotAngle * 12.0 / TAU) * TAU / 12.0;
    float rTotAngle = mod(round(totAngle * 12.0 / TAU) * TAU / 12.0, TAU);

    float numBird = rTotAngle * 12.0 / TAU;
    if (numBird < 0)
    numBird += 12.0;

    float modRotAngle = mod(rotAngle - rRotAngle, TAU / 12.0);

    if (modRotAngle < 0.0) {
        modRotAngle += TAU / 12.0;
    }

    float tUpDown = numBird * 54.3 + f * 6.1 + 1.2;
    float tLeftRight = numBird * 78.7 + f * 5.6 + 3.05;

    float testAngle = rWorAngle + modRotAngle + 0.2 * (TAU / 48.0) * sin(tLeftRight);

    vec3 bpos = vec3(cos(testAngle), BIRDS_HEIGHT + BIRDS_AMPLITUDE * sin(tUpDown), sin(testAngle));

    return vec4(normalize(bpos), numBird);
}

vec3 drawBirdGroup(vec3 color, vec3 worldPos, float dir, float decal, float size) {

    vec4 birdPos;
    float birdWeight;

    // draw bird 1
    birdPos = getBirdPos1(worldPos, dir, decal);
    birdWeight = birdPos.w / 12.0 * decal;
    color.rgb = drawBird(color.rgb, worldPos, birdPos.xyz, - dir, birdPos.w, size, birdWeight);

    // draw bird 2
    birdPos = getBirdPos2(worldPos, dir, decal);
    birdWeight = birdPos.w / 12.0 * decal;
    color.rgb = drawBird(color.rgb, worldPos, birdPos.xyz, - dir, birdPos.w, size, birdWeight);

    return color;
}