float Noise2D(vec2 pos) {
    vec2 flr = floor(pos);
    vec2 frc = fract(pos);
    frc = frc * frc * (3.0 - 2.0 * frc);

    vec2 uv00 = vec2(flr.x, flr.y);
    vec2 uv01 = vec2(flr.x, flr.y + 1.0);
    vec2 uv10 = vec2(flr.x + 1.0, flr.y);
    vec2 uv11 = vec2(flr.x + 1.0, flr.y + 1.0);

    float n00 = GetNoise(uv00);
    float n01 = GetNoise(uv01);
    float n10 = GetNoise(uv10);
    float n11 = GetNoise(uv11);

    float n0 = mix(n00, n01, frc.y);
    float n1 = mix(n10, n11, frc.y);

    return mix(n0, n1, frc.x) - 0.5;
}

vec3 CalcMove(vec3 pos, float density, float speed, vec2 mult) {
    vec3 t = pos * density + frameTimeCounter * WAVING_SPEED;
    t *= speed;
    vec3 wave = vec3(0.0);
    wave.x = Noise2D(vec2(t.y, t.z));
    wave.y = Noise2D(vec2(t.x, t.z + 0.333));
    wave.z = Noise2D(vec2(t.x + 0.667, t.y + 0.667));

    return wave * vec3(mult, mult.x);
}

vec3 CalcMove2(vec3 pos, float density, float speed, vec2 mult) {
    vec3 t = pos * density + frameTimeCounter;
    t *= speed;
    vec3 wave = vec3(0.0);
    wave.x = Noise2D(vec2(t.y, t.z));
    wave.y = Noise2D(vec2(t.x, t.z + 0.333));
    wave.z = Noise2D(vec2(t.x + 0.667, t.y + 0.667));

    return wave * vec3(mult, mult.x);
}

float CalcLilypadMove(vec3 worldpos) {
    float wave = sin(TAU * (frameTimeCounter * 0.7 + worldpos.x * 0.14 + worldpos.z * 0.07)) +
    sin(TAU * (frameTimeCounter * 0.5 + worldpos.x * 0.10 + worldpos.z * 0.20));
    return wave * 0.0125;
}

float CalcLavaMove(vec3 worldpos) {
    float fy = fract(worldpos.y + 0.005);

    if (fy > 0.01) {
        float wave = sin(TAU * (frameTimeCounter * 0.2 + worldpos.x * 0.15 + worldpos.z * 0.10)) +
        sin(TAU * (frameTimeCounter * 0.1 + worldpos.x * 0.13 + worldpos.z * 0.25));
        return wave * 0.025 + 0.035;
    } else
    return 0.0;
}

vec3 CalcLanternMove(vec3 position) {
    vec3 frc = fract(position);
    frc = vec3(frc.x - 0.5, fract(frc.y - 0.001) - 1.0, frc.z - 0.5);
    vec3 flr = position - frc;
    float offset = flr.x * 2.4 + flr.y * 2.7 + flr.z * 2.2;

    float rmult = PI * 0.016;
    float rx = sin(frameTimeCounter + offset) * rmult;
    float ry = sin(frameTimeCounter * 1.7 + offset) * rmult;
    float rz = sin(frameTimeCounter * 1.4 + offset) * rmult;
    mat3 rotx = mat3(1, 0, 0, 0, cos(rx), - sin(rx), 0, sin(rx), cos(rx));
    mat3 roty = mat3(cos(ry), 0, sin(ry), 0, 1, 0, - sin(ry), 0, cos(ry));
    mat3 rotz = mat3(cos(rz), - sin(rz), 0, sin(rz), cos(rz), 0, 0, 0, 1);
    frc = rotx * roty * rotz * frc;

    return flr + frc - position;
}

vec3 CalcPropaguleMove(vec3 position) {
    vec3 frc = fract(position);
    frc = vec3(frc.x - 0.5, fract(frc.y - 0.001) - 1.0, frc.z - 0.5);
    vec3 flr = position - frc;
    float offset = flr.x * 2.2 + flr.y * 2.5 + flr.z * 2.0;

    float rmult = PI * 0.016;
    float rx = sin(frameTimeCounter * (WAVING_SPEED * 1.8) + offset) * rmult;
    float ry = sin(frameTimeCounter * (WAVING_SPEED * 1.8) * 1.7 + offset) * rmult;
    float rz = sin(frameTimeCounter * (WAVING_SPEED * 1.8) * 1.4 + offset) * rmult;
    mat3 rotx = mat3(1, 0, 0, 0, cos(rx), - sin(rx), 0, sin(rx), cos(rx));
    mat3 roty = mat3(cos(ry), 0, sin(ry), 0, 1, 0, - sin(ry), 0, cos(ry));
    mat3 rotz = mat3(cos(rz), - sin(rz), 0, sin(rz), cos(rz), 0, 0, 0, 1);
    frc = rotx * roty * rotz * frc;

    return flr + frc - position;
}

vec3 WavingBlocks(vec3 position, float istopv) {

    vec3 wave = vec3(0.0);
    vec3 worldpos = position + cameraPosition;

    #ifdef WAVING_GRASS
    if ((mc_Entity.x == 10100 || mc_Entity.x == 10701 || mc_Entity.x == 10109)&& istopv > 0.9)
    wave += CalcMove(worldpos, 1.0, 0.85, vec2(0.22, 0.0));
    #endif

    #ifdef WAVING_MUSHROOM
    if ((mc_Entity.x == 10117)&& istopv > 0.9)
    wave += CalcMove(worldpos, 1.0, 0.85, vec2(0.12, 0.0));
    #endif

    #ifdef WAVING_COBWEB
    if ((mc_Entity.x == 10118)&& istopv > 0.9)
    wave += CalcMove(worldpos, 1.0, 0.85, vec2(0.12, 0.0));
    #endif

    #ifdef WAVING_CROPS
    if ((mc_Entity.x == 10102 || mc_Entity.x == 10108)&&(istopv > 0.9 || fract(worldpos.y + 0.0675) > 0.01))
    wave += CalcMove(worldpos, 0.35, 1.0, vec2(0.15, 0.06));
    if ((mc_Entity.x == 10119)&& istopv > 0.9)
    wave += CalcMove(worldpos, 1.0, 0.85, vec2(0.22, 0.0));
    #endif

    #ifdef WAVING_PLANT
    if ((mc_Entity.x == 10101 || mc_Entity.x == 100 || mc_Entity.x == 101 || mc_Entity.x == 104 || mc_Entity.x == 10115)&&(istopv > 0.9 || fract(worldpos.y + 0.005) > 0.01))
    wave += CalcMove(worldpos, 0.7, 1.25, vec2(0.12, 0.0));

    if (mc_Entity.x == 10111 || mc_Entity.x == 10112 || mc_Entity.x == 10256)
    wave += CalcMove(worldpos, 0.5, 1.25, vec2(0.06, 0.0));
    #endif

    #ifdef WAVING_TALL_PLANT
    if ((mc_Entity.x == 10104 || mc_Entity.x == 103 || mc_Entity.x == 10702) && (istopv > 0.9 || fract(worldpos.y + 0.005) > 0.01) || (mc_Entity.x == 10103 || mc_Entity.x == 102 || mc_Entity.x == 10703))
    wave += CalcMove(worldpos, 0.7, 1.25, vec2(0.12, 0.06));
    #endif

    #ifdef WAVING_LEAVES
    if (mc_Entity.x == 10105 || mc_Entity.x == 10704)
    wave += CalcMove(worldpos, 0.35, 1.0, vec2(0.08, 0.08));
    #endif

    #ifdef WAVING_VINES
    if (mc_Entity.x == 10106)
    wave += CalcMove(worldpos, 0.35, 1.25, vec2(0.06, 0.12));
    #endif

    #ifdef WAVING_LILYPAD
    if (mc_Entity.x == 10107)
    wave.y += CalcLilypadMove(worldpos);
    #endif

    #ifdef WAVING_FIRE
    if ((mc_Entity.x == 10249 || mc_Entity.x == 10252)&& istopv > 0.9)
    wave += CalcMove2(worldpos, 0.7, 1.25, vec2(0.25, 0.06));
    #endif

    #ifdef WAVING_LAVA
    if (mc_Entity.x == 10248)
    wave.y += CalcLavaMove(worldpos);
    #endif

    #ifdef WAVING_CHAIN
    if (mc_Entity.x == 10110)
    wave += CalcMove2(worldpos, 1.25, 0.75, vec2(0.02, 0.001));
    #endif

    #ifdef WAVING_LANTERN
    if (mc_Entity.x == 10251 || mc_Entity.x == 10253)
    wave += CalcLanternMove(worldpos);
    #endif

    #ifdef WAVING_LEAVES
    if (mc_Entity.x == 109)
    wave += CalcPropaguleMove(worldpos);
    #endif

    position += wave;

    return position;
}