// This is in UV space
uniform int step;
uniform sampler2D trailTex;

// screenX, screenY, set


vec4 effect( vec4 color, sampler2D texture, vec2 uv, vec2 screenCoord ) {
	vec2 screenUV = screenCoord / love_ScreenSize.xy;
	float sourceSet = texture2D(trailTex, uv).x;

	float bestDistance = 99999999.0;
	vec2 bestCoord = vec2(-65000, -65000);
	for (int y = -1; y <= 1; ++y) {
    	for (int x = -1; x <= 1; ++x) {
        	vec2 sampleUV = (screenCoord + vec2(x,y)*step) / love_ScreenSize.xy;
		    vec2 candidateCoord = texture2D(texture, sampleUV).xy;
            float distance = length(candidateCoord.xy - screenCoord);
            if ((candidateCoord.x >= 0.0) && (distance < bestDistance)) {
                bestDistance = distance;
                bestCoord = candidateCoord.xy;
            }
        }
    }

    return vec4(bestCoord, 0.0, 1.0);
}