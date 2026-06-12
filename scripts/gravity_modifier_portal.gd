extends Sprite2D

@onready var area_2d: Area2D = $Area2D

@export var modifier : float = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_2d.body_entered.connect(on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	for body in area_2d.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.gravMult = modifier

func on_body_entered(body:Node2D) -> void:
	if body.is_in_group("player"):
		body.gravMult = modifier
