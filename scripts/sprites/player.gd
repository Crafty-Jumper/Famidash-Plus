extends CharacterBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var sprite_2d_2: Sprite2D = $Sprite2D2

var gamemode : int = 0
var dashing : bool = false
var dashSpeed : float = 0.0
var flipped : bool = false
var flippedMult = 1
var buffering : bool = false
var clicking : bool = false
var first_click : bool = false
var clickDisabler : bool = false
@onready var trigger_manager: Area2D = $"../Area2D"

var iconRotates : bool = true
var iconSpeed : float = 1.0

const base_speed = 166
const speeds : Array = [
	base_speed, # 1x
	base_speed * 0.8068, # 0.5x
	base_speed * 1.2444, # 2x
	base_speed * 1.5042, # 3x
	base_speed * 1.8503, # 4x
	base_speed * 0.5179 # 0.25
	]
var speedIdx = 0

var JUMP_VELOCITY = 0xF953 / 224.0
var ship_speed = 0x003C
var maxFall = 0x07C1 / 5.0
var gravity = 0x009A / 416.0
var physicsTable = {
		"canHeadBonk":false,
		"upVel":284.942,
		"gravity":0.37,
		"maxFall":397.0,
		"maxUp":397.0,
		"pads":[0,0,0,0],
		"size":[14,14]
	}
var physics = JSON.parse_string(FileAccess.open("res://physics.json",FileAccess.READ).get_as_text())

var gravMult : float = 1

@onready var level: Node2D = $".."
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var rotation_frame = 0
var ninjaJumps = 3
var robotJump = 0x13

## textures n stuff
const deathSpr : Texture2D = preload("res://player/explode.png")

var cubeSpr : Texture2D = load("res://player/cubes/cube" + str(Global.save_data["icons"][0]) + ".png")
var shipCubeSpr : Texture2D = load("res://player/cubes/ship" + str(Global.save_data["icons"][0]) + ".png")
var shipSpr : Texture2D = load("res://player/ships/ship" + str(Global.save_data["icons"][1]) + ".png")
var ballSpr : Texture2D = load("res://player/balls/ball" + str(Global.save_data["icons"][2]) + ".png")
var ufoSpr : Texture2D = load("res://player/ufos/ufo" + str(Global.save_data["icons"][3]) + ".png")
var robotSpr : Texture2D = load("res://player/robots/robot" + str(Global.save_data["icons"][5]) + ".png")
var spiderSpr : Texture2D = load("res://player/spiders/spider" + str(Global.save_data["icons"][6]) + ".png")
var waveSpr : Texture2D = load("res://player/waves/wave" + str(Global.save_data["icons"][4]) + ".png")
var swingSpr : Texture2D = load("res://player/swings/swing" + str(Global.save_data["icons"][7]) + ".png")
var ninjaSpr : Texture2D = load("res://player/ninjas/ninja" + str(Global.save_data["icons"][9]) + ".png")

const jimshipSpr : Texture2D = preload("res://player/jim/ship.png")
const jimufoSpr : Texture2D = preload("res://player/jim/ufo.png")
const jimrobotSpr : Texture2D = preload("res://player/jim/robot.png")

var on_floor : bool = false
var on_left_wall : bool = false
var on_right_wall : bool = false
var on_ceil : bool = false

func update_physics(mode:String="cube") -> void:
	physicsTable = physics[mode]

func _ready() -> void:
	var icons = FileAccess.open("res://icons.json",FileAccess.READ)
	var json = JSON.parse_string(icons.get_as_text())
	iconRotates = json["cube"][Global.save_data["icons"][0]].get("rotate",true)
	iconSpeed = json["cube"][Global.save_data["icons"][0]].get("animSpeed",1.0)
	icons.close()
	sprite_2d.material.set_shader_parameter("outline",Global.get_color(Global.save_data["colors"][2]))
	sprite_2d.material.set_shader_parameter("col1",Global.get_color(Global.save_data["colors"][0]))
	sprite_2d.material.set_shader_parameter("col2",Global.get_color(Global.save_data["colors"][1]))

func _physics_process(delta: float) -> void:
	debug_mode()
	sprite_2d_2.visible = false
	collision_shape_2d.disabled = gamemode == -1
	if gamemode == -1:
		rotation_frame += 1
		if Global.retro:
			sprite_2d.frame = 3
			sprite_2d.position.y = flippedMult * ((0.15*(rotation_frame*rotation_frame)) + (-5 * rotation_frame))
		else:
			if rotation_frame < 16:
				sprite_2d.frame = floor(rotation_frame/4.0)
			else:
				sprite_2d.visible = false
		if rotation_frame == 40:
			Global.fade_scene("res://scenes/level.tscn",false,true)
		return
	collision_handle()
	on_floor = get("on_floor")
	on_ceil = get("on_ceil")
	on_left_wall = get("on_left_wall")
	on_right_wall = get("on_right_wall")
	if flipped:
		var tmp = on_floor
		on_floor = on_ceil
		on_ceil = tmp
	velocity.x = speeds[speedIdx]
	flippedMult = -1 if flipped else 1
	up_direction.y = -flippedMult
	sprite_2d.flip_v = flipped if gamemode != 0 else false
	sprite_2d_2.flip_v = flipped
	if !(Input.is_action_pressed("A") or Input.is_action_pressed("up")):
		clickDisabler = false
	if !clickDisabler:
		clicking = (Input.is_action_pressed("A") or Input.is_action_pressed("up"))
		first_click = (Input.is_action_just_pressed("A") or Input.is_action_just_pressed("up"))
	if on_right_wall:
		die()
	if on_ceil:
		if !physicsTable["canHeadBonk"]:
			die()
	
	
	
	if gamemode == 0:
		handle_cube(delta)
	if gamemode == 1:
		if Global.retro:
			handle_ufo(delta)
		else:
			handle_ship(delta)
	if gamemode == 2:
		handle_ball(delta)
	if gamemode == 3:
		handle_ufo(delta)
	if gamemode == 4:
		handle_robot(delta)
	if gamemode == 5:
		handle_spider(delta)
	if gamemode == 6:
		handle_wave(delta)
	if gamemode == 7:
		handle_swing(delta)
	if gamemode == 8:
		if Global.retro:
			handle_robot(delta)
		else:
			handle_ninja(delta)
	if dashing:
		velocity.y = dashSpeed * velocity.x
		if !clicking:
			dashing = false
			velocity.y = 0
	
	if velocity.y * flippedMult > maxFall:
		velocity.y = flippedMult * maxFall
	
	buffer()
	
	move_and_slide()

func animate_cube(texture: Texture2D=cubeSpr,rotate:bool=true) -> void:
	sprite_2d.texture = texture
	sprite_2d.hframes = 7
	
	if !on_floor:
		rotation_frame += flippedMult * iconSpeed
		if dashing:
			rotation_frame += flippedMult * iconSpeed
	else:
		if !clicking:
			rotation_frame = round(rotation_frame/12.0)*12
	sprite_2d.frame = floor(fmod(rotation_frame/2,6))
	if rotate:
		sprite_2d.rotation_degrees = floor(rotation_frame/12)*90
	else:
		sprite_2d.rotation = 0
	rotation_frame = wrap(rotation_frame,0,48)

func animate_ship(texture:Texture2D=shipSpr,flip:bool=true):
	sprite_2d.texture = shipCubeSpr
	sprite_2d_2.visible = true
	sprite_2d.hframes = 5
	sprite_2d_2.hframes = 5
	sprite_2d_2.texture = texture
	rotation_frame = 2
	sprite_2d.rotation = 0
	if velocity.y < -50:
		if velocity.y > -100:
			rotation_frame += (flippedMult if flip else 1)
		else:
			rotation_frame += 2 * (flippedMult if flip else 1)
	elif velocity.y > 50:
		rotation_frame -= (flippedMult if flip else 1)
		if velocity.y > 100:
			rotation_frame -= 2 * (flippedMult if flip else 1)
	sprite_2d.frame = clamp(rotation_frame,0,4)
	sprite_2d_2.frame = clamp(rotation_frame,0,4)
	if !flip:
		sprite_2d.flip_v = false
		sprite_2d_2.flip_v = false

func animate_ball(texture:Texture2D=ballSpr):
	sprite_2d.texture = texture
	sprite_2d.hframes = 4
	sprite_2d.frame = rotation_frame/4
	rotation_frame = wrap(rotation_frame,0,15)
	rotation_frame += 1

func animate_ufo(texture:Texture2D=ufoSpr):
	sprite_2d.hframes = 1
	sprite_2d.rotation = 0
	sprite_2d.texture = texture

func animate_robot(texture: Texture2D=robotSpr,isThreeFrame:bool=false) -> void:
	sprite_2d.texture = texture
	sprite_2d.hframes = 5
	sprite_2d.rotation = 0
	if !on_floor:
		sprite_2d.frame = 4
	else:
		if !clicking:
			sprite_2d.frame = rotation_frame/(6 if isThreeFrame else 4)
	rotation_frame = wrap(rotation_frame,0,15)
	rotation_frame += 1

func animate_wave(texture:Texture2D=waveSpr):
	sprite_2d.rotation = 0
	sprite_2d.texture = texture
	sprite_2d.hframes = 3
	if velocity.y < 0:
		rotation_frame = 2
	elif velocity.y > 0:
		rotation_frame = 0
	else:
		rotation_frame = 1
	sprite_2d.frame = rotation_frame

func buffer() -> void:
	if on_floor:
		buffering = false
		return
	if !clicking:
		buffering = false
	if first_click:
		buffering = true

func handle_cube(delta:float) -> void:
	update_physics()
	
	if Global.retro:
		gamemode = 4
	
	
	animate_cube(cubeSpr,iconRotates)
	if not on_floor:
		velocity.y += physicsTable["gravity"] * delta * flippedMult * gravMult
	if clicking and on_floor:
		velocity.y = -physicsTable["upVel"] * flippedMult
	if velocity.y > physicsTable["maxFall"]:
		velocity.y = physicsTable["maxFall"]
	if velocity.y < -physicsTable["maxUp"]:
		velocity.y = -physicsTable["maxUp"]


func handle_ship(delta:float) -> void:
	update_physics("ship")
	animate_ship()
	if not on_floor and !clicking:
		velocity.y += physicsTable["gravity"] * delta * flippedMult * gravMult
	if clicking:
		velocity.y -= physicsTable["upVel"] * delta * flippedMult * gravMult
	if velocity.y > physicsTable["maxFall"]:
		velocity.y = physicsTable["maxFall"]
	if velocity.y < -physicsTable["maxUp"]:
		velocity.y = -physicsTable["maxUp"]



func handle_ball(delta:float) -> void:
	update_physics("ball")
	if (first_click and on_floor) or (buffering and on_floor):
		flipped = !flipped
		velocity.y = -physicsTable["upVel"] * flippedMult
	animate_ball()
	if not on_floor:
		velocity.y += physicsTable["gravity"] * delta * flippedMult * gravMult
	
	if velocity.y > physicsTable["maxFall"]:
		velocity.y = physicsTable["maxFall"]
	if velocity.y < -physicsTable["maxUp"]:
		velocity.y = -physicsTable["maxUp"]

func handle_ufo(delta:float) -> void:
	update_physics("ufo")
	if Global.retro:
		if gamemode == 1:
			animate_ship(jimshipSpr)
		else:
			animate_ufo(jimufoSpr)
	else:
		animate_ufo()
	
	if not on_floor:
		velocity.y += physicsTable["gravity"] * delta * flippedMult * gravMult
	if first_click:
		velocity.y = -physicsTable["upVel"] * flippedMult
	if velocity.y > physicsTable["maxFall"]:
		velocity.y = physicsTable["maxFall"]
	if velocity.y < -physicsTable["maxUp"]:
		velocity.y = -physicsTable["maxUp"]

func handle_robot(delta:float) -> void:
	if Global.retro:
		update_physics("cube")
	else:
		update_physics("robot")
	if Global.retro:
		animate_robot(jimrobotSpr,true)
	else:
		animate_robot()
	if not on_floor:
		velocity.y += physicsTable["gravity"] * delta * flippedMult * gravMult
		if !clicking:
			robotJump = 0
	else:
		robotJump = 0x13
		ninjaJumps = 3
	if clicking and robotJump > 0:
		velocity.y = -JUMP_VELOCITY/2 * flippedMult
		robotJump -= 1
	if gamemode == 8:
		if ninjaJumps > 0:
			if first_click:
				robotJump = 0x13
				ninjaJumps -= 1
	if velocity.y > physicsTable["maxFall"]:
		velocity.y = physicsTable["maxFall"]
	if velocity.y < -physicsTable["maxUp"]:
		velocity.y = -physicsTable["maxUp"]


func handle_spider(delta:float) -> void:
	update_physics("spider")
	if (first_click and on_floor) or (buffering and on_floor):
		spider_teleport(!flipped)
	animate_robot(spiderSpr)
	if not on_floor:
		velocity.y += physicsTable["gravity"] * delta * flippedMult * gravMult * 0.9
	if velocity.y * flippedMult  > physicsTable["maxFall"]:
		velocity.y = physicsTable["maxFall"] * flippedMult 
	if velocity.y * flippedMult  < -physicsTable["maxUp"]:
		velocity.y = -physicsTable["maxUp"] * flippedMult 

func handle_wave(delta:float) -> void:
	animate_wave()
	if clicking:
		velocity.y = -abs(velocity.x)
	else:
		velocity.y = abs(velocity.x)

func handle_swing(delta:float) -> void:
	update_physics("swing")
	if Global.retro:
		animate_ship(jimufoSpr)
	else:
		animate_ship(swingSpr,false)
	sprite_2d.flip_v = false
	
	if not on_floor:
		velocity.y += physicsTable["gravity"] * delta * flippedMult * gravMult
	if first_click:
		flipped = !flipped
	if velocity.y * flippedMult > physicsTable["maxFall"]:
		velocity.y = physicsTable["maxFall"] * flippedMult 
	if velocity.y * flippedMult  < -physicsTable["maxUp"]:
		velocity.y = -physicsTable["maxUp"] * flippedMult 

func handle_ninja(delta:float) -> void:
	update_physics()
	
	if Global.retro:
		animate_robot(jimrobotSpr)
	else:
		animate_cube(ninjaSpr,false)
	
	
	
	if first_click and ninjaJumps > 1:
		velocity.y = -physicsTable["upVel"] * flippedMult
		ninjaJumps -= 1
	
	if not on_floor:
		velocity.y += physicsTable["gravity"] * delta * flippedMult * gravMult
	else:
		ninjaJumps = 3
	if velocity.y * flippedMult  > physicsTable["maxFall"]:
		velocity.y = physicsTable["maxFall"] * flippedMult 
	if velocity.y  * flippedMult < -physicsTable["maxUp"]:
		velocity.y = -physicsTable["maxUp"] * flippedMult 

func die() -> void:
	if Global.debug:
		return
	collision_shape_2d.disabled = true
	if position.x < 32:
		return
	Global.play_sfx(0)
	if Global.retro:
		sprite_2d.texture = jimrobotSpr
		sprite_2d.hframes = 5
	else:
		sprite_2d.texture = deathSpr
		sprite_2d.hframes = 4
	sprite_2d.frame = 0
	rotation_frame = 0
	rotation = 0
	gamemode = -1

@warning_ignore("unused_parameter")
func _on_area_2d_body_entered(body: Node2D) -> void:
	die()

func spider_teleport(up:bool=false) -> void:
	disable_clicks()
	velocity.y = 0
	flipped = up
	if up:
		ray_cast_2d.target_position = Vector2(0,-256.0)
	else:
		ray_cast_2d.target_position = Vector2(0,256.0)
	ray_cast_2d.force_raycast_update()
	position.y = ray_cast_2d.get_collision_point().y + (8 if up else -8)
	
	return

func disable_clicks() -> void:
	clickDisabler = true
	clicking = false
	first_click = false

func teleport(vel:float=velocity.y,off:float=0) -> void:
	position.y = trigger_manager.tpExitY + off
	velocity.y = vel

@onready var node_2d: Node2D = $Node2D
@onready var br: RayCast2D = $Node2D/br
@onready var b: RayCast2D = $Node2D/b
@onready var bl: RayCast2D = $Node2D/bl
@onready var cr: RayCast2D = $Node2D/cr
@onready var c: RayCast2D = $Node2D/c
@onready var cl: RayCast2D = $Node2D/cl
@onready var tr: RayCast2D = $Node2D/tr
@onready var t: RayCast2D = $Node2D/t
@onready var tl: RayCast2D = $Node2D/tl

func collision_handle() -> void:
	on_ceil = false
	on_floor = false
	on_left_wall = false
	on_right_wall = false
	if gamemode != -1:
		if velocity.y >= -1:
			collide(br,"on_floor",!flipped or physicsTable["canHeadBonk"],!flipped or physicsTable["canHeadBonk"])
			collide(b,"on_floor",true,!flipped or physicsTable["canHeadBonk"])
			collide(bl,"on_floor",!flipped or physicsTable["canHeadBonk"],!flipped or physicsTable["canHeadBonk"])
		if velocity.y <= 0:
			collide(tr,"on_ceil",flipped or physicsTable["canHeadBonk"],flipped or physicsTable["canHeadBonk"])
			collide(t,"on_ceil",true,flipped or physicsTable["canHeadBonk"])
			collide(tl,"on_ceil",flipped or physicsTable["canHeadBonk"],flipped or physicsTable["canHeadBonk"])
		collide(cr,"on_right_wall",false,false)
		if c.is_colliding():
			die()
		collide(cr,"on_left_wall",false,false)

func collide(node:RayCast2D,surface:String,push:bool=true,surface_graze:bool=false):
	node.enabled = false
	node.force_raycast_update()
	node.enabled = true
	var push_mask : Vector2 = node.target_position / physicsTable["size"][0]
	if node.is_colliding():
		print(node.get_collision_point() != position + node.target_position)
		if (node.get_collision_point() == position + node.target_position and surface_graze) or (node.get_collision_point() != position + node.target_position):
			if push:
				position.y = node.get_collision_point().y - push_mask.y * physicsTable["size"][1]
				velocity.y = 0
				if surface == "on_ceil":
					on_ceil = true
				elif surface == "on_left_wall":
					on_left_wall = true
				elif surface == "on_right_wall":
					on_right_wall = true
				else:
					on_floor = true

func debug_mode() -> void:
	if !Global.debug:
		return
	if Input.is_action_just_pressed("right"):
		flipped = !flipped
