extends Sprite2D

@export var id = 0
@onready var level = get_parent().get_parent()
var velY : float = -5.0
var origPos : Vector2 = position
var collected : bool = false
@onready var animated_object: AnimatedObject = $AnimatedObject
var remove : bool = true

func _ready() -> void:
	var level_save = Global.save_data["levels"].get(Global.levelName,{"normal":0,"practice":0,"coins":[false,false,false]})
	origPos = position
	$Area2D.body_entered.connect(detect)
	Global.refreshed.connect(blue)
	if level_save["coins"][id]:
		frame_coords.y = 0
		animated_object.startFrame = frame
		remove = false

func blue() -> void:
	position = origPos
	collected = false
	if remove:
		level.coins[id] = false
	velY = -5.0

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
