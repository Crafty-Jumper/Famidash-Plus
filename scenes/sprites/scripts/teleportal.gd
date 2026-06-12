extends Sprite2D

@onready var area_2d: Area2D = $Area2D
@export var orb = false
@export var y_off = 8
var activated : bool = false

func _ready() -> void:
	area_2d.body_entered.connect(on_body_entered)
	Global.refreshed.connect(blue)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if activated:
		return
	
	for body in area_2d.get_overlapping_bodies():
		if body.is_in_group("player"):
			if orb and !body.buffering:
				return
			activated = true
			body.teleport(0 if orb else body.velocity.y)

func on_body_entered(body:Node2D) -> void:
	if activated:
		return
	if body.is_in_group("player"):
		if orb and !body.buffering:
			return
		activated = true
		body.teleport(0 if orb else body.velocity.y, y_off)

func blue() -> void:
	activated = false
