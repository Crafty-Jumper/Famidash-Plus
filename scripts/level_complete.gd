extends Node2D

@onready var camera_2d: Camera2D = $Camera2D
var tween = create_tween()
var canInput : bool = false
var retray : bool = false
@onready var arrow: Sprite2D = $Arrow

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera_2d.position.y += 240
	tween.tween_property(camera_2d,"position",camera_2d.position-Vector2(0,240),2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !tween.is_running():
		canInput = true
	if !canInput:
		return
	arrow.visible = true
	if retray:
		arrow.position.x = 72.0
	else:
		arrow.position.x = 184.0
	
	
	if Input.is_action_just_pressed("left"):
		retray = !retray
	if Input.is_action_just_pressed("right"):
		retray = !retray
	
	if Input.is_action_just_pressed("A"):
		if retray:
			Global.play_sfx(8)
			canInput = false
			await Global.sfx.finished
			Global.fade_scene("res://scenes/level.tscn")
		else:
			Global.play_sfx(7)
			Global.fade_scene("res://scenes/level_select.tscn")
