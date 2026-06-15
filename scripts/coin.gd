extends Sprite2D

@export var id = 0
@onready var level = get_parent().get_parent()
var velY : float = -5.0

var collected : bool = false

func _ready() -> void:
	$Area2D.body_entered.connect(detect)
	if level.coins[id]:
		frame_coords.y = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if collected:
		position.y += velY
		velY += 30 * delta

func detect(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect()

func collect() -> void:
	if level.practiceMode:
		return
	collected = true
	level.coins[id] = true
	Global.play_sfx(3)
	velY = -5.0
