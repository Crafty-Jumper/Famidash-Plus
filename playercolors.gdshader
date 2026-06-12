shader_type canvas_item;

uniform vec4 outline : source_color;
uniform vec4 col1 : source_color;
uniform vec4 col2 : source_color;

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	
	COLOR = ((original_color.r * outline) + (original_color.g * col1) + (original_color.b * col2));
	COLOR.a = original_color.a;
}
