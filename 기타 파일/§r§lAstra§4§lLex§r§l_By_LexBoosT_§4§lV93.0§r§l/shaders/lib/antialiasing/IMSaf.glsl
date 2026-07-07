/*///////////////////////////////IMS Anisotropic Filtering///////////////////////////////
//https://discord.com/channels/774352792659820594/867896166930841631/990274984855363615//
////////////////////////////Idea Based on VanillaBean Shaders////////////////////////////
///////////////////https://github.com/ruvaldak/VanillaBean-shaders/////////////////////*/

float manualDeterminant(mat2 matrix) {
    return matrix[0][0] * matrix[1][1] - matrix[0][1] * matrix[1][0];
}

mat2 inverse(mat2 m) {
    return mat2(
        m[1][1], -m[0][1],
       -m[1][0],  m[0][0]
    ) / manualDeterminant(m);
}

vec4 textureAF(vec2 uv, int samples, vec2 spriteDimensions, vec2 spriteCorner, float viewportHeight) {
    mat2 J = inverse(mat2(dFdx(uv), dFdy(uv)));
    J = transpose(J) * J;
    float d = manualDeterminant(J);
    float t = J[0][0] + J[1][1];
    float D = sqrt(abs(t * t - 4.0 * d));
    float V = (t - D) / 2.0;
    float v = (t + D) / 2.0;
    float M = 1.0 / sqrt(V);
    float m = 1.0 / sqrt(v);
    vec2 A = M * normalize(vec2(-J[0][1], J[0][0] - V));

    float lod = log2(clamp(M / 16.0, m, 1.0) * viewportHeight);

    float samplesDiv2 = samples * 0.5;
    vec2 ADivSamples = A / samples;
    vec3 finalRGB = vec3(0.0);

    for (float i = -samplesDiv2 + 0.5; i < samplesDiv2; i++) {
        vec2 sampleUV = uv + ADivSamples * i;
        sampleUV = clamp(mod(sampleUV - spriteCorner, spriteDimensions) + spriteCorner, spriteBounds.xy, spriteBounds.zw);
        finalRGB += texture2DLod(texture, sampleUV, lod).rgb;
    }

    finalRGB /= samples;
    return vec4(finalRGB, texture2DLod(texture, uv, lod).a);
}