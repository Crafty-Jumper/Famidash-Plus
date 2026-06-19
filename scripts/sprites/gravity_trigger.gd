extends Sprite2D

@export var modifier : float = 1
@onready var area_2d: Area2D = $Area2D

func _ready() -> void:
	area_2d.area_entered.connect(entered_screen)

func entered_screen(area: Area2D) -> void:
	if area.is_in_group("triggersNStuff"):
		area.gravity_mod.emit(modifier)
