extends AudioStreamPlayer

# -----------------------------
# DPCM rate table (NES)
# -----------------------------
var dpcm_rates = [
	428, 380, 340, 320, 286, 254, 226, 214,
	190, 160, 142, 128, 106,  85,  72,  54
]
var dpcm_buffer := []

# -----------------------------
# State
# -----------------------------
var sample_data : PackedByteArray = PackedByteArray()
var sample_pos := 0
var bit_index := 0
var step_counter = 0
var step_length = 1
var output_level := 64  # 0–127 (centered)

var rate_index := 15
var timer := 0.0

var sample_rate := 44100.0
const CPU_CLOCK = 1789773.0
var playback_pos := 0.0
var decoded_buffer := PackedFloat32Array()

var playback

# -----------------------------
# Init
# -----------------------------
func _ready():
	var dpcm = AudioStreamGenerator.new()
	dpcm.mix_rate = sample_rate
	dpcm.buffer_length = 0.05

	stream = dpcm
	play()
	
	var sampleString = load_dpcm_from_file("fdbass D")
	load_sample(hex_to_bytes(sampleString))
	decode_all()
	
	set_rate(0)
	
	playback = get_stream_playback()

# -----------------------------
# Load sample
# -----------------------------
func load_sample(data: PackedByteArray):
	sample_data = data
	sample_pos = 0
	bit_index = 0

# -----------------------------
# Playback control
# -----------------------------

# -----------------------------
# Rate control
# -----------------------------
func set_rate(index: int):
	rate_index = clamp(index, 0, 15)

# -----------------------------
# Audio loop
# -----------------------------
func _process(_delta):
	if playback == null or !playing:
		return

	var frames = playback.get_frames_available()

	for i in range(frames):
		var s = generate_sample()
		playback.push_frame(Vector2(s, s))

# -----------------------------
# Sample generation
# -----------------------------

func decode_all():
	decoded_buffer.clear()
	output_level = 64

	for i in range(sample_data.size()):
		var byte = sample_data[i]

		for b in range(8):
			var bit = (byte >> b) & 1

			if bit == 1:
				output_level = min(output_level + 2, 127)
			else:
				output_level = max(output_level - 2, 0)

			var sample = ((output_level / 127.0) * 2.0 - 1.0) * 0.2
			decoded_buffer.append(sample)

func generate_sample():
	var step_time = dpcm_rates[rate_index] 
	timer += 1.0 / sample_rate

	if timer >= step_time:
		timer -= step_time
		advance_dpcm_state()
		step_length = int(sample_rate * step_time)
		step_counter = 0
	
	if step_counter < step_length:
		step_counter += 1
	
	return ((output_level / 127.0) * 2.0 - 1.0) * 0.2

func advance_dpcm_state():
	if sample_pos >= sample_data.size():
		playing = false
		return

	var byte = sample_data[sample_pos]
	var bit = (byte >> bit_index) & 1

	if bit == 1:
		output_level = min(output_level + 2, 127)
	else:
		output_level = max(output_level - 2, 0)

	bit_index += 1
	if bit_index >= 8:
		bit_index = 0
		sample_pos += 1

func hex_to_bytes(hex: String) -> PackedByteArray:
	var bytes = PackedByteArray()
	
	# safety: remove whitespace/newlines just in case
	hex = hex.strip_edges().to_lower()
	
	for i in range(0, hex.length(), 2):
		var byte_str = hex.substr(i, 2)
		var value = int("0x" + byte_str)
		bytes.append(value)
	
	return bytes

func load_dpcm_from_file(sample:String):
	var file = FileAccess.open("user://cache/dpcm.json", FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(json_text)
	return parsed[sample]["data"]
