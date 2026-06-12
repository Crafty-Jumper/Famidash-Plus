extends Node2D

var robtop : bool = false
var robtopLvlCnt = 26

const difficulties = {
	"AUTO":1,
	"EASY":2,
	"NORMAL":3,
	"HARD":4,
	"HARDER":5,
	"INSANE":6,
	"EASYDEMON":7,
	"MEDIUMDEMON":8,
	"DEMON":9,
	"HARDDEMON":9,
	"INSANEDEMON":10,
	"EXTREMEDEMON":11,
	"IMPOSSIBLEDEMON":12,
	"GRANDPADEMON":13
	}

@onready var banner_corner: Sprite2D = $BannerCorner
@onready var banner_corner_2: Sprite2D = $BannerCorner2
@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar
@onready var texture_progress_bar_2: TextureProgressBar = $TextureProgressBar2
@onready var normal_percent: Label = $NormalPercent
@onready var practice_percent: Label = $PracticePercent
@onready var sprite_2d_2: Sprite2D = $Sprite2D2

@onready var level_name: Label = $LevelName
@onready var star_count: Label = $StarCount
@onready var sprite_2d: Sprite2D = $Sprite2D
const menu_themes : Array = ["menu_theme","menu_b_sides","emeht_unem","menu_d_sides","menu_e_sides"]
var json

func _ready() -> void:
	set_level_data(get_level_data(0))
	robtop = Global.levelIdx <= robtopLvlCnt
	if Global.songName.contains("menu") or Global.songName.contains("unem"):
		return
	Global.change_song(menu_themes[Global.menuTheme],true)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	banner_corner.position.x = -get_viewport_rect().size.x/8
	banner_corner_2.position.x = get_viewport_rect().size.x/8
	if Input.is_action_just_pressed("B"):
		Global.fade_scene("res://scenes/title.tscn")
	
	if Input.is_action_just_pressed("A"):
		Global.play_sfx(8)
		Global.change_song("")
		await Global.sfx.finished
		Global.fade_scene("res://scenes/level.tscn")
	
	if Input.is_action_just_pressed("left"):
		Global.levelIdx -= 1
	if Input.is_action_just_pressed("right"):
		Global.levelIdx += 1
	if Global.levelIdx < 0:
		Global.levelIdx = robtopLvlCnt
	if Global.levelIdx > json.size()-1:
		Global.levelIdx = robtopLvlCnt+1
	if robtop:
		if Global.levelIdx > robtopLvlCnt:
			Global.levelIdx = 0
	else:
		if Global.levelIdx < robtopLvlCnt+1:
			Global.levelIdx = json.size()-1
	
	var data = get_level_data(Global.levelIdx)
	set_level_data(data)
	set_level_progress()

func get_level_data(index:int):
	var file = FileAccess.open("res://LEVELS/lvlset_HUGE_metadata.json",FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	json = JSON.parse_string(text)
	return json[index]

func set_level_data(data:Dictionary):
	sprite_2d.frame = difficulties.get(data["difficulty"],0)
	Global.levelName = data["level"]
	level_name.text = data.get("upperText","") + (" \n" if fmod(data.get("upperText","").length(),2) == 1 else "\n")
	level_name.text += data["lowerText"] + (" " if fmod(data["lowerText"].length(),2) == 1 else "")
	star_count.text = str(int(data["stars"]) if floor(data["stars"]) == data["stars"] else data["stars"])

func set_level_progress() -> void:
	var level_save = Global.save_data["levels"].get(Global.levelName,{"normal":0,"practice":0,"coins":[false,false,false]})
	sprite_2d_2.visible = level_save["normal"] >= 100
	texture_progress_bar.value = level_save["normal"]
	normal_percent.text = str(int(ceil(level_save["normal"]))) + "%"
	texture_progress_bar_2.value = level_save["practice"]
	practice_percent.text = str(int(ceil(level_save["practice"]))) + "%"
