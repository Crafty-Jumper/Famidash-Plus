shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture;

uniform vec4 srcBG1 : source_color;
uniform vec4 srcBG2 : source_color;
uniform vec4 srcOBJ : source_color;
uniform vec4 srcGND1 : source_color;
uniform vec4 srcGND2 : source_color;

uniform vec4 BG1 : source_color;
uniform vec4 BG2 : source_color;
uniform vec4 OBJ : source_color;
uniform vec4 GND1 : source_color;
uniform vec4 GND2 : source_color;

void fragment() {
	vec4 original_color = texture(screen, SCREEN_UV);
	COLOR.rgba = original_color.rgba;
	if (original_color.a == 0.0) {
		COLOR.a = 0.0;
	}
	if (original_color.rgba == srcBG1) {
		COLOR.rgba = BG1.rgba;
	};
	if (original_color.rgba == srcBG2) {
		COLOR.rgba = BG2.rgba;
	};
	if (original_color.rgba == srcOBJ) {
		COLOR.rgba = OBJ.rgba;
	};
	if (original_color.rgba == srcGND1) {
		COLOR.rgba = GND1.rgba;
	};
	if (original_color.rgba == srcGND2) {
		COLOR.rgba = GND2.rgba;
	};
}
