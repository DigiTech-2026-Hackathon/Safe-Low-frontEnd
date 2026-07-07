if (blockEntityId == 10888) {
    if (albedo.b < 0.1) {
        const vec4 colors[16] = vec4[](
            #if COLOR_END_PORTAL == 1
            vec4(0.5922, 0.3569, 0.9725, 1.0),
            vec4(0.8392, 0.3059, 1.0, 0.616),
            vec4(0.7451, 0.0941, 0.9451, 0.432),
            vec4(0.898, 0.0157, 0.9804, 0.651),
            vec4(0.098, 0.0, 1.0, 1.0),
            vec4(0.2353, 0.0431, 0.9412, 1.0),
            vec4(0.3961, 0.0353, 0.6392, 0.527),
            vec4(0.8784, 0.0275, 0.9922, 0.377),
            vec4(0.7216, 0.5294, 0.9765, 0.363),
            vec4(0.5804, 0.4392, 0.8431, 0.384),
            vec4(0.53406537, 0.55311275, 1.5943265, 1.0),
            vec4(0.5765, 0.2431, 0.851, 0.452),
            vec4(0.5902973, 0.4286982, 0.64408666, 1.0),
            vec4(0.5882, 0.1176, 0.8039, 0.479),
            vec4(0.7843, 0.4078, 0.9608, 0.418),
            vec4(0.8784, 0.0275, 0.9922, 0.349)
            #elif COLOR_END_PORTAL == 0
            vec4(0.4422, 0.4422, 0.4422, 1.0),
            vec4(0.6216, 0.6216, 0.8353, 0.616),
            vec4(0.5412, 0.5412, 0.5412, 0.432),
            vec4(0.651, 0.651, 0.8353, 0.651),
            vec4(0.1333, 0.1333, 0.498, 1.0),
            vec4(0.2353, 0.2353, 0.7059, 1.0),
            vec4(0.3176, 0.3176, 0.3176, 0.527),
            vec4(0.698, 0.698, 0.9412, 0.377),
            vec4(0.6086, 0.6086, 0.8353, 0.363),
            vec4(0.4667, 0.4667, 0.6902, 0.384),
            vec4(0.4272, 0.4272, 0.8353, 1.0),
            vec4(0.4314, 0.4314, 0.7059, 0.452),
            vec4(0.5364, 0.5364, 0.6086, 1.0),
            vec4(0.4118, 0.4118, 0.6784, 0.479),
            vec4(0.5922, 0.5922, 0.8353, 0.418),
            vec4(0.698, 0.698, 0.9412, 0.349)
            #endif
        );

        albedo.rgb = colors[15].rgb * 0.001;

        for(int i = 1; i < 16; i++) {
            float colormult = 1.0 / (16 - i + 20.0);
            albedo.rgb *= 0.69 * (1.0 + float(i > 1));
            float rotation = (i - 0.1 * i + 0.71 * i - 11 * i + 21) * 0.01 + i * 0.01;
            float Cos = cos(radians(rotation));
            float Sin = sin(radians(rotation));
            vec2 offset = vec2(0.0, 1.0 / (3600.0 / 24.0)) * pow(16.0 - i, 2.0) * 0.004;

            vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos * (i + 1), 1.0)).xyz);
            if (abs(dot(normal, upVec)) > 0.9) {
                wpos.xz /= wpos.y;
                wpos.xz *= 0.08 * sign(- worldPos.y);
                wpos.xz *= abs(worldPos.y) + i;
                wpos.xz -= cameraPosition.xz * 0.10;
            } else {
                vec3 absPos = abs(worldPos);
                if (abs(dot(normal, eastVec)) > 0.9) {
                    wpos.xz = wpos.yz / wpos.x;
                    wpos.xz *= 0.08 * sign(- worldPos.x);
                    wpos.xz *= abs(worldPos.x) + i;
                    wpos.xz -= cameraPosition.yz * 0.10;
                } else {
                    wpos.xz = wpos.yx / wpos.z;
                    wpos.xz *= 0.08 * sign(- worldPos.z);
                    wpos.xz *= abs(worldPos.z) + i;
                    wpos.xz -= cameraPosition.yx * 0.10;
                }
            }
            vec2 pos = wpos.xz;

            vec2 wind = fract((frameTimeCounter + 984.0) * (i + 8) * 0.125 * offset);
            vec2 coord = mat2(Cos, Sin, - Sin, Cos) * pos + wind;
            if (mod(float(i), 4) < 1.5) coord = coord.yx + vec2(-1.0, 1.0) * wind.y;

            vec4 endPortalSample = texture2D(texture, coord) * colors[i - 1] * colormult;
            albedo += endPortalSample * length(endPortalSample.rgb) * 35.0;
            emission = EMISSIVE_END_PORTAL;
        }
    } else {
        albedo.rgb *= 10.0;
        emission = EMISSIVE_END_PORTAL;
    }
    vanillaDiffuse = 1.0;
    lightmap.x *= 0.77;
    dolighting = false;
}
