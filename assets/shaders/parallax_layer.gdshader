shader_type canvas_item;

uniform sampler2D layer_texture : repeat_enable, filter_nearest;
uniform float scroll_speed : hint_range(0.0, 0.2) = 0.0;
uniform float tiles_across : hint_range(0.5, 10.0) = 1.0;

void fragment() {
	vec2 uv = vec2(UV.x * tiles_across + TIME * scroll_speed, UV.y);
	COLOR = texture(layer_texture, uv);
}
