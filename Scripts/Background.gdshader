shader_type canvas_item;

uniform float scroll_speed = 0.1;
uniform float game_time = 0.0;

void fragment() {
	float offset_x = game_time * scroll_speed;
	vec2 scrolled_uv = vec2(UV.x + offset_x, UV.y);
	COLOR = texture(TEXTURE, fract(scrolled_uv));
}


