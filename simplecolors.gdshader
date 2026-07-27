shader_type canvas_item;

uniform vec4 s1 : source_color;
uniform vec4 s2 : source_color;
uniform vec4 s3 : source_color;
uniform vec4 r1 : source_color;
uniform vec4 r2 : source_color;
uniform vec4 r3 : source_color;

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	
	if (original_color == s1) {
		COLOR = r1;
	}
	if (original_color == s2) {
		COLOR = r2;
	}
	if (original_color == s3) {
		COLOR = r3;
	}
}
