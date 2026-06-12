extends AudioStreamPlayer

# -----------------------------
# Pulse wave settings
# -----------------------------
var duty_patterns = [
	0.125, # 12.5%
	0.25,  # 25%
	0.5,   # 50%
	0.75   # 75%
]
var volume : float = 0.0
var duty_index : int = 0
var duty : float = 0.5

# -----------------------------
# State
# -----------------------------
var phase : float = 0.0
var current_value : float = 0.0

var step_interval : float = 0.0
var sample_rate := 44100.0

var playback

# -----------------------------
# Init
# -----------------------------
func _ready():
	var pulse = AudioStreamGenerator.new()
	pulse.mix_rate = sample_rate
	pulse.buffer_length = 0.05

	stream = pulse
	play()
	
	playback = get_stream_playback()
	
	set_duty(duty_index)
	set_frequency(658.0/2)

# -----------------------------
# Frequency control
# -----------------------------
func set_frequency(hz: float):
	step_interval = sample_rate / hz

func change_duty(duty_cycle:int=0):
	duty_index = duty_cycle
	duty_index = fmod(duty_index,4)
	duty = duty_patterns[duty_index]

# -----------------------------
# Duty control
# -----------------------------
func set_duty(index: int):
	duty_index = clamp(index, 0, 3)
	duty = duty_patterns[duty_index]

# -----------------------------
# Audio loop
# -----------------------------
func _process(_delta):
	if playback == null:
		return

	var frames = playback.get_frames_available()

	for i in range(frames):
		playback.push_frame(Vector2(generate_sample(), generate_sample()))

# -----------------------------
# Sample generation
# -----------------------------
func generate_sample():
	phase += 1.0

	while phase >= step_interval:
		phase -= step_interval

	# position inside cycle (0–1)
	var t = phase / step_interval

	if t < duty:
		current_value = 1.0
	else:
		current_value = -1.0

	return current_value * 0.2 * volume/15

func set_volume(v: float):
	volume = clamp(v, 0.0, 15.0)
