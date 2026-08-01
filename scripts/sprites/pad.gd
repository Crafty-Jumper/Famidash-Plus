extends Sprite2D

@onready var area_2d: Area2D = $Area2D
@export var speed: float = 284.942
@export var flipGrav: bool = false
@export var one_shot: bool = false
var activated : bool = false

func _ready() -> void:
	#area_2d.body_entered.connect(on_body_entered)
	Global.refreshed.connect(blue)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	for body in area_2d.get_overlapping_bodies():
		if body.is_in_group("player"):
			if activated and one_shot:
				return
			if flipGrav:
				if (!body.flipped and area_2d.position.y > 8) or (body.flipped and area_2d.position.y < 8):
					body.velocity.y = -speed * body.flippedMult
					body.flipped = !body.flipped
			else:
				body.velocity.y = -speed * body.flippedMult
			activated = true

func blue() -> void:
	activated = false

func on_body_entered(body:Node2D) -> void:
	if body.is_in_group("player"):
		if activated and one_shot:
			return
		if flipGrav:
			if (!body.flipped and area_2d.position.y > 8) or (body.flipped and area_2d.position.y < 8):
				body.velocity.y = -speed * body.flippedMult
				body.flipped = !body.flipped
		else:
			body.velocity.y = -speed * body.flippedMult / (1.5 if body.gamemode == 2 else 1.0)
		activated = true
