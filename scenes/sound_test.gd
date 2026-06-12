extends Node2D

@onready var label: Label = $Label
@onready var label_2: Label = $Label2
@onready var label_3: Label = $Label3
@onready var banner_corner: Sprite2D = $BannerCorner
@onready var banner_corner_2: Sprite2D = $BannerCorner2

var song : int = 0
var currSong : Dictionary = {
		"song":"",
		"text":"",
		"originalArtist":"",
		"coveringArtists":""
	}
var music_meta = JSON.parse_string(FileAccess.open("res://music_data.json",FileAccess.READ).get_as_text())



func _process(delta: float) -> void:
	if Input.is_action_just_pressed("start"):
		music_meta = JSON.parse_string(FileAccess.open("res://music_data.json",FileAccess.READ).get_as_text())
	banner_corner.position.x = -get_viewport_rect().size.x/8
	banner_corner_2.position.x = get_viewport_rect().size.x/8
	if Input.is_action_just_pressed("B"):
		Global.fade_scene("res://scenes/title.tscn")
	if song >= music_meta.size():
		song = 0
	if song < 0:
		song = music_meta.size() - 1
	currSong = music_meta[song]
	if Input.is_action_just_pressed("A"):
		if Global.songName == currSong["song"]:
			Global.change_song("")
		else:
			Global.change_song(currSong["song"],true)
	if Input.is_action_just_pressed("left"):
		song -= 1
	if Input.is_action_just_pressed("right"):
		song += 1
	label.text = currSong.get("text","")
	original_artist()
	overingArtist()

func original_artist() -> void:
	if currSong.get("originalArtist","") is String:
		label_2.text = currSong.get("originalArtist","")
	if currSong.get("originalArtist","") is Array:
		label_2.text = ""
		for i in currSong.get("originalArtist","").size():
			label_2.text += (", " if i > 0 else "") + currSong.get("originalArtist",[])[i]

func overingArtist() -> void:
	if currSong.get("coveringArtist","") is String:
		label_3.text = currSong.get("coveringArtist","")
	if currSong.get("coveringArtist","") is Array:
		label_3.text = ""
		for i in currSong.get("coveringArtist","").size():
			label_3.text += (", " if i > 0 else "") + currSong.get("coveringArtist",[])[i]
