#version 120

#define DRAW_SHADOW_MAP gcolor //Configures which buffer to draw to the screen [gcolor shadowcolor0 shadowtex0 shadowtex1]

uniform float frameTimeCounter;
uniform sampler2D gcolor;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;

varying vec2 texcoord;

void main() {
	vec3 screenPos = vec3(texcoord, texture2D(depthtex, texcoord).r);
	vec3 clipPos = screenPos * 2.0 - 1.0;
	vec4 tmp = gbufferProjectionInverse * vec4(clipPos, 1.0);
	vec3 viewPos = tmp.xyz / tmp.w;

	float density = 0.001; 
	float dst = length(viewPos);
	vec3 color = texture2D(DRAW_SHADOW_MAP, texcoord).rgb;

/* DRAWBUFFERS:0 */
	vec3 fogColor = vec3(1,1,1);
	gl_FragData[0]=mix(color,fogColor,exp(-dst * density));

}