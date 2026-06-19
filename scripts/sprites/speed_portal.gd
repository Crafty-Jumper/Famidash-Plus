extends Sprite2D

@onready var area_2d: Area2D = $Area2D

@export var speed = 0

func _process(_delta: float) -> void:
	for body in area_2d.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.speedIdx = speed
