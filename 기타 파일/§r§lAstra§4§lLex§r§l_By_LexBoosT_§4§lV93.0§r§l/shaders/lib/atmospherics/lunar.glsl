vec3 getLunarCoord(vec3 pos) {

    vec3 npos = normalize(pos);

    npos = normalize(moonRotMatrix * npos);

    return npos;
}

vec3 polar(vec3 cart) {

    vec3 p = vec3(0.0);
    p.x = length(cart);
    p.y = acos(cart.y / p.x);
    p.z = atan(cart.z, cart.x);

    return p;
}