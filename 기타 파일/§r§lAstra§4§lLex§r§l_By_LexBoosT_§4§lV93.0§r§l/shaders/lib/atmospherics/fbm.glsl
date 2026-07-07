float fbmNoise(vec2 p) {
    vec2 ip = floor(p);
    vec2 fp = fract(p);
    float a = hash12(ip);
    float b = hash12(ip + vec2(1, 0));
    float c = hash12(ip + vec2(0, 1));
    float d = hash12(ip + vec2(1, 1));

    vec2 t = smoothstep(0.0, 1.0, fp);
    return mix(mix(a, b, t.x), mix(c, d, t.x), t.y);
}

float fbm(vec2 p, int octaveCount) {
    float value = 0.0;
    float amplitude = 0.25;
    for(int i = 0; i < octaveCount; ++ i)
    {
        value += amplitude * fbmNoise(p);
        p *= rotate2d(0.5);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

vec3 cutColor(vec3 color, float threshold) {
    if (length(color) < threshold)return vec3(0.0);
    else return color;
}

float colorfade(vec3 color, float fade) {
    return 1.0 - ((1.0 - fade) * clamp01(length(color)));
}

vec3 doFBM(vec2 coord, float hashspeed, float fade)
{
    vec2 uv = coord ;
    uv = 2.0 * uv - 1.0;

    uv += 2.5 * fbm(uv + 0.6 * frameTimeCounter * hashspeed, 8) - 1.0;

    float dist = abs(uv.x);

    vec3 col = vec3(0.5, 0.2, 0.8) * mix(0.0, 0.07, hash11(frameTimeCounter * hashspeed)) / dist;
    vec3 col2 = cutColor(col * 0.033 * pow8(fade), 0.5);
    col2 *= colorfade(col, pow8(fade));
    return col2;
}

float testfade(float alt) {
    return smoothstep(0.1, 0.5, clamp01(alt));
}

vec3 skyFBMStep(vec3 wpos, vec3 theta, float hashspeed) {
    wpos.xy *= rotate2d(theta.z * TAU);
    wpos.zx *= rotate2d(theta.y * TAU);
    wpos.yz *= rotate2d(theta.x * TAU);
    float fade = testfade(wpos.x);

    if (wpos.x < 0.0) {
        return vec3(0.0);
    }else {
        return doFBM(wpos.zy, hashspeed, fade);
    }
}

vec3 doFullSkyFBM(vec3 color, vec3 viewPos) {
    vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz);

    bool dragonBattle = gl_Fog.start / far < 0.5;

    vec3 fbmColor = vec3(0.0);

    fbmColor += skyFBMStep(wpos, vec3(0.0, 0.0, 0.0), 0.8);
    fbmColor += skyFBMStep(wpos, vec3(0.0, 0.1666, 0.0), 0.82);
    fbmColor += skyFBMStep(wpos, vec3(0.0, 0.3333, 0.0), 0.84);
    fbmColor += skyFBMStep(wpos, vec3(0.0, 0.5, 0.0), 0.86);
    fbmColor += skyFBMStep(wpos, vec3(0.0, 0.6666, 0.0), 0.88);
    fbmColor += skyFBMStep(wpos, vec3(0.0, 0.8333, 0.0), 0.9);

    if (dragonBattle) {
        color += fbmColor;
    }

    return color;
}