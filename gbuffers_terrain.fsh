#version 120

#define COLORED_SHADOWS 1 //0: Stained glass will cast ordinary shadows. 1: Stained glass will cast colored shadows. 2: Stained glass will not cast any shadows. [0 1 2]
#define SHADOW_BRIGHTNESS 0.75 //Light levels are multiplied by this number when the surface is in shadows [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
// is this important? ^
uniform sampler2D lightmap;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D texture;
uniform sampler2D colortex4;
uniform vec3 shadowLightPosition;
uniform int worldTime;
uniform sampler2D specular;
uniform vec3 skyColor;


varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec4 shadowPos;
varying vec3 normals; 
varying vec4 viewPos;

const int shadowMapResolution = 1024; //Resolution of the shadow map. Higher numbers mean more accurate shadows. [128 256 512 1024 2048 4096 8192]

//fix artifacts when colored shadows are enabled
const bool shadowcolor0Nearest = true;
const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;
	vec2 lm = lmcoord;
	vec3 shadowColor = vec3(1.0); 
	if (shadowPos.w > 0.0) { //this?
		//surface is facing towards shadowLightPosition
		#if COLORED_SHADOWS == 0
			//for normal shadows, only consider the closest thing to the sun,
			//regardless of whether or not it's opaque.
			if (texture2D(shadowtex0, shadowPos.xy).r < shadowPos.z) {
		#else
			//for invisible and colored shadows, first check the closest OPAQUE thing to the sun.
			if (texture2D(shadowtex1, shadowPos.xy).r < shadowPos.z) {
		#endif
			//surface is in shadows. reduce light level.
			shadowColor *= 0.0; 
		}
		else {
			#if COLORED_SHADOWS == 1
				//when colored shadows are enabled and there's nothing OPAQUE between us and the sun,
				//perform a 2nd check to see if there's anything translucent between us and the sun.
				if (texture2D(shadowtex0, shadowPos.xy).r < shadowPos.z) {
					//surface has translucent object between it and the sun. modify its color.
					//if the block light is high, modify the color less.
					vec4 shadowLightColor = texture2D(shadowcolor0, shadowPos.xy);
					
					//apply the color.
					shadowColor *= shadowLightColor.rgb;
				}
			#endif
		}
	}


	
	color *= texture2D(lightmap, lm);
	vec3 dayColor = texture2D(colortex4, vec2(float(worldTime) / 24000.0, 0.5)).rgb; // Day color 
	dayColor /= vec3(2.0);
	vec3 norm = normalize(normals);
	vec3 lightNormal = normalize(shadowLightPosition);
	float diff = max(dot(norm, lightNormal), 0.1); 
	vec3 diffuse = diff * dayColor * shadowColor; 
	float smoothness = texture2D(specular, texcoord).r;
	float specularStrength = 0.20; //do not go above 1 or under 0
	smoothness = exp(smoothness * specularStrength);
	vec3 viewDir = -normalize(viewPos.xyz);
	vec3 reflectDir = reflect(-lightNormal, norm);
    vec3 HalfwayVector = normalize(viewDir + lightNormal);
	float spec = pow(max(dot(HalfwayVector, norm), 0.0), smoothness) * (smoothness + 8.0) / (8.0 * 3.14159);
	vec3 wee = diffuse + spec;
	vec3 ambientThing = skyColor * lm.y * SHADOW_BRIGHTNESS * color.rgb;
	vec3 blockLight = vec3(1.0, 0.7, 0.3) * lm.x * color.rgb;
	color.rgb = color.rgb * diffuse + diffuse * spec + ambientThing + blockLight;
	


/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}