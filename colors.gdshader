shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture;

uniform vec3 srcBG1 : source_color;
uniform vec3 srcBG2 : source_color;
uniform vec3 srcOBJ : source_color;
uniform vec3 srcGND1 : source_color;
uniform vec3 srcGND2 : source_color;

uniform vec3 BG1 : source_color;
uniform vec3 BG2 : source_color;
uniform vec3 OBJ : source_color;
uniform vec3 GND1 : source_color;
uniform vec3 GND2 : source_color;

void fragment() {
	vec4 original_color = texture(screen, SCREEN_UV);
	COLOR.rgba = original_color.rgba;
	
	if (original_color.rgb == srcBG1) {
		COLOR.rgb = BG1.rgb;
	};
	if (original_color.rgb == srcBG2) {
		COLOR.rgb = BG2.rgb;
	};
	if (original_color.rgb == srcOBJ) {
		COLOR.rgb = OBJ.rgb;
	};
	if (original_color.rgb == srcGND1) {
		COLOR.rgb = GND1.rgb;
	};
	if (original_color.rgb == srcGND2) {
		COLOR.rgb = GND2.rgb;
	};
}
