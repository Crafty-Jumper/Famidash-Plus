extends AudioStreamPlayer

# -----------------------------
# Triangle waveform (32-step NES-style)
# -----------------------------
var triangle_table = [
	0,1,2,3,4,5,6,7,
	8,9,10,11,12,13,14,15,
	15,14,13,12,11,10,9,8,
	7,6,5,4,3,2,1,0
]
const CPU_CLOCK = 1789773.0

# -----------------------------
# State
# -----------------------------
var tri_index := 0
var current_value := 0.0
var base_step_interval := 0.0
var timer_counter := 0.0
var step_interval := 0.0  # time per triangle step
var volume : float = 15.0

# -----------------------------
# Audio config
# -----------------------------
var sample_rate := 44100.0

var playback
var playingSound : bool = false
# -----------------------------
# Init
# -----------------------------
func _ready():
	var triangle = AudioStreamGenerator.new()
	triangle.mix_rate = sample_rate
	triangle.buffer_length = 0.05

	stream = triangle
	play()
	
	playback = get_stream_playback()
	
	set_frequency(440)

# -----------------------------
# Frequency control (IMPORTANT)
# -----------------------------
func set_frequency(hz: float):
	base_step_interval = (1.0 / hz) / 32.0
	step_interval = base_step_interval


# -----------------------------
# Audio loop
# -----------------------------
func _process(_delta):
	if playback == null:
		return
	if !playingSound:
		return
	
	var frames_available = playback.get_frames_available()
	
	for i in range(frames_available):
		var sample = generate_sample()
		playback.push_frame(Vector2(sample, sample))

# -----------------------------
# Sample generation
# -----------------------------
func generate_sample():
	timer_counter += 1.0 / sample_rate

	while timer_counter >= step_interval:
		timer_counter -= step_interval
		tri_index = (tri_index + 1) % 32
		current_value = triangle_table[tri_index]

	# normalize 0–15 → -1 to 1
	if volume > 0:
		return (current_value / 15.0) * 0.2
	else:
		return (current_value / 15.0) * 0

func apply_pitch_offset(semitones: float):
	var ratio = pow(2.0, semitones / 12.0)
	step_interval = base_step_interval / ratio
