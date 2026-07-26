extends Node2D

@onready var cursor: Sprite2D = $Cursor
@onready var parallax_1: Sprite2D = $Parallax1
@onready var ground: Sprite2D = $Ground

var scroll = 0
var selection = 1
const menu_themes : Array = ["menu_theme","menu_b_sides","emeht_unem","menu_d_sides","menu_e_sides"]
var selected : bool = false

func _ready() -> void:
	parallax_1.texture = load("res://spritesheets/parallax" + str(Global.background) + ".png")
	DiscordRich.set_activity("In the menu","On the title screen")
	Global.save_file()
	if Global.songName.contains("menu") or Global.songName.contains("unem"):
		return
	if Global.menuTheme == -1:
		if randi_range(1,256) == 1:
			Global.menuTheme = 4
		else:
			Global.menuTheme = randi_range(0,3)
	Global.change_song(menu_themes[Global.menuTheme],true)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("select"):
		Global.fade_scene("uid://c3b5iwtldunv3")
	scroll -= 120*delta
	if !Global.sfx.playing or !selected:
		parallax_1.position.x = round(fmod(scroll/6,parallax_1.texture.get_size().x))-parallax_1.texture.get_size().x
		ground.position.x = round(fmod(scroll,64))-128
	handle_cursor()
	
	if Input.is_action_just_pressed("A"):
		if selected:
			return
		if selection == 1:
			selected = true
			if randi_range(1,256) == 1:
				Global.play_sfx("fire.wav")
			else:
				Global.play_sfx("geometry-dash.wav")
			Global.music.stream_paused = true
			Global.levelIdx = 0
			await Global.sfx.finished
			Global.fade_scene("uid://ckrwwrc62vbnd")
			Global.music.stream_paused = false
			return
		
		if selection == 2:
			selected = true
			if randi_range(1,256) == 1:
				Global.play_sfx("gofuckyourself.wav")
			else:
				Global.play_sfx("fire.wav")
			Global.music.stream_paused = true
			Global.levelIdx = 27
			await Global.sfx.finished
			Global.fade_scene("uid://ckrwwrc62vbnd")
			Global.music.stream_paused = false
			return
	
		if selection == 3:
			selected = true
			Global.change_song("")
			Global.fade_scene("uid://ce55h62s85vjj")
			return
		
		if selection == 5:
			selected = true
			Global.fade_scene("uid://c0b2s7x4kdhbb")
			return
	
		if selection == 0:
			selected = true
			Global.fade_scene("uid://blfpe35rtmm2e")
			return
		
		Global.play_sfx(9)

func handle_cursor() -> void:
	if selected:
		return
	if Input.is_action_just_pressed("left"):
		selection -= 1
	if Input.is_action_just_pressed("right"):
		selection += 1
	if Input.is_action_just_pressed("up") or Input.is_action_just_pressed("down"):
		selection += 3
	selection = fmod(selection,6)
	if selection < -1:
		selection = 5
	if selection <= 2:
		cursor.position.x = 80 + selection * 48
		cursor.position.y = 96
		cursor.region_rect.position.x = 64
	if selection == -1:
		cursor.position = Vector2(224,16)
	if selection > 2:
		cursor.position.x = 80 + (selection - 3) * 48
		cursor.position.y = 152
		cursor.region_rect.position.x = 80
