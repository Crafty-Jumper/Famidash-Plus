extends Node2D

@onready var background: Sprite2D = $Background
@onready var camera_2d: Camera2D = $Camera2D
@onready var character_body_2d: CharacterBody2D = $CharacterBody2D
@onready var color_rect: ColorRect = $ColorRect
@onready var area_2d: Area2D = $Area2D
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var texture_progress_bar: TextureProgressBar = $Camera2D/Control/TextureProgressBar
@onready var checkpoints: Node2D = $Checkpoints
var camLock = 0
var freeCam : bool = false
var gamePause : bool = false
var practiceMode : bool = false
var checkpoint : PackedScene = load("uid://6qiilp7m3aai")
var coins : Array = [false,false,false]

const freeModes : Array = [0,4,8,9,10,11]

func _ready() -> void:
	Global.refreshed.connect(respawn_player)
	var level_save = Global.save_data["levels"].get(Global.levelName,{"normal":0,"practice":0,"coins":[false,false,false]})
	coins = level_save["coins"]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pause_management()
	camera_2d.position.x = character_body_2d.position.x + 48
	texture_progress_bar.value = (character_body_2d.position.x*6.1)/tile_map_layer.levelWidth
	if Input.is_action_just_pressed("select"):
		if checkpoints.get_children().size():
			checkpoints.get_child(checkpoints.get_children().size()-1).queue_free()
	if character_body_2d.gamemode == -1:
		if practiceMode:
			write_percent_practice()
		else:
			write_percent()
		if !practiceMode:
			Global.change_song("")
		return
	
	if character_body_2d.position.y < camera_2d.position.y-120:
		character_body_2d.die()
	if character_body_2d.position.y > camera_2d.position.y+120:
		character_body_2d.die()
	
	if practiceMode:
		if Input.is_action_just_pressed("B"):
			var new = checkpoint.instantiate()
			checkpoints.add_child(new)
	
	if !freeModes.has(character_body_2d.gamemode):
		if camera_2d.position.y != camLock and !freeCam:
			camera_2d.position.y = move_toward(camera_2d.position.y, camLock, 2)
	
	if freeModes.has(character_body_2d.gamemode):
		if camera_2d.position.y > character_body_2d.position.y + 56:
			camera_2d.position.y = character_body_2d.position.y + 56
		if camera_2d.position.y < character_body_2d.position.y - 56:
			camera_2d.position.y = character_body_2d.position.y - 56
	if camera_2d.position.y < 120:
		camera_2d.position.y = 120
	if camera_2d.position.y > tile_map_layer.levelHeight*16 - 72:
		camera_2d.position.y = tile_map_layer.levelHeight*16 - 72
	area_2d.position = camera_2d.position
	if camera_2d.position.x < get_viewport_rect().size.x/8:
		camera_2d.position.x = get_viewport_rect().size.x/8
	if camera_2d.position.x > tile_map_layer.levelWidth * 16 - get_viewport_rect().size.x/8:
		camera_2d.position.x = tile_map_layer.levelWidth * 16 - get_viewport_rect().size.x/8
	background.position.x = floor(fmod(camera_2d.position.x*-0.2,144)+camera_2d.position.x-144*5)
	background.position.y = floor(fmod(camera_2d.position.y*-0.2,72)+camera_2d.position.y-72*5)
	color_rect.position = background.position
	
	

func write_percent() -> void:
	var level_save = Global.save_data["levels"].get(Global.levelName,{"normal":0,"practice":0,"coins":[false,false,false]})
	if level_save["normal"] < texture_progress_bar.value:
		level_save["normal"] = texture_progress_bar.value
		Global.save_data["levels"][Global.levelName] = level_save
		Global.save_file()

func write_percent_practice() -> void:
	var level_save = Global.save_data["levels"].get(Global.levelName,{"normal":0,"practice":0,"coins":[false,false,false]})
	if level_save["practice"] < texture_progress_bar.value:
			level_save["practice"] = texture_progress_bar.value
			Global.save_data["levels"][Global.levelName] = level_save
			Global.save_file()

func respawn_player() -> void:
	if practiceMode:
		tile_map_layer.respawn_at_checkpoint()
	else:
		tile_map_layer.reset_level()

func pause_management() -> void:
	if Input.is_action_just_pressed("start"):
		gamePause = !gamePause
	if gamePause:
		character_body_2d.process_mode = Node.PROCESS_MODE_DISABLED
		Global.music.stream_paused = true
		if !Global.fadeIn:
			Global.sfx.stream_paused = true
			Global.fadeAmnt = 0.6
		else:
			return
		if Input.is_action_just_pressed("select"):
			Global.play_sfx(7)
			Global.sfx.stream_paused = false
			Global.fadeIn = true
			Global.fade_scene("res://scenes/level_select.tscn")
		if Input.is_action_just_pressed("B"):
			practiceMode = true
			gamePause = false
			Global.change_song("practice",true)
	else:
		character_body_2d.process_mode = Node.PROCESS_MODE_ALWAYS
		Global.music.stream_paused = false
		Global.sfx.stream_paused = false
