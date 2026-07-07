vec3 hue2(float h) {
    float t = h * TAU;
    vec3 rgb = vec3(sin(t) * 0.5 + 0.5, sin(t + PI * 0.5) * 0.5 + 0.5, sin(t + PI) * 0.5 + 0.5);

    return rgb;
}