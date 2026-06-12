extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.fadeAmnt = 1.5
	Global.change_song("scheming_weasel")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_anything_pressed():
		Global.fade_scene("res://scenes/credits.tscn")
