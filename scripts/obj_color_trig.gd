extends Sprite2D

@onready var area_2d: Area2D = $Area2D

@export var index : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_2d.area_entered.connect(entered_screen)

func entered_screen(area: Area2D) -> void:
	if area.is_in_group("triggersNStuff"):
		area.color_rect.material.set_shader_parameter("OBJ",Global.get_color(index))
