extends CharacterBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D

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

@onready var collision_area: Area2D = $CollisionArea

const speeds : Array = [
	166, # 1x
	132, # 0.5x
	208, # 2x
	]
var speedIdx = 0
const JUMP_VELOCITY = 0xF953 / 224.0
const ship_speed = 0x003C
const maxFall = 0x07C1 / 5.0

var gravMult : float = 1
const gravity = 0x009A / 416.0
@onready var level: Node2D = $".."
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var rotation_frame = 0
var ninjaJumps = 3
var robotJump = 0x13

## textures n stuff
const deathSpr : Texture2D = preload("res://player/explode.png")

const cubeSpr : Texture2D = preload("res://player/cube00.png")
const shipSpr : Texture2D = preload("res://player/ship00.png")
const ballSpr : Texture2D = preload("res://player/ball00.png")
const ufoSpr : Texture2D = preload("res://player/ufo00.png")
const robotSpr : Texture2D = preload("res://player/robot00.png")
const spiderSpr : Texture2D = preload("res://player/spider00.png")
const ninjaSpr : Texture2D = preload("res://player/ninja00.png")

const jimshipSpr : Texture2D = preload("res://player/jim/ship.png")
const jimufoSpr : Texture2D = preload("res://player/jim/ufo.png")
const jimrobotSpr : Texture2D = preload("res://player/jim/robot.png")


func _physics_process(delta: float) -> void:
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
	velocity.x = speeds[speedIdx]
	flippedMult = -1 if flipped else 1
	up_direction.y = -flippedMult
	sprite_2d.flip_v = flipped
	if !(Input.is_action_pressed("A") or Input.is_action_pressed("up")):
		clickDisabler = false
	if !clickDisabler:
		clicking = (Input.is_action_pressed("A") or Input.is_action_pressed("up"))
		first_click = (Input.is_action_just_pressed("A") or Input.is_action_just_pressed("up"))
	if is_on_wall():
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
	
	if !is_on_floor():
		rotation_frame += 1
		if dashing:
			rotation_frame += 1
	else:
		if !clicking:
			rotation_frame = floor(rotation_frame/12.0)*12
	sprite_2d.frame = floor(fmod(rotation_frame/2,6))
	if rotate:
		sprite_2d.rotation_degrees = floor(rotation_frame/12)*90
	else:
		sprite_2d.rotation = 0
	rotation_frame = wrap(rotation_frame,0,48)

func animate_ship(texture:Texture2D=shipSpr):
	sprite_2d.texture = texture
	sprite_2d.hframes = 5
	rotation_frame = 2
	sprite_2d.rotation = 0
	if velocity.y < -50:
		if velocity.y > -100:
			rotation_frame += flippedMult
		else:
			rotation_frame += 2*flippedMult
	elif velocity.y > 50:
		rotation_frame -= flippedMult
		if velocity.y > 100:
			rotation_frame -= 2 * flippedMult 
	sprite_2d.frame = clamp(rotation_frame,0,4)

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
	if !is_on_floor():
		sprite_2d.frame = 4
	else:
		if !clicking:
			sprite_2d.frame = rotation_frame/(6 if isThreeFrame else 4)
	rotation_frame = wrap(rotation_frame,0,15)
	rotation_frame += 1

func buffer() -> void:
	if is_on_floor():
		buffering = false
		return
	if !clicking:
		buffering = false
	if first_click:
		buffering = true

func handle_cube(delta:float) -> void:
	
	if Global.retro:
		gamemode = 4
	
	animate_cube(cubeSpr)
	
	if not is_on_floor():
		velocity.y += gravity * delta * 3600 * flippedMult * gravMult
	if clicking and is_on_floor():
		velocity.y = -JUMP_VELOCITY * flippedMult

func handle_ship(delta:float) -> void:
	if velocity.y > maxFall/2:
		velocity.y = maxFall/2
	if velocity.y < -maxFall/2:
		velocity.y = -maxFall/2
	animate_ship()
	if not is_on_floor() and !clicking:
		velocity.y += ship_speed * delta * 7 * flippedMult * gravMult
	if clicking:
		velocity.y -= ship_speed * delta * 12.5 * flippedMult * gravMult

func handle_ball(delta:float) -> void:
	if (first_click and is_on_floor()) or (buffering and is_on_floor()):
		flipped = !flipped
		velocity.y = -20 * flippedMult
	animate_ball()
	if not is_on_floor():
		velocity.y += gravity * delta * 3600 * flippedMult * gravMult

func handle_robot(delta:float) -> void:
	
	if Global.retro:
		animate_robot(jimrobotSpr,true)
	else:
		animate_robot()
	if not is_on_floor():
		velocity.y += gravity * delta * 3600 * flippedMult * (1 if Global.retro else 0.9) * gravMult
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

func handle_spider(delta:float) -> void:
	if (first_click and is_on_floor()) or (buffering and is_on_floor()):
		spider_teleport(!flipped)
	animate_robot(spiderSpr)
	if not is_on_floor():
		velocity.y += gravity * delta * 3600 * flippedMult * gravMult * 0.9

func handle_ninja(delta:float) -> void:
	
	if Global.retro:
		animate_robot(jimrobotSpr)
	else:
		animate_cube(ninjaSpr,false)
	
	
	
	if first_click and ninjaJumps > 1:
		velocity.y = -JUMP_VELOCITY * flippedMult
		ninjaJumps -= 1
	
	if not is_on_floor():
		velocity.y += gravity * delta * 3600 * flippedMult * gravMult
	else:
		ninjaJumps = 3
func handle_ufo(delta:float) -> void:
	
	if Global.retro:
		if gamemode == 1:
			animate_ship(jimshipSpr)
		else:
			animate_ufo(jimufoSpr)
	else:
		animate_ufo()
	
	if not is_on_floor():
		velocity.y += gravity/3 * delta * 3600 * flippedMult * gravMult
	if first_click:
		velocity.y = -JUMP_VELOCITY * flippedMult / 2

func die() -> void:
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
