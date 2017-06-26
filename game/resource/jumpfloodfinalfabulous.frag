// screenX, screenY, set

uniform float time;
uniform float cutoff;
uniform float blur;
uniform vec2  centreCoord;
uniform float radius;

float smin(float x, float y)
{
	const float k = 1.0;
	return -log(exp(-k*x) + exp(-k*y))/k;
}

vec4 effect( vec4 color, sampler2D texture, vec2 uv, vec2 screenCoord ) {
	float maxDistance = length(love_ScreenSize.xy);
	vec2 bestCoord = texture2D(texture, uv).xy;
	float d1 = (bestCoord.x >= 0.0) ? length(bestCoord - screenCoord) : 0.0;
	float d2 = clamp(length(screenCoord - centreCoord) - radius, 0.0, 999999.0);
	//float distance = smin(d1, d2);
	//float distance = smin(d1, d2);
	float distance = smin(d1, d2);
	float scaled = distance * 0.01;

	float h = scaled - time;
    vec3 rgb = clamp(abs(mod(h*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    rgb = mix( rgb, vec3(1.0), 1.0-smoothstep(0.0,0.02,abs(scaled)) );

	rgb *= (1 - smoothstep(cutoff, cutoff+blur, distance));

    return vec4(color.xyz * rgb, 1.0);
}