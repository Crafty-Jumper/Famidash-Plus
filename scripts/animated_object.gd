extends Node2D
class_name AnimatedObject

@export var frames = 1
@export var fps = 1
@onready var sprite : Sprite2D = get_parent()
var frame_idx = 0
var startFrame = 0

var timer = Timer.new()

func _ready() -> void:
	startFrame = sprite.frame

func _process(delta: float) -> void:
	sprite.frame = startFrame + frame_idx
	frame_idx = fmod(floor(Time.get_ticks_msec()/1000.0*fps),frames)
