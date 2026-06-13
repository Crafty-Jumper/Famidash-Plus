extends CanvasLayer

# save file
const savePath = "user://save.json"
var save_data : Dictionary = {
	"settings":[],
	"icons":[0,0,0,0,0,0,0,0,0,0,0,0],
	"funsettings":[],
	"levels":{
		"stereomadness":{
			"normal":69,
			"practice":42,
			"coins":[false,true,false]
		}
	}
}

var extraData : Variant = 0
var fade = ColorRect.new()
var music = AudioStreamPlayer.new()
var sfx = AudioStreamPlayer.new()
var fadeAmnt : float = 0.0
var fadeIn : bool = false
var newScene : bool = true
var new_scene : PackedScene = load("res://scenes/title.tscn")
var menuTheme : int = -1
var songName : String = ""
var songLoop : bool = false
signal refreshed
var levelName : String = "stereomadness"
var levelIdx : int = 0

# fun settings
var retro : bool = false
var blind : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_file()
	add_child(fade)
	add_child(music)
	add_child(sfx)
	music.stream = load("res://music/song_menu_theme.wav")
	fade.color = Color.BLACK
	fade.color.a = 0
	fade.size = Vector2(4000,4000)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if (!music.stream_paused) and !music.playing:
		if songLoop:
			music.play()
	fade_effect()
	if fadeIn and fadeAmnt > 1.5:
		if newScene:
			get_tree().change_scene_to_packed(new_scene)
		else:
			refreshed.emit()
		fadeIn = false

func fade_effect() -> void:
	fadeAmnt = clamp(fadeAmnt,0,10)
	if fadeIn:
		fadeAmnt += 0.1
	if !fadeIn:
		fadeAmnt -= 0.1
	fade.color.a = floor((fadeAmnt*3))/3

func change_song(song: String = "menu_theme",loop:bool=false):
	songLoop = loop
	songName = song
	if DirAccess.dir_exists_absolute("res://music/song_" + song):
		var name = "res://music/song_" + song + "/" + DirAccess.get_files_at("res://music/song_" + song)[randi_range(0,DirAccess.get_files_at("res://music/song_" + song).size()-1)]
		name = name.replace(".import","")
		music.stream = load(name)
		music.play()
		return
	music.stream = load("res://music/song_" + song + ".wav")
	music.play()

func play_sfx(id) -> void:
	if id is int:
		sfx.stream = load("res://sfx/" + str(id) + ".mp3")
	elif id is String:
		sfx.stream = load("res://sfx/" + id)
	sfx.play()

func fade_scene(scene:String, instant:bool = false, reload:bool = false,extradata:Variant=0) -> void:
	extraData = extradata
	newScene = !reload
	fadeIn = true
	new_scene = load(scene)
	if instant:
		fadeIn = false
		if !reload:
			get_tree().change_scene_to_packed(new_scene)
		else:
			refreshed.emit()

func save_file() -> void:
	var file = FileAccess.open(savePath,FileAccess.WRITE)
	file.store_var(save_data)
	file.close()

func load_file() -> void:
	if FileAccess.file_exists(savePath):
		var file = FileAccess.open(savePath,FileAccess.READ)
		save_data = file.get_var()
		file.close()
	else:
		save_file()
