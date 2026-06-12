extends TileMapLayer

var index = 0
var tilePosX = 0
var tilePosY = 0
var levelString = ""
var spriteString = ""
var ohgodthelag : Dictionary = {}
var levelPath = "res://LEVELS/" + Global.levelName + ".tmx"
@onready var camera_2d: Camera2D = $"../Camera2D"
var levelWidth = 0
var levelHeight = 0
@onready var sprites: Node2D = $"../Sprites"
@onready var character_body_2d: CharacterBody2D = $"../CharacterBody2D"
@onready var area_2d: Area2D = $"../Area2D"
@onready var node_2d: Node2D = $".."
@onready var checkpoints: Node2D = $"../Checkpoints"

func _ready() -> void:
	for i in JSON.parse_string(FileAccess.open("res://LEVELS/lvlset_HUGE_metadata.json",FileAccess.READ).get_as_text()):
		if i["level"] == Global.levelName:
			ohgodthelag = i
			break
	var atlas_source = tile_set.get_source(0) as TileSetAtlasSource
	var spikeSet = ohgodthelag["spikeSet"]
	var blockSet = ohgodthelag["blockSet"]
	if FileAccess.file_exists("res://tiles/" + blockSet + spikeSet + ".png"):
		atlas_source.texture = load("res://tiles/" + blockSet + spikeSet + ".png")
	levelWidth = int(get_layer_property(levelPath,"","width"))
	levelHeight = int(get_layer_property(levelPath,"","height"))
	levelString = get_layer(levelPath,"")
	spriteString = get_layer(levelPath,"SP")
	levelString = levelString.replace("\n","")
	for i in 30:
		if tilePosX >= levelWidth:
			return
		for j in levelHeight:
			_place_tiles()
			if tilePosY > levelHeight:
				continue
			_place_sprites()

func reset_level() -> void:
	character_body_2d.gravMult = 1
	camera_2d.position.y = levelHeight*16 - 72
	character_body_2d.sprite_2d.position.y = 0
	character_body_2d.flipped = false
	character_body_2d.velocity = Vector2.ZERO
	character_body_2d.position.x = 8
	character_body_2d.position.y = 16*(levelHeight-1)+8
	character_body_2d.speedIdx = ohgodthelag["startingSpeed"]
	character_body_2d.gamemode = ohgodthelag["startingGameMode"]
	character_body_2d.sprite_2d.show()
	camera_2d.position.y = levelHeight*16 - 72
	area_2d.bg_color.emit(ohgodthelag["startingBackgroundColor"])
	area_2d.gnd_color.emit(ohgodthelag["startingGroundColor"])
	if !node_2d.practiceMode:
		Global.change_song(ohgodthelag["songID"].replace("song_",""))
	node_2d.camLock = camera_2d.position.y

func respawn_at_checkpoint() -> void:
	var checkpoint = checkpoints.get_child(checkpoints.get_children().size()-1)
	if checkpoint == null:
		reset_level()
		return
	
	character_body_2d.sprite_2d.position.y = 0
	character_body_2d.flipped = false
	character_body_2d.sprite_2d.show()
	
	character_body_2d.velocity = checkpoint.player_vel
	character_body_2d.position = checkpoint.position
	character_body_2d.speedIdx = checkpoint.player_speed
	character_body_2d.gamemode = checkpoint.player_mode

func place_tile_column() -> void:
	if tilePosX == 30:
		reset_level()
	if tilePosX >= levelWidth:
		return
	for i in levelHeight:
		_place_tiles()
		if tilePosY > levelHeight:
			continue
		_place_sprites()

func _process(_delta: float) -> void:
	visible = !Global.blind
	if tilePosX < levelWidth:
		place_tile_column()

func _place_tiles() -> void:
	if tilePosX >= levelWidth:
		levelString = ""
		return
	if tilePosY >= levelHeight+3:
		tilePosY = -1
		tilePosX += 1
	var tileID : int = int((levelString.get_slice(",",index)))-1
	var tilePos = Vector2i(0,0)
	index = (tilePosY+1) * levelWidth + tilePosX
	# ok
	# add ground
	if tilePosY > levelHeight:
		if fmod(tilePosX,4) == 0:
			tileID = 2
		else:
			tileID = 6
	if tilePosY == levelHeight:
		if fmod(tilePosX,4) == 0:
			tileID = 136
		else:
			tileID = 137
	tilePos = Vector2i(fmod(tileID,16),floor(tileID/16))
	set_cell(Vector2i(tilePosX,tilePosY),0,tilePos)
	tilePosY += 1

func _place_sprites() -> void:
	var tileID : int = int((spriteString.get_slice(",",index)))-1
	var tilePos = Vector2i(tilePosX*16,(tilePosY)*16)
	
	if !FileAccess.file_exists("res://scenes/sprites/" + str(tileID-256) + ".tscn"):
		return
	
	if tileID > 255:
		var sprite = load("res://scenes/sprites/" + str(tileID-256) + ".tscn")
		var spriteNode = sprite.instantiate()
		spriteNode.position = Vector2(tilePos) + get_sprite_offset(Vector2i(tilePosX,tilePosY))
		
		$"../Sprites".add_child(spriteNode)
	
	if tilePosY >= levelHeight:
		return

func get_sprite_offset(pos:Vector2i=Vector2i(0,0)) -> Vector2:
	var offsetX = 0
	var offsetY = 0
	
	var array = [float(pos.x),float(pos.y)]
	
	for i:Dictionary in ohgodthelag.get("objectOffsets",[]):
		if i.get("coordinates") == null:
			return Vector2(0,0)
		if i["coordinates"][0] is float:
			if i["coordinates"] == array:
				offsetX = i.get("offsetX",0)
				offsetY = i.get("offsetY",0)
				return Vector2(offsetX,offsetY)
		else:
			if i["coordinates"].has(array):
				offsetX = i.get("offsetX",0)
				offsetY = i.get("offsetY",0)
				return Vector2(offsetX,offsetY)
	
	return Vector2(offsetX,offsetY)

func get_layer(file:String,layer:String) -> String:
	var tmxfile = XMLParser.new()
	var error = tmxfile.open(file)
	
	if !error == OK:
		return "i got nothin"
	
	var encoding = ""
	var layerFound = false
	
	var currentNode = ""
	
	while tmxfile.read() == OK:
		match tmxfile.get_node_type():
			XMLParser.NODE_ELEMENT:
				currentNode = tmxfile.get_node_name()
				if currentNode == "layer":
					if tmxfile.has_attribute("height") and tmxfile.get_named_attribute_value("name") == layer:
						layerFound = true
				if currentNode == "layer":
					if tmxfile.has_attribute("height") and !tmxfile.has_attribute("name"):
						if layer == "":
							layerFound = true
				if layerFound:
					if tmxfile.get_node_name() == "data":
						encoding = tmxfile.get_named_attribute_value("encoding")
			XMLParser.NODE_TEXT:
				if layerFound and currentNode == "data":
					var csv = tmxfile.get_node_data().strip_edges()
					if encoding == "csv":
						if !csv == "":
							return csv
	return ""

func get_layer_property(file:String,layer:String,property:String):
	var tmxfile = XMLParser.new()
	var error = tmxfile.open(file)
	
	if !error == OK:
		return "i got nothin"
	
	
	while tmxfile.read() == OK:
		match tmxfile.get_node_type():
			XMLParser.NODE_ELEMENT:
				if tmxfile.get_node_name() == "layer":
					if tmxfile.has_attribute("name") and tmxfile.has_attribute("height"):
						if tmxfile.get_named_attribute_value("name") == layer:
							var value = tmxfile.get_named_attribute_value(property)
							return value
					else:
						var value = tmxfile.get_named_attribute_value(property)
						return value
					
	return "this shouldn't be seen"
