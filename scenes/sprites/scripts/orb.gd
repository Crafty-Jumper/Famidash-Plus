extends Sprite2D

@onready var area_2d: Area2D = $Area2D
@export var speed: float = 284.942
@export var flipGrav: bool = false

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
			if !body.buffering:
				return
			activated = true
			body.buffering = false
			if flipGrav:
				body.velocity.y = -speed * body.flippedMult
				body.flipped = !body.flipped
			else:
				body.velocity.y = -speed * body.flippedMult

func blue() -> void:
	activated = false

func on_body_entered(body:Node2D) -> void:
	if activated:
		return
	if body.is_in_group("player"):
		if !body.buffering:
			return
		activated = true
		body.buffering = false
		if flipGrav:
			body.velocity.y = -speed * body.flippedMult
			body.flipped = !body.flipped
		else:
			body.velocity.y = -speed * body.flippedMult
