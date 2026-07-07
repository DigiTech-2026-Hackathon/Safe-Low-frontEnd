void GetMaterials(out float smoothness, out float metalness, out float f0, inout float emission, inout float subsurface, out float porosity, out float ao, out vec3 normalMap, vec2 newCoord, vec2 dcdx, vec2 dcdy) {

    vec4 specularMap = vec4(0.0, 0.0, 0.0, 1.0);
    float ssrMask = 0.0;
    float emissionMat = 0.0;

    #ifdef MC_SPECULAR_MAP
    #ifdef PARALLAX
    specularMap = textureGrad(specular, newCoord, dcdx, dcdy);
    #else
    specularMap = texture2D(specular, texCoord);
    #endif
    #else
    specularMap = vec4(0.0, 0.0, 0.0, 1.0);
    #endif

    normalMap = textureGrad(normals, newCoord, dcdx, dcdy).rgb;
    normalMap.xyz += vec3(0.5, 0.5, 0.0);
    normalMap.xyz = pow(normalMap.xyz, vec3(NORMALS_STRENGTH));
    normalMap.xyz -= vec3(0.5, 0.5, 0.0);

    #if MATERIAL_FORMAT == 0

    smoothness = specularMap.r;
    f0 = 0.04;
    metalness = specularMap.g;
    porosity = 0.5 - 0.5 * smoothness;

    ssrMask = specularMap.a > 0.0 ? 1.0 - specularMap.a : 0.0;

    #ifdef SSS
    subsurface = mix(ssrMask, 1.0, subsurface);
    #else
    subsurface = ssrMask;
    #endif

    #if (EMISSIVE == 1 || EMISSIVE == 2)
    emissionMat = specularMap.b * specularMap.b;
    #endif

    ao = 1.0;

    normalMap.xyz = normalMap.xyz * 2.0 - 1.0;

    #elif MATERIAL_FORMAT == 1

    #ifdef MC_SPECULAR_MAP
    specularMap = textureLod(specular, newCoord, 0);
    #endif

    smoothness = specularMap.r;

    #if ((defined GBUFFERS_HAND || defined GBUFFERS_ENTITIES)&&(HAND_ENTITIES_SPECULAR_TRICK == 1))
    f0 = specularMap.g * specularMap.g;
    metalness = f0 >= 0.7 ? 1.0 : 0.0;
    #else
    f0 = specularMap.g;
    metalness = f0 >= 0.9 ? 1.0 : 0.0;
    #endif

    porosity = specularMap.b <= 0.251 ? specularMap.b * 3.984 : 0.0;
    ssrMask = specularMap.b > 0.251 ? clamp01(specularMap.b * 1.335 - 0.355) : 0.0;

    #ifdef SSS
    subsurface = mix(ssrMask, 1.0, subsurface);
    #else
    subsurface = ssrMask;
    #endif

    #if (EMISSIVE == 1 || EMISSIVE == 2)
    emissionMat = specularMap.a < 1.0 ? clamp(specularMap.a * 1.004 - 0.004, 0.0, 1.0) : 0.0;
    #endif

    #ifdef PARALLAX
    ao = textureGrad(normals, newCoord, dcdx, dcdy).z;
    #else
    ao = texture2D(normals, texCoord).z;
    #endif

    normalMap.xyz = normalMap.xyz * 2.0 - 1.0;
    float normalCheck = normalMap.x + normalMap.y;
    if (normalCheck > - 1.999) {
        if (length(normalMap.xy) > 1.0)
        normalMap.xy = normalize(normalMap.xy);
        normalMap.z = sqrt(1.0 - dot(normalMap.xy, normalMap.xy));
        normalMap = normalize(clampVec3Inv_11(normalMap));
    } else {
        normalMap = vec3(0.0, 0.0, 1.0);
        ao = 1.0;
    }
    #endif

    #if EMISSIVE == 2
    emission = mix(emissionMat, 1.0, emission);
    #elif EMISSIVE == 1
    emission = emissionMat;
    #elif EMISSIVE == 3
    emission = emission;
    #endif

    #ifdef NORMAL_DAMPENING
    vec2 mipx = dcdx * atlasSize;
    vec2 mipy = dcdy * atlasSize;
    float delta = max(dot(mipx, mipx), dot(mipy, mipy));
    float miplevel = Max0(0.25 * log2(delta));

    normalMap = normalize(mix(vec3(0.0, 0.0, 1.0), normalMap, 1.0 / exp2(miplevel)));
    #endif
}