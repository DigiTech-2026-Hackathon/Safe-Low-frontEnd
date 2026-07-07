mat3 getMoonRotMatrix(vec3 uSunVec) {
    uSunVec = normalize(uSunVec);
    vec3 uupvec = vec3(0.0, 1.0, 0.0);

    vec3 avgvec = normalize(uupvec - uSunVec);

    vec4 quat = normalize(vec4(cross(uupvec, avgvec), dot(uupvec, avgvec)));

    mat3 rotMatrix;
    rotMatrix[0][0] = 1.0 - 2.0 * quat.y * quat.y - 2.0 * quat.z * quat.z;
    rotMatrix[1][0] = 2.0 * quat.x * quat.y + 2.0 * quat.z * quat.w;
    rotMatrix[2][0] = 2.0 * quat.x * quat.z + 2.0 * quat.y * quat.w;
    rotMatrix[0][1] = 2.0 * quat.x * quat.y - 2.0 * quat.z * quat.w;
    rotMatrix[1][1] = 1.0 - 2.0 * quat.x * quat.x - 2.0 * quat.z * quat.z;
    rotMatrix[2][1] = 2.0 * quat.y * quat.z + 2.0 * quat.x * quat.w;
    rotMatrix[0][2] = 2.0 * quat.x * quat.z + 2.0 * quat.y * quat.w;
    rotMatrix[1][2] = 2.0 * quat.y * quat.z - 2.0 * quat.x * quat.w;
    rotMatrix[2][2] = 1.0 - 2.0 * quat.x * quat.x - 2.0 * quat.y * quat.y;

    return rotMatrix;
}

mat3 rotmat(float rotx, float roty, float rotz) {

    float rotxp = radians(rotx + 90.0);
    float rotyp = radians(roty);
    float rotzp = radians(rotz);
    float a = cos(rotxp);
    float b = sin(rotxp);
    float c = cos(rotyp);
    float d = sin(rotyp);
    float e = cos(rotzp);
    float f = sin(rotzp);

    mat3 rotxmat = mat3(1.0, 0.0, 0.0, 0.0, a, b, 0.0, - b, a);

    mat3 rotymat = mat3(c, 0.0, - d, 0.0, 1.0, 0.0, d, 0.0, c);

    mat3 rotzmat = mat3(e, f, 0.0, - f, e, 0.0, 0.0, 0.0, 1.0);

    return rotzmat * rotxmat * rotymat;

}
