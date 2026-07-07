/*#############################################
#    _   ___ _____ ___    _   _    _____  __  #
#   /_\ / __|_   _| _ \  /_\ | |  | __\ \/ /  #
#  / _ \\__ \ | | |   / / _ \| |__| _| >  <   #
# /_/ \_\___/ |_| |_|_\/_/ \_\____|___/_/\_\  #
#											  #
#############################################*/

//Settings//////////////////Settings///////////////////Settings///////////////////Settings//

//#define DEBUG_CLOUDS

#include "/lib/util/functions.glsl"

#include "/settings/globalSettings.glsl"

//Varying////////////////////Varying////////////////////Varying////////////////////Varying//
#if (REALISTIC_CLOUDS == 0 && defined OVERWORLD)
	varying vec2 texCoord;
	varying vec3 sunVec, upVec, uSunVec, normal;
	varying vec4 color;
#endif

//Vertex Shader////////////Vertex Shader////////////Vertex Shader////////////Vertex Shader//
#ifdef VERTEX

	//Uniforms//

	#if (REALISTIC_CLOUDS == 0 && defined OVERWORLD)
		#if AA > 1
			uniform int frameCounter;
			uniform float viewWidth;
			uniform float viewHeight;
		#include "/lib/util/jitter.glsl"
		#endif

		#if MOUVEMENT_CAM > 0
			uniform float frameTimeCounter;
			uniform float onGroundSmooth;
		#endif

		uniform vec3 cameraPosition;
		uniform mat4 gbufferModelViewInverse;
	#endif

	//Program//
	void main(){
		#if (REALISTIC_CLOUDS == 0 && defined OVERWORLD)
			texCoord=(gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

			color = gl_Color;

			normal=normalize(gl_NormalMatrix * gl_Normal);

			upVec = normalize(gbufferModelView[1].xyz);
			uSunVec = GetuSunVec();
			sunVec = GetSunVec(uSunVec);

			vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
				 position.xz -= vec2(88.0);

			float height = position.y + cameraPosition.y;
			if (height > 193.0) position.y += 2.0;
			gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

				#if MOUVEMENT_CAM > 0
					gl_Position += vec4(0.03 * sin(frameTimeCounter * 3.0 * SPEED_MOOVE), 0.015 * cos(frameTimeCounter * 4.0 * SPEED_MOOVE), 0.0, 0.0) * gl_ProjectionMatrix * onGroundSmooth;
				#endif

				#if AA > 1
					gl_Position.xy=TAAJitter(gl_Position.xy, gl_Position.w);
				#endif
		#else

			gl_Position = vec4(0.0);

			return;
		#endif
	}

#endif

//Fragment Shader//////////Fragment Shader/////////Fragment Shader/////////Fragment Shader//
#ifdef FRAGMENT

	//Uniforms//
	#if (REALISTIC_CLOUDS == 0 && defined OVERWORLD)

		uniform float rainFactor;
		uniform float screenBrightness;
		uniform float viewWidth, viewHeight;
		uniform ivec2 eyeBrightnessSmooth;

		uniform vec3 cameraPosition;

		#ifdef SKY_VANILLA
			uniform vec3 skyColor;
			uniform vec3 fogColor;
		#endif

		uniform sampler2D texture;

		uniform mat4 gbufferProjectionInverse;
		uniform mat4 gbufferModelViewInverse;
		uniform mat4 shadowProjection;
		uniform mat4 shadowModelView;

		#if AA > 1
			uniform int frameCounter;
		#endif
	#endif

	//Common Variables//
	#if (REALISTIC_CLOUDS == 0 && defined OVERWORLD)
	float sunVisibility    =clamp00125(dot( sunVec,upVec) + 0.0625) * 8.0;
	float screenBrightness2=clamp01(screenBrightness);
	#endif

	//Includes//
	#if (REALISTIC_CLOUDS == 0 && defined OVERWORLD)
		#include "/lib/util/spaceConversion.glsl"
		#include "/lib/color/lightColor.glsl"
		#include "/lib/color/skyColor.glsl"

		#if AA > 1
			#include "/lib/util/jitter.glsl"
		#endif
	#endif

	//Program//
	void main(){

		#if (REALISTIC_CLOUDS == 0 && defined OVERWORLD)
			vec4 albedo = vec4(1.0, 1.0, 1.0, texture2D(texture, texCoord.xy).a);
			vec3 cloudTex = texture2D(texture, texCoord.xy).rgb;
			albedo.rgb = pow(albedo.rgb * cloudTex, vec3(2.2));

			float timeBrightnessS = 1.0 - dayFactor;
			      timeBrightnessS = 1.0 - pow2(timeBrightnessS);
			if (rainFactor < 1.0) albedo.rgb *= lightCol * sky_ColorSqrt * (0.5 + 0.25 * timeBrightnessS);
			float sunVisibility2 = pow2(sunVisibility);
			if (rainFactor > 0.0) {
				vec3 rainColor = pow2(weatherCol.rgb) * (0.001 + 0.03 * timeBrightnessS + 0.02 * sunVisibility2);
				albedo.rgb = mix(albedo.rgb, rainColor * cloudTex, rainFactor);
			}
			if (albedo.a > 0.1) {
				albedo.a = VANILLA_CLOUD_OPACITY;
				albedo.a *= albedo.a;
			}

			vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
			#if AA > 1
				vec3 viewPos = ScreenToView(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
			#else
				vec3 viewPos = ScreenToView(screenPos);
			#endif

			vec3 worldPos = ViewToPlayer(viewPos);
			float lWorldPos = max(abs(worldPos.x), abs(worldPos.z));
			float cloudDistance = 375.0;
			cloudDistance = clamp01((cloudDistance - lWorldPos) / cloudDistance);
			if (cloudDistance < 0.00001) discard;
			albedo.a *= min(cloudDistance * 3.0, 1.0);

			vec3 nViewPos = normalize(viewPos.xyz);
			float NdotVoU = dot(nViewPos, upVec);
			float NdotVoS = dot(nViewPos, sunVec);

			float scattering = 0.5 * sunVisibility2 * pow(NdotVoS * 0.5 * (2.0 * sunVisibility - 1.0) + 0.5, 6.0);
			scattering *= scattering;
			albedo.rgb *= 1.5 + scattering * (1.0 - rainFactor * 0.8);

			float absFactorP = min((1.0 - min(nightFactor, 0.6) / 0.6) * 0.215, 0.075);
			vec3 cloudColor = vec3(0.0);
			if (NdotVoS > 0.0) {
				float absNdotVoU = 1.0 - abs(NdotVoU);
				float absFactor = absFactorP * absNdotVoU * NdotVoS * absNdotVoU * 12.0 * (1.0 - rainFactor);
				cloudColor = mix(lightMorning, lightEvening, mefade);
				cloudColor *= pow4(cloudColor);
				cloudColor *= pow2(absFactor);
			}
			albedo.rgb += cloudColor * 0.25;

			float height = worldPos.y + cameraPosition.y;
			float cloudHeightFactor = 0.0;
			bool doFancyClouds = false;
			if (height < 134.0) {
				cloudHeightFactor = clamp(height - 127.85, 0.0, 6.0) / 6.0;
				doFancyClouds = true;
			} else if (height < 199.0 && height > 190.0) {
				cloudHeightFactor = clamp(height - 191.85, 0.0, 6.0) / 6.0;
				doFancyClouds = true;
			}
			if (doFancyClouds) {
				vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
				float shadowTime = abs(sunVisibility - 0.5) * 2.0;
				shadowTime *= shadowTime;
				lightVec *= shadowTime * shadowTime;
				float NdotL = clamp(dot(normal, lightVec) * 1.01 - 0.01, 0.0, 1.0);
				albedo.rgb *= 1.0 + NdotL * 0.25;

				cloudHeightFactor = pow(cloudHeightFactor, 2.0 - NdotL);

				cloudHeightFactor *= 1.0 + 3.0 * sqrt1(nightFactor) * (1.0 - rainFactor);

				float vanillaDiffuse = clampInv11(dot(normal, upVec));
				if (vanillaDiffuse > 0.0) albedo.rgb *= 1.0 - 0.25 * vanillaDiffuse;
				else albedo.rgb *= 1.0 + 0.05 * pow4(vanillaDiffuse);

				albedo.rgb *= 0.5 + (0.25 + 0.75 * (1.0 - rainFactor) * sunVisibility2) * cloudHeightFactor;
			} else {
				float vanillaDiffuse = clamp(0.25 * dot(normal, upVec) + 0.75, 0.5, 1.0);
				albedo.rgb *= vanillaDiffuse;
			}
			vec3 vlAlbedo = mix(vec3(1.0), albedo.rgb, sqrt1(albedo.a)) * (1.0 - pow(albedo.a, 64.0));
		#else
			discard;

			vec4 albedo = vec4(1.0);
			vec3 vlAlbedo = vec3(1.0);

		#endif

		/* RENDERTARGETS: 0,1 */
		#ifdef DEBUG_CLOUDS
            gl_FragData[0]=vec4(0.549, 0.0, 1.0, 0.75);
		#else
			gl_FragData[0] = clampVec4_01(albedo);
		#endif

		gl_FragData[1] = vec4(vlAlbedo, 1.0);

	}

#endif