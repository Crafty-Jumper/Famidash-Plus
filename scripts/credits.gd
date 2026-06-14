extends Node2D

var canSkip : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if FileAccess.file_exists(Global.savePath):
		canSkip = true
	else:
		Global.save_file()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("A") and canSkip:
		Global.fade_scene("res://scenes/title.tscn")


func _on_timer_timeout() -> void:
	Global.fade_scene("res://scenes/title.tscn")
