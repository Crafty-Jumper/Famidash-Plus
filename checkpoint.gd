extends Sprite2D

var player_vel = Vector2(0,0)
var song_pos = 0.0
var player_mode : int = 0
var player_speed : int = 0
var bg_col : int = 0
var gnd_col : int = 0
var obj_col : int = 0
var spawn_time = 0
@onready var character_body_2d : CharacterBody2D = $"../../CharacterBody2D"

func _ready() -> void:
	spawn_time = Time.get_ticks_msec()
	player_vel = character_body_2d.velocity
	position = character_body_2d.position
	player_mode = character_body_2d.gamemode
	player_speed = character_body_2d.speedIdx
	song_pos = Global.music.get_playback_position()
