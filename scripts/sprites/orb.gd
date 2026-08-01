extends Sprite2D

@onready var area_2d: Area2D = $Area2D
@export var color: String = "yellow"
@export var flipGrav: bool = false

var activated : bool = false

@onready var player : CharacterBody2D = $"../../CharacterBody2D"

func _ready() -> void:
	Global.refreshed.connect(blue)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
		if area_2d.overlaps_body(player):
			if !player.buffering:
				return
			if abs(player.position.y) * player.flippedMult > 0:
				player.position.y -= player.velocity.y * delta
			activated = true
			player.buffering = false
			if flipGrav:
				player.velocity.y = player.physicsTable["orbs"][color] * player.flippedMult
				player.flipped = !player.flipped
			else:
				player.velocity.y = -player.physicsTable["orbs"][color] * player.flippedMult

func blue() -> void:
	activated = false
