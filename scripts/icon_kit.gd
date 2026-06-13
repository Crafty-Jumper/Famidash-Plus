extends Node2D


const menu_themes : Array = ["menu_theme","menu_b_sides","emeht_unem","menu_d_sides","menu_e_sides"]
var selected_icon : int = 0
@onready var selector: Sprite2D = $Selector
@onready var selectedicon: Sprite2D = $selectedicon
@onready var canvas_group: CanvasGroup = $CanvasGroup
@onready var banner_corner: Sprite2D = $BannerCorner
@onready var banner_corner_2: Sprite2D = $BannerCorner2
@onready var color_rect: ColorRect = $ColorRect
var max_icons = 0

func _ready() -> void:
	selected_icon = Global.save_data.get("icons",[0,0,0,0,0,0,0,0,0,0,0,0])[0]
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
	banner_corner.position.x = get_viewport_rect().size.x/-8
	banner_corner_2.position.x = get_viewport_rect().size.x/8
	color_rect.position.x = get_viewport_rect().size.x/-8
	color_rect.size.x = get_viewport_rect().size.x/4
	selectedicon.texture = load("res://player/cubes/cube" + str(Global.save_data["icons"][0]) + ".png")
	if Input.is_action_just_pressed("left"):
		if fmod(selected_icon,8) == 0:
			selected_icon -= 8
		selected_icon -= 1
	if Input.is_action_just_pressed("right"):
		if fmod(selected_icon,8) == 7:
			selected_icon += 8
		selected_icon += 1
	if Input.is_action_just_pressed("up"):
		selected_icon -= 8
	if Input.is_action_just_pressed("down"):
		selected_icon += 8
	if selected_icon < 0:
		selected_icon = 0
	if selected_icon > max_icons and max_icons != 0:
		selected_icon = max_icons
	update_icon_list()
	
	if Input.is_action_just_pressed("A"):
		Global.save_data["icons"][0] = selected_icon
	if Input.is_action_just_pressed("B"):
		Global.fade_scene("res://scenes/title.tscn")
	

func update_icon_list() -> void:
	selector.position.x = fmod(selected_icon,8)*16-56
	selector.position.y = fmod(floor(selected_icon/8.0),2)*16+136.0
	for i in canvas_group.get_children().size():
		var icon : Sprite2D = canvas_group.get_child(i)
		icon.texture = load("res://player/cubes/cube" + str(int(floor(selected_icon/16.0)*16 + i)) + ".png")
		if !FileAccess.file_exists("res://player/cubes/cube" + str(int(floor(selected_icon/16.0)*16 + i)) + ".png"):
			if max_icons == 0:
				max_icons = int(floor(selected_icon/16.0)*16 + i)-1
				selected_icon = int(floor(selected_icon/16.0)*16 + i)-1
