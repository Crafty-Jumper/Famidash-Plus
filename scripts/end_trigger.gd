extends Sprite2D

@onready var area_2d: Area2D = $Area2D
@onready var main : Node2D = $"../.."
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_2d.area_entered.connect(entered_screen)

func entered_screen(area: Area2D) -> void:
	if area.is_in_group("triggersNStuff"):
		Global.fade_scene("res://scenes/level_complete.tscn",true,false,{"practiceMode":main.practiceMode,"attempts":main.tile_map_layer.attempts,"jumps":0,"coins":main.coins})
		if get_parent().get_parent().practiceMode:
			write_percent_practice()
		else:
			write_percent()
		Global.play_sfx(2)

func write_percent() -> void:
	var level_save = Global.save_data["levels"].get(Global.levelName,{"normal":0,"practice":0,"coins":[false,false,false]})
	level_save["normal"] = 100
	Global.save_data["levels"][Global.levelName] = level_save
	Global.save_file()

func write_percent_practice() -> void:
	var level_save = Global.save_data["levels"].get(Global.levelName,{"normal":0,"practice":0,"coins":[false,false,false]})
	level_save["practice"] = 100
	Global.save_data["levels"][Global.levelName] = level_save
	Global.save_file()
