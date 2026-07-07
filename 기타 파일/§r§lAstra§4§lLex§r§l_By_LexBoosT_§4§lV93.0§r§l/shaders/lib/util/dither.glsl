float Bayer2(vec2 c) {
    c = 0.5 * floor(c);
    return fract(1.5 * fract(c.y) + c.x);
}
float Bayer4(vec2 c) {
    return 0.25 * Bayer2(0.5 * c) + Bayer2(c);
}
float Bayer8(vec2 c) {
    return 0.25 * Bayer4(0.5 * c) + Bayer2(c);
}
float Bayer16(vec2 c) {
    return 0.25 * Bayer8(0.5 * c) + Bayer2(c);
}
float Bayer32(vec2 c) {
    return 0.25 * Bayer16(0.5 * c) + Bayer2(c);
}
float Bayer64(vec2 c) {
    return 0.25 * Bayer32(0.5 * c) + Bayer2(c);
}

float InterleavedGradientNoise() {
    float n = 52.9829189 * fract(0.06711056 * gl_FragCoord.x + 0.00583715 * gl_FragCoord.y);
    #if AA > 1
    return fract(n + 1.61803398875 * mod(float(frameCounter), 3600.0));
    #else
    return fract(n);
    #endif
}

float animateDither(float dither) {
    float ditherAnimate = 1.61803398875 * mod(float(frameCounter), 3600.0);
    return fract(dither + ditherAnimate);
}