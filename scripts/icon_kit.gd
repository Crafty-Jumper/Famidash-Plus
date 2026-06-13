extends Node2D


const menu_themes : Array = ["menu_theme","menu_b_sides","emeht_unem","menu_d_sides","menu_e_sides"]
var selected_icon : int = 0
@onready var selector: Sprite2D = $Selector
@onready var selectedicon: Sprite2D = $selectedicon


func _ready() -> void:
	if Global.songName.contains("menu") or Global.songName.contains("unem"):
		return
	if Global.menuTheme == -1:
		if randi_range(1,256) == 1:
			Global.menuTheme = 4
		else:
			Global.menuTheme = randi_range(0,3)
	Global.change_song(menu_themes[Global.menuTheme],true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	selectedicon.texture = load("res://player/cubes/cube" + str(Global.save_data["icons"][0]) + ".png")
	if Input.is_action_just_pressed("left"):
		selected_icon -= 1
	if Input.is_action_just_pressed("right"):
		selected_icon += 1
	if Input.is_action_just_pressed("up"):
		selected_icon -= 8
	if Input.is_action_just_pressed("down"):
		selected_icon += 8
	selector.position.x = fmod(selected_icon,8)*16-56
	selector.position.y = selected_icon/8*16+136.0
	if Input.is_action_just_pressed("A"):
		Global.save_data["icons"][0] = selected_icon
	if Input.is_action_just_pressed("B"):
		Global.fade_scene("res://scenes/title.tscn")
