extends Sprite2D

@onready var area_2d: Area2D = $Area2D
@export var gamemode : int = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	for body in area_2d.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.gamemode = gamemode
			body.level.camLock = position.y + 16
