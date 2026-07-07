const float PI = radians(180.0);
const float TAU = radians(360.0);
const float EPS = 1e-5;

////////////// F U N C T I O N S //////////////
float powL(float x, int y) {
    float result = 1.0;
    for(int i = 0; i < y; i++) {
        result *= x;
    }
    return result;
}
vec2 powL(vec2 x, int y) {
    vec2 result = vec2(1.0);
    for(int i = 0; i < y; i++) {
        result *= x;
    }
    return result;
}

vec3 powL(vec3 x, int y) {
    vec3 result = vec3(1.0);
    for(int i = 0; i < y; i++) {
        result *= x;
    }
    return result;
}

vec4 powL(vec4 x, int y) {
    vec4 result = vec4(1.0);
    for(int i = 0; i < y; i++) {
        result *= x;
    }
    return result;
}

float pow2(float x) {return powL(x, 2);}
float pow3(float x) {return powL(x, 3);}
float pow4(float x) {return powL(x, 4);}
float pow5(float x) {return powL(x, 5);}
float pow6(float x) {return powL(x, 6);}
float pow7(float x) {return powL(x, 7);}
float pow8(float x) {return powL(x, 8);}
float pow9(float x) {return powL(x, 9);}
float pow10(float x) {return powL(x, 10);}
float pow11(float x) {return powL(x, 11);}
float pow12(float x) {return powL(x, 12);}
float pow13(float x) {return powL(x, 13);}
float pow14(float x) {return powL(x, 14);}
float pow15(float x) {return powL(x, 15);}
float pow16(float x) {return powL(x, 16);}
float pow17(float x) {return powL(x, 17);}
float pow18(float x) {return powL(x, 18);}
float pow19(float x) {return powL(x, 19);}
float pow20(float x) {return powL(x, 20);}
float pow24(float x) {return powL(x, 24);}
float pow32(float x) {return powL(x, 32);}

vec2 pow2(vec2 x) {return powL(x, 2);}
vec2 pow3(vec2 x) {return powL(x, 3);}
vec2 pow4(vec2 x) {return powL(x, 4);}
vec2 pow5(vec2 x) {return powL(x, 5);}
vec2 pow6(vec2 x) {return powL(x, 6);}
vec2 pow7(vec2 x) {return powL(x, 7);}
vec2 pow8(vec2 x) {return powL(x, 8);}
vec2 pow9(vec2 x) {return powL(x, 9);}
vec2 pow10(vec2 x) {return powL(x, 10);}
vec2 pow11(vec2 x) {return powL(x, 11);}
vec2 pow12(vec2 x) {return powL(x, 12);}
vec2 pow13(vec2 x) {return powL(x, 13);}
vec2 pow14(vec2 x) {return powL(x, 14);}
vec2 pow15(vec2 x) {return powL(x, 15);}
vec2 pow16(vec2 x) {return powL(x, 16);}
vec2 pow17(vec2 x) {return powL(x, 17);}
vec2 pow18(vec2 x) {return powL(x, 18);}
vec2 pow19(vec2 x) {return powL(x, 19);}
vec2 pow20(vec2 x) {return powL(x, 20);}
vec2 pow24(vec2 x) {return powL(x, 24);}
vec2 pow32(vec2 x) {return powL(x, 32);}

vec3 pow2(vec3 x) {return powL(x, 2);}
vec3 pow3(vec3 x) {return powL(x, 3);}
vec3 pow4(vec3 x) {return powL(x, 4);}
vec3 pow5(vec3 x) {return powL(x, 5);}
vec3 pow6(vec3 x) {return powL(x, 6);}
vec3 pow7(vec3 x) {return powL(x, 7);}
vec3 pow8(vec3 x) {return powL(x, 8);}
vec3 pow9(vec3 x) {return powL(x, 9);}
vec3 pow10(vec3 x) {return powL(x, 10);}
vec3 pow11(vec3 x) {return powL(x, 11);}
vec3 pow12(vec3 x) {return powL(x, 12);}
vec3 pow13(vec3 x) {return powL(x, 13);}
vec3 pow14(vec3 x) {return powL(x, 14);}
vec3 pow15(vec3 x) {return powL(x, 15);}
vec3 pow16(vec3 x) {return powL(x, 16);}
vec3 pow17(vec3 x) {return powL(x, 17);}
vec3 pow18(vec3 x) {return powL(x, 18);}
vec3 pow19(vec3 x) {return powL(x, 19);}
vec3 pow20(vec3 x) {return powL(x, 20);}
vec3 pow24(vec3 x) {return powL(x, 24);}
vec3 pow32(vec3 x) {return powL(x, 32);}

vec4 pow2(vec4 x) {return powL(x, 2);}
vec4 pow3(vec4 x) {return powL(x, 3);}
vec4 pow4(vec4 x) {return powL(x, 4);}
vec4 pow5(vec4 x) {return powL(x, 5);}
vec4 pow6(vec4 x) {return powL(x, 6);}
vec4 pow7(vec4 x) {return powL(x, 7);}
vec4 pow8(vec4 x) {return powL(x, 8);}
vec4 pow9(vec4 x) {return powL(x, 9);}
vec4 pow10(vec4 x) {return powL(x, 10);}
vec4 pow11(vec4 x) {return powL(x, 11);}
vec4 pow12(vec4 x) {return powL(x, 12);}
vec4 pow13(vec4 x) {return powL(x, 13);}
vec4 pow14(vec4 x) {return powL(x, 14);}
vec4 pow15(vec4 x) {return powL(x, 15);}
vec4 pow16(vec4 x) {return powL(x, 16);}
vec4 pow17(vec4 x) {return powL(x, 17);}
vec4 pow18(vec4 x) {return powL(x, 18);}
vec4 pow19(vec4 x) {return powL(x, 19);}
vec4 pow20(vec4 x) {return powL(x, 20);}
vec4 pow24(vec4 x) {return powL(x, 24);}
vec4 pow32(vec4 x) {return powL(x, 32);}

///////////////////clamp(x, 0.0, 1.0);////////////////////////////
float clamp01(float x) {
    return clamp(x, 0.0, 1.0);
}
vec2 clamp01(vec2 x) {
    return clamp(x, 0.0, 1.0);
}
vec3 clamp01(vec3 x) {
    return clamp(x, 0.0, 1.0);
}
vec4 clamp01(vec4 x) {
    return clamp(x, 0.0, 1.0);
}
///////////////////clampInv(x, -1.0, 1.0);//////////////////////////
float clampInv11(float x) {
    return clamp(x, -1.0, 1.0);
}
vec2 clampInv11(vec2 x) {
    return clamp(x, -1.0, 1.0);
}
vec3 clampInv11(vec3 x) {
    return clamp(x, -1.0, 1.0);
}
vec4 clampInv11(vec4 x) {
    return clamp(x, -1.0, 1.0);
}
///////////////////clamp00125(x, 0.0, 0.125);//////////////////////////
float clamp00125(float x) {
    return clamp(x, 0.0, 0.125);
}
vec2 clamp00125(vec2 x) {
    return clamp(x, 0.0, 0.125);
}
vec3 clamp00125(vec3 x) {
    return clamp(x, 0.0, 0.125);
}
vec4 clamp00125(vec4 x) {
    return clamp(x, 0.0, 0.125);
}
///////////////////clampVec2_01(x, vec2(0.0), vec2(1.0);///////////////
vec2 clampVec2_01(vec2 x) {
    return clamp(x, vec2(0.0), vec2(1.0));
}
///////////////////clampVec3_01(x, vec2(0.0), vec2(1.0);///////////////
vec3 clampVec3_01(vec3 x) {
    return clamp(x, vec3(0.0), vec3(1.0));
}
///////////////////clampVec3Inv_11(x, vec3(-1.0), vec3(1.0);/////////
vec3 clampVec3Inv_11(vec3 x) {
    return clamp(x, vec3(-1.0), vec3(1.0));
}
///////////////////clampVec4_01(x, vec4(0.0), vec4(1.0);///////////
vec4 clampVec4_01(vec4 x) {
    return clamp(x, vec4(0.0), vec4(1.0));
}
///////////////////clampLmC_00933(x, vec2(0.0), vec2(0.9333, 1.0);/////
vec2 clampLmC_00933(vec2 x) {
    return clamp(x, vec2(0.0), vec2(0.9333, 1.0));
}

int min1(int x) {
    return min(x, 1);
}
float min1(float x) {
    return min(x, 1.0);
}

float Max0(float x) {
    return max(x, 0.0);
}
vec2 Max0(vec2 x) {
    return max(x, 0.0);
}
vec3 Max0(vec3 x) {
    return max(x, 0.0);
}
vec4 Max0(vec4 x) {
    return max(x, 0.0);
}

float sqrt1(float x) {
    x = 1.0 - x;
    x *= x;
    return 1.0 - x;
}

float sqrt2(float x) {
    x = 1.0 - x;
    x *= x;
    x *= x;
    return 1.0 - x;
}
float sqrt3(float x) {
    x = 1.0 - x;
    x *= x;
    x *= x;
    x *= x;
    return 1.0 - x;
}
vec2 sqrt3(vec2 x) {
    x = 1.0 - x;
    x *= x;
    x *= x;
    x *= x;
    return 1.0 - x;
}
vec3 sqrt3(vec3 x) {
    x = 1.0 - x;
    x *= x;
    x *= x;
    x *= x;
    return 1.0 - x;
}
vec4 sqrt3(vec4 x) {
    x = 1.0 - x;
    x *= x;
    x *= x;
    x *= x;
    return 1.0 - x;
}

float sqrt1inv(float x) {
        x = 1.0 - x;
        x *= x;
        return x;
    }

float Smooth3(float x)
{
    x = clamp(x, 0.0, 1.0);
    return x * x * (3.0 - 2.0 * x);
}

vec2 Smooth3(vec2 x)
{
	x = clamp(x, 0.0, 1.0);
	return x * x * (3.0 - 2.0 * x);
}

float smoothClamp(float f, float minf, float maxf) {
    if (f <= minf) {
        return minf;
    } else
    if (f >= maxf) {
        return maxf;
    } else {
        float nf = (f - minf) / (maxf - minf);
        float res = 0.0;
        if (nf < 0.5) {
            res = 2.0 * pow2(nf);
        }else {
            float fi = -2.0 * nf + 2.0;
            res = 1 - pow2(fi) / 2.0;
        }
        return res * (maxf - minf) + minf;
    }
}
vec2 smoothClamp2(vec2 v, vec2 minv, vec2 maxv) {
    return vec2(
        smoothClamp(v.x, minv.x, maxv.x),
        smoothClamp(v.y, minv.y, maxv.y)
    );
}
vec3 smoothClamp3(vec3 v, vec3 minv, vec3 maxv) {
    return vec3(
        smoothClamp(v.x, minv.x, maxv.x),
        smoothClamp(v.y, minv.y, maxv.y),
        smoothClamp(v.z, minv.z, maxv.z)
    );
}
vec4 smoothClamp4(vec4 v, vec4 minv, vec4 maxv) {
    return vec4(
        smoothClamp(v.x, minv.x, maxv.x),
        smoothClamp(v.y, minv.y, maxv.y),
        smoothClamp(v.z, minv.z, maxv.z),
        smoothClamp(v.w, minv.w, maxv.w)
    );
}

bool CheckForColor(vec3 albedo, vec3 check) {
    vec3 dif = albedo - check / 255.0;
    return dif == clamp(dif, vec3(-0.001), vec3(0.001));
}

vec3 nvec3(vec4 pos) {
    return pos.xyz / pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

float cdist(vec2 coord) {
    return max(abs(coord.x - 0.5) * 1.95, abs(coord.y - 0.5) * 2.0);
}

float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

mat2 rotate2d(float theta) {
    return mat2(cos(theta), -sin(theta),
                sin(theta),  cos(theta));
}

float GetLuminance(vec3 color) {
    const mat3 SRGB_2_XYZ_MAT2 = mat3(
        0.4124564, 0.3575761, 0.1804375,
        0.2126729, 0.7151522, 0.0721750,
        0.0193339, 0.1191920, 0.9503041
    );

return dot(color, SRGB_2_XYZ_MAT2[1]);
}