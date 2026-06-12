extends Area2D

@onready var color_rect: ColorRect = $"../ColorRect"
@onready var character_body_2d: CharacterBody2D = $"../CharacterBody2D"

var tpExitY = 0

const colors : Array = [
	"6B6B6B","001084","08008C","42007B","63005A","6B0010","600000","4F3500","314E18","005A21","215A10","085242","003973","000000","000000","000000",
	"A5A5A5","0042C6","4229CE","6B00BD","942994","9C1042","9C3900","845E21","5F7B21","2D8C29","188E10","2E8663","29739C","000000","000000","000000",
	"EFEFEF","5A8CFF","7B6BFF","A55AFF","D64AFF","E7639C","DE7B52","CE9C29","FFDA31","7BCE31","5ACE52","4AC694","4AB5CE","525252","000000","000000"]

signal bg_color(index)
signal gnd_color(index)
signal gravity_mod(mod:float)

func _on_bg_color(index) -> void:
	var secondary = index - 16
	if secondary < 0:
		secondary = 15
	color_rect.material.set_shader_parameter("BG1",Color("#" + colors[index]))
	DisplayServer.window_set_color(Color("#" + colors[index]))
	color_rect.material.set_shader_parameter("BG2",Color("#" + colors[secondary]))

func _on_gnd_color(index) -> void:
	var secondary = index - 16
	if secondary < 0:
		secondary = 15
	color_rect.material.set_shader_parameter("GND1",Color("#" + colors[index]))
	color_rect.material.set_shader_parameter("GND2",Color("#" + colors[secondary]))

func _on_gravity_mod(mod: float) -> void:
	character_body_2d.gravMult = mod
