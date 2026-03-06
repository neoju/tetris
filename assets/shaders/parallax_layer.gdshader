shader_type canvas_item;

uniform sampler2D layer_texture : repeat_enable, filter_nearest;
uniform float scroll_speed : hint_range(0.0, 0.2) = 0.0;

void fragment() {
	vec2 uv = vec2(UV.x + TIME * scroll_speed, UV.y);
	COLOR = texture(layer_texture, uv);
}
