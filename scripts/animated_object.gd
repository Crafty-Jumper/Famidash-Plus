extends Node2D
class_name AnimatedObject

@export var frames = 2
@export var fps = 1
@onready var sprite = get_parent()
var frame_idx = 0
var startFrame = 0

var timer = Timer.new()

func _ready() -> void:
	add_child(timer)
	timer.one_shot = true
	timer.start(1.0/fps)
	timer.timeout.connect(looped)
	startFrame = sprite.frame

func looped() -> void:
	timer.start(fps/60.0)
	sprite.frame = startFrame + frame_idx
	if frame_idx > frames:
		frame_idx = 0
