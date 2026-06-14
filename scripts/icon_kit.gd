extends Node2D


const menu_themes : Array = ["menu_theme","menu_b_sides","emeht_unem","menu_d_sides","menu_e_sides"]

@onready var selector: Sprite2D = $Selector
@onready var selectedicon: Sprite2D = $selectedicon
@onready var canvas_group: CanvasGroup = $CanvasGroup
@onready var banner_corner: Sprite2D = $BannerCorner
@onready var banner_corner_2: Sprite2D = $BannerCorner2
@onready var color_rect: ColorRect = $ColorRect
@onready var color_rect_3: ColorRect = $ColorRect3

@onready var colors: Sprite2D = $Colors
@onready var colors_2: Sprite2D = $Colors2
@onready var colors_3: Sprite2D = $Colors3
@onready var color_selector: Sprite2D = $ColorSelector
@onready var label_2: Label = $Label2
var hovered_color : int = 0

var max_icons = 0
var icon_meta = JSON.parse_string(FileAccess.open("res://icons.json",FileAccess.READ).get_as_text())

var selected_icon : int = 0
var menu_state : int = 1
const gamemode_frames = [7,5,4,1,3,5,5,5,1,7,2,3,7]
const gamemode_frame_idx = [0,2,0,0,1,1,0,2,0,0,0,1,0]
const gamemode_names = ["cube","ship","ball","ufo","wave","robot","spider","swing","jetpack","ninja","pogo","snake","football"]
var gamemode = 0
var hovered_gamemode = 0

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
	
	colors.self_modulate = Global.get_color(Global.save_data["colors"][0])
	colors_2.self_modulate = Global.get_color(Global.save_data["colors"][1])
	colors_3.self_modulate = Global.get_color(Global.save_data["colors"][2])
	
	banner_corner.position.x = get_viewport_rect().size.x/-8
	banner_corner_2.position.x = get_viewport_rect().size.x/8
	color_rect.position.x = get_viewport_rect().size.x/-8
	color_rect.size.x = get_viewport_rect().size.x/4
	selectedicon.texture = load("res://player/" + gamemode_names[gamemode] + "s/" + gamemode_names[gamemode] + str(Global.save_data["icons"][gamemode]) + ".png")
	selectedicon.hframes = gamemode_frames[gamemode]
	selectedicon.frame = gamemode_frame_idx[gamemode]
	if gamemode == 5 or gamemode == 6:
		selectedicon.offset.x = -4
	else:
		selectedicon.offset.x = 0
	manage_cursor()
	update_icon_list(gamemode_names[gamemode])
	
	
	if Input.is_action_just_pressed("B"):
		Global.fade_scene("res://scenes/title.tscn")
	

func update_icon_list(mode:String = "cube",frame=0) -> void:
	for i in canvas_group.get_children().size():
		var icon : Sprite2D = canvas_group.get_child(i)
		if gamemode == 5 or gamemode == 6:
			icon.offset.x = -4
		else:
			icon.offset.x = 0
		if FileAccess.file_exists("res://player/" + mode + "s/" + mode + str(int(floor(selected_icon/16.0)*16 + i)) + ".png"):
			icon.texture = load("res://player/" + mode + "s/" + mode + str(int(floor(selected_icon/16.0)*16 + i)) + ".png")
			icon.frame = icon_meta[int(floor(selected_icon/16.0)*16 + i)]["previewFrame"]
			icon.frame = gamemode_frame_idx[gamemode]
			icon.hframes = gamemode_frames[gamemode]
		else:
			icon.texture = Texture.new()
		if !FileAccess.file_exists("res://player/" + mode + "s/" + mode + str(int(floor(selected_icon/16.0)*16 + i)) + ".png"):
			if max_icons == 0:
				max_icons = int(floor(selected_icon/16.0)*16 + i)-1
				selected_icon = int(floor(selected_icon/16.0)*16 + i)-1

func manage_cursor() -> void:
	selector.visible = true
	color_selector.visible = false
	label_2.visible = false
	color_rect_3.position.x = gamemode * 16 - 102
	if menu_state == 0:
		selector.position.x = hovered_gamemode * 16 - 96
		selector.position.y = 96
		selector.region_rect.position.x = 64
		if Input.is_action_just_pressed("A"):
			change_page(hovered_gamemode)
		if Input.is_action_just_pressed("left"):
			hovered_gamemode -= 1
		if Input.is_action_just_pressed("right"):
			hovered_gamemode += 1
		if Input.is_action_just_pressed("down"):
			menu_state = 1
			return
	elif menu_state == 1:
		selector.region_rect.position.x = 80
		selector.position.x = fmod(selected_icon,8)*16-56
		selector.position.y = fmod(floor(selected_icon/8.0),2)*16+136.0
		if Input.is_action_just_pressed("A"):
			Global.save_data["icons"][gamemode] = selected_icon
		if Input.is_action_just_pressed("left"):
			if fmod(selected_icon,8) == 0:
				selected_icon -= 8
			selected_icon -= 1
		if Input.is_action_just_pressed("right"):
			if fmod(selected_icon,8) == 7:
				selected_icon += 8
			selected_icon += 1
		if Input.is_action_just_pressed("up"):
			if fmod(selected_icon,16) > 7:
				selected_icon -= 8
			else:
				menu_state = 0
		if Input.is_action_just_pressed("down"):
			if fmod(selected_icon,16) < 8:
				selected_icon += 8
			else:
				menu_state = 2
		if selected_icon < 0:
			selected_icon = 0
		if selected_icon > max_icons and max_icons != 0:
			selected_icon = max_icons
	elif menu_state == 2:
		selector.visible = false
		color_selector.visible = true
		label_2.visible = true
		color_selector.position.x = 48 * hovered_color - 48
		if Input.is_action_just_pressed("left"):
			if hovered_color == 0:
				menu_state = 1
			else:
				hovered_color -= 1
		if Input.is_action_just_pressed("right"):
			if hovered_color == 2:
				menu_state = 1
			else:
				hovered_color += 1
		if Input.is_action_just_pressed("up"):
			Global.save_data["colors"][hovered_color] += 1
		if Input.is_action_just_pressed("down"):
			Global.save_data["colors"][hovered_color] -= 1
		wrap(Global.save_data["colors"][hovered_color],0,Global.colors.size()-1)
	
	
func change_page(mode:int=0):
	max_icons = 0
	gamemode = mode
	selected_icon = Global.save_data["icons"][mode]
