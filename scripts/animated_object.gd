class AnimatingObject:
	extends Sprite2D
	
	@export var frames = 2
	@export var fps = 1
	var frame_idx = 0
	var startFrame = frame
	
	var timer = Timer.new()
	
	func _ready() -> void:
		timer.time_left = fps/60.0
		timer.one_shot = true
		add_child(timer)


# Called every frame. 'delta' is the elapsed time since the previous frame.
	func _process(_delta: float) -> void:
		if timer.time_left <= 0:
			timer.start()
		if frame_idx > frames:
			frame_idx = 0
		frame = startFrame + frame_idx
