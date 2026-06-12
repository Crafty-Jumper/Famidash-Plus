extends AudioStreamPlayer

var lfsr = 1  # must never be 0
var current_index : int = 9
var noise_periods = [
	4, 8, 16, 32, 64, 96, 128, 160,
	202, 254, 380, 508, 762, 1016, 2034, 4068
]
var volume = 0.0
var timer = 0
var period = noise_periods[current_index]
var current_value = 1.0
var short : bool = false
var playback

func _ready():
	var noise = AudioStreamGenerator.new()
	noise.mix_rate = 44100  # standard sample rate
	noise.buffer_length = 0.05  # small = lower latency

	stream = noise
	play()

	playback = get_stream_playback()

func _process(_delta):
	if playback == null:
		return

	var frames_available = playback.get_frames_available()

	for i in range(frames_available):
		var sample = generate_sample()
		playback.push_frame(Vector2(sample, sample))  # stereo

var sample_rate = 44100.0
var cpu_rate = 1789773.0  # NES CPU
var timer_counter = 0.0

func generate_sample():
	var freq = cpu_rate / (period * 2.0)

	timer_counter += freq / sample_rate

	var accum = 0.0
	var steps = 0

	while timer_counter >= 1.0:
		timer_counter -= 1.0
		current_value = clock_noise(short)
		accum += current_value
		steps += 1

	# If no steps happened, just use current value
	if steps == 0:
		return current_value * volume / 15.0 * 0.2

	# Average the steps (THIS is the key fix)
	var avg = accum / steps
	return avg * volume / 15.0 * 0.2

func clock_noise(short_mode: bool) -> float:
	var bit0 = lfsr & 1
	var tap_bit = (lfsr >> (6 if short_mode else 1)) & 1
	var feedback = bit0 ^ tap_bit

	# Shift register
	lfsr = (lfsr >> 1) | (feedback << 14)

	# --- NES-style output ---
	# NES outputs 0 or 1, not ±1
	# and it's inverted (bit0 == 0 = loud)
	var out = 1.0 if bit0 == 0 else 0.0

	# Convert to centered audio, but keep asymmetry
	return (out * 2.0 - 1.0) * 0.8 + (out * 0.2)

const CPU_CLOCK = 1789773.0

func set_note(index: int):
	current_index = fmod(index,16)
	period = noise_periods[current_index]
	

func set_volume(v: float):
	volume = clamp(v, 0.0, 15.0)
