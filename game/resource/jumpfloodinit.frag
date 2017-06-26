
vec4 effect( vec4 color, sampler2D texture, vec2 uv, vec2 coord ) {
	vec4 trail = texture2D(texture, uv);

    if (trail.x == 1.0)
        return vec4(coord, 0.0, 1.0);
    else
        return vec4(-65000.0, -65000.0, 0.0, 1.0);
}