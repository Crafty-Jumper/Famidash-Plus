extends Node2D

var robtop : bool = false
var robtopLvlCnt = 26
@onready var color_rect_2: ColorRect = $ColorRect2
var selected_level : bool = false

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
@onready var center_level: Node2D = $CenterLevel
@onready var left_level: Node2D = $LeftLevel
@onready var right_level: Node2D = $RightLevel

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
		if !selected_level:
			Global.fade_scene("uid://du82hjkyi5nln")
	
	if Input.is_action_just_pressed("A"):
		if !selected_level:
			selected_level = true
			Global.play_sfx(8)
			Global.change_song("")
			await Global.sfx.finished
			Global.fade_scene("uid://c0332ymehycxl")
	color_rect_2.material.set_shader_parameter("BG1",Global.get_color(fmod(Global.levelIdx,12)+17))
	center_level.position.x = lerp(center_level.position.x,0.0,delta * 12)
	left_level.position.x = center_level.position.x-get_viewport_rect().size.x/4
	right_level.position.x = center_level.position.x+get_viewport_rect().size.x/4
	
	if !selected_level:
		if Input.is_action_just_pressed("left"):
			Global.levelIdx -= 1
			left_level.position.x = -get_viewport_rect().size.x/2
			center_level.position.x = -get_viewport_rect().size.x/4
			right_level.position.x = 0
		if Input.is_action_just_pressed("right"):
			Global.levelIdx += 1
			left_level.position.x = 0
			center_level.position.x = get_viewport_rect().size.x/4
			right_level.position.x = get_viewport_rect().size.x/2
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
	
	
	if true:
		var data = get_level_data(Global.levelIdx-1)
		set_level_data(data,left_level)
		set_level_progress(left_level)
	if true:
		var data = get_level_data(Global.levelIdx+1)
		set_level_data(data,right_level)
		set_level_progress(right_level)
	if true:
		var data = get_level_data(Global.levelIdx)
		set_level_data(data)
		set_level_progress()

func get_level_data(index:int):
	var file = FileAccess.open("res://level_header.json",FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	json = JSON.parse_string(text)
	return json[clamp(index,0,json.size()-1)]

func set_level_data(data:Dictionary,node:Node2D=$CenterLevel):
	node.get_child(1).frame = difficulties.get(data["difficulty"],0)
	Global.levelName = data["level"]
	node.get_child(6).text = data.get("upperText","") + (" \n" if fmod(data.get("upperText","").length(),2) == 1 else "\n")
	node.get_child(6).text += data["lowerText"] + (" " if fmod(data["lowerText"].length(),2) == 1 else "")
	node.get_child(7).text = str(int(data["stars"]) if floor(data["stars"]) == data["stars"] else data["stars"])

func set_level_progress(node:Node2D=$CenterLevel) -> void:
	var level_save = Global.save_data["levels"].get(Global.levelName,{"normal":0,"practice":0,"coins":[false,false,false]})
	node.get_child(2).visible = level_save["normal"] >= 100
	node.get_child(3).value = level_save["normal"]
	node.get_child(8).text = str(int(ceil(level_save["normal"]))) + "%"
	node.get_child(4).value = level_save["practice"]
	node.get_child(9).text = str(int(ceil(level_save["practice"]))) + "%"
	node.get_child(11).region_rect.position.x = int(level_save["coins"][0])*8+8.0
	node.get_child(12).region_rect.position.x = int(level_save["coins"][1])*8+8.0
	node.get_child(13).region_rect.position.x = int(level_save["coins"][2])*8+8.0
