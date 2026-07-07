#if (defined OVERWORLD &&(defined PLANET || defined PLANET2))

vec3 drawPlanetImage(vec3 albedo, vec3 skycolor, vec2 size, vec3 wpos, sampler2D tex, float opacity) {
    vec3 newwpos = planetRotMatrix * wpos;

    vec2 planetTexCoord = (newwpos.xy / newwpos.z) / size;

    if (- 1.0 < planetTexCoord.x && planetTexCoord.x < 1.0 && - 1.0 < planetTexCoord.y && planetTexCoord.y < 1.0 && newwpos.z > 0.0) {
        vec4 planet = texture2D(tex, vec2(0.5, 0.5) + planetTexCoord * 0.5);
        float planetLength = length(planet.rgb);
        float planetPow = pow2(planetLength + mix(0.2, 0.6, sunVisibility));
        planet.rgb *= planetPow;
        planet.rgb = mix(albedo.rgb, planet.rgb * 0.1, planet.a * opacity);
        albedo.rgb = mix(planet.rgb, skycolor.rgb, step(0.0, planet.a) * sunVisibility * 0.75);
        return albedo.rgb;
    }

    return albedo.rgb;
}
#endif

#if (defined OVERWORLD && defined NEBULA)
vec3 drawNebulaImage(vec3 albedo, vec2 size, vec3 wpos, sampler2D tex, float opacity) {
    vec3 newwpos = nebulaRotMatrix * wpos;
    vec2 nebulaTexCoord = (newwpos.xy / newwpos.z) / size;

    if (moonVisibility > 0.0 && - 1.0 < nebulaTexCoord.x && nebulaTexCoord.x < 1.0 && - 1.0 < nebulaTexCoord.y && nebulaTexCoord.y < 1.0 && newwpos.z > 0.0) {
        vec4 nebula = texture2D(tex, vec2(0.5, 0.5) + nebulaTexCoord * 0.5);
        nebula.rgb *= pow2(length(nebula.rgb) + 0.3);
        albedo.rgb = mix(albedo.rgb, (pow2(nebula.rgb) * 0.7) * 0.15, ((1.0 - sunVisibility) * nightFactor) * nebula.a * opacity);
    }

    return albedo.rgb;
}
#endif

#if (defined OVERWORLD && defined GALAXY)
vec3 drawGalaxyImage(vec3 albedo, vec2 size, vec3 wpos, sampler2D tex, float opacity) {

    vec3 newwpos = galaxyRotMatrix * wpos;
    vec2 galaxyTexCoord = (newwpos.xy / newwpos.z) / size;

    if (moonVisibility > 0.0 && - 1.0 < galaxyTexCoord.x && galaxyTexCoord.x < 1.0 && - 1.0 < galaxyTexCoord.y && galaxyTexCoord.y < 1.0 && newwpos.z > 0.0) {

        vec4 galaxy = texture2D(tex, vec2(0.5, 0.5) + galaxyTexCoord * 0.5);
        galaxy.rgb *= pow2(length(galaxy.rgb) + 0.3);
        albedo.rgb = mix(albedo.rgb, galaxy.rgb * 0.1, ((1.0 - sunVisibility) * nightFactor) * galaxy.a * opacity);

    }

    return albedo.rgb;
}
#endif