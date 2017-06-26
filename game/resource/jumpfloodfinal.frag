
uniform float cutoff;
uniform float blur;

vec4 effect( vec4 color, sampler2D texture, vec2 uv, vec2 screenCoord ) {
	float distance = texture2D(texture, uv).z;

	return color * (1 - smoothstep(cutoff, cutoff+blur, distance));
}