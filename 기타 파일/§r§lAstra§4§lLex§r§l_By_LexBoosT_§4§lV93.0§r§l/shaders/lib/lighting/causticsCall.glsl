if (isEyeInWater == 1) {

    float skyLightMap = lightmap.y * lightmap.y * (3.0 - 2.0 * lightmap.y);

    #if defined NEWMOON_DISABLER_STUFF
    shadow *= NoL * (1.0 - (float((moonPhase == 4)) * (1.0 - sunVisibility)));
    #else
    shadow *= NoL;
    #endif

    albedo.rgb = GetCaustics(albedo.rgb, worldPos.xyz, cameraPosition.xyz, shadow, skyLightMap, lightmap.x);
}
