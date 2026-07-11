extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DiscordRich.set_activity("In the menu","Reading the help screen")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("B"):
		Global.fade_scene("uid://du82hjkyi5nln")
