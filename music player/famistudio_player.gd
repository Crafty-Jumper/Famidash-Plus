extends Node2D

# =========================================================
# NODE REFERENCES
# =========================================================

@onready var pulse_1: AudioStreamPlayer = $"../Pulse1"
@onready var pulse_2: AudioStreamPlayer = $"../Pulse2"
@onready var triangle: AudioStreamPlayer = $"../Triangle"
@onready var noise: AudioStreamPlayer = $"../Noise"
@onready var dpcm: AudioStreamPlayer = $"../DPCM"

# =========================================================
# SONG DATA
# =========================================================
var song_data := {}
var song_meta := {}
var channel_state := {}

# =========================================================
# TIMING
# =========================================================
var tempo : int = 150
var speed : int = 6
var pattern_length : int = 24

var song_position : int = 0
var tick_time : float = 0.0
var row : int = 0

# =========================================================
# NOTE TABLE
# =========================================================
var note_freq := {}
var noise_freq := {}
var instruments : Dictionary = JSON.parse_string(FileAccess.open("user://cache/instruments.json",FileAccess.READ).get_as_text())

# =========================================================
# VOICES (INSTRUMENT INSTANCES)
# =========================================================
class Voice:
	var dpcm_sample : String = ""
	var dpcm_pitch : int = 0
	var dpcm_loop : bool = false
	
	var channel : String = ""
	var instrument : Dictionary = {}
	var base_freq : float = 440.0
	
	var dpcm_fired : bool = false
	
	var spawn_row : int = 0
	var releasing : bool = false
	var release : int = -1
	
	var length : int = 0
	var activity : int = 0
	
	var vol_env_index : int = 0
	var dut_env_index : int = 0
	var pit_env_index : int = 0
	var arp_env_index : int = 0
	
	var slide_target = null
	var volume_slide_target : int = -1
	var fine_pitch := 0
	var attack : bool = true
	
	var base_noise : int = 0
	var noise_index : int = 0
	
	var volume : int = 15
	var duty : int = 0
	var pitch : int = 0
	var arp : int = 0

var voices : Array = []

var vol_pulse1 : int = 15
var vol_pulse2 : int = 15
var vol_noise : int = 15

var dut_pulse1 : int = 0
var dut_pulse2 : int = 0
var dut_noise : int = 0

# =========================================================
# READY
# =========================================================
func _ready():
	build_note_table()
	build_noise_table()

# =========================================================
# UPDATE LOOP
# =========================================================
func _process(delta):
	tick_time -= delta
	if tick_time <= 0.0:
		tick_time += (speed * 60.0) / (tempo * 24.0)
		update_voices(true)
		step()
		return

	update_voices()

# =========================================================
# STEP ENGINE
# =========================================================
func step():
	for c in channel_state.keys():
		var ch = channel_state[c]

		var pattern_id = get_pattern(c)
		if pattern_id == null:
			continue

		var pattern = ch["patterns"].get(pattern_id, null)
		if pattern == null:
			continue

		for note in pattern:
			if note.get("time", -1) == row:
				if note.get("is_effect_only", false):
					apply_channel_effect(c, note)
				else:
					spawn_voice(c, note)

	advance_row()

func apply_channel_effect(channel: String, note: Dictionary):
	match channel:
		"Square1":
			if note["volume"] != -1:
				vol_pulse1 = note["volume"]
			if note["duty"] != -1:
				dut_pulse1 = note["duty"]

		"Square2":
			if note["volume"] != -1:
				vol_pulse2 = note["volume"]
			if note["duty"] != -1:
				dut_pulse2 = note["duty"]

		"Noise":
			if note["volume"] != -1:
				vol_noise = note["volume"]
			if note["duty"] != -1:
				dut_noise = note["duty"]

# =========================================================
# ADVANCE ROW + PATTERN INDEX
# =========================================================
func advance_row():
	row += 1

	if row >= pattern_length:
		row = 0
		song_position += 1

		# 🔁 global loop
		var song_length = int(song_meta["Length"])

		if song_position >= song_length:
			song_position = 0

# =========================================================
# GET CURRENT PATTERN
# =========================================================
func get_pattern(channel: String):
	var ch = channel_state[channel]

	if song_position >= ch["order"].size():
		return null

	var value = ch["order"][song_position]

	if value == null:
		return null

	if typeof(value) != TYPE_STRING:
		return null
	
	return value

# =========================================================
# SPAWN VOICE (THIS ENABLES INSTRUMENTS)
# =========================================================

func kill_oldest_voice(channel: String):
	for i in range(voices.size()):
		if voices[i].channel == channel:
			voices.remove_at(i)
			return

func spawn_voice(channel: String, note: Dictionary):
	var v = Voice.new()
	var instrument_name = note.get("instrument", "")
	var arp_name = note.get("arpeggio", "")
	var inst : Dictionary = instruments["instruments"].get(instrument_name, null)
	var arp = instruments["arpeggios"].get(arp_name,{})
	
	v.channel = channel
	v.instrument = inst.duplicate(true)
	if arp != {}:
		v.instrument["env"]["arp"] = arp["notes"]
		v.instrument["envHold"]["arp"][0] = int(arp["loop"])
		v.instrument["envHold"]["arp"][1] = -1
	
	var value = note.get("value", null)
	if value == null:
		return

	var freq = note_freq.get(value, null)
	if freq == null:
		return

	match channel:
		"Square1":
			if note["volume"] != -1:
				vol_pulse1 = note["volume"]
			if note["duty"] != -1:
				dut_pulse1 = note["duty"]

		"Square2":
			if note["volume"] != -1:
				vol_pulse2 = note["volume"]
			if note["duty"] != -1:
				dut_pulse2 = note["duty"]

		"Triangle":
			triangle.playingSound = true

		"Noise":
			if note["volume"] != -1:
				vol_noise = note["volume"]
			if note["duty"] != -1:
				dut_noise = note["duty"]
			v.base_noise = note_to_noise_index(value)

		
		"DPCM":
			var map = v.instrument.get("dpcmMap", {})
			var entry = map.get(v.dpcm_sample, null)

			if entry == null:
				return

			var sample_name = entry[0]

			var dpcm_node = dpcm
			var data = instruments["dpcm"].get(sample_name, null)

			if data == null:
				return

			dpcm_node.play_sample(data["data"])
			dpcm_node.set_note(v.dpcm_pitch)
			dpcm_node.set_volume(v.volume)

	

	# base freq + fine pitch
	v.base_freq = freq * pow(2.0, note.get("fine_pitch", 0) / 12.0)

	v.length = note["duration"]
	v.release = note["release"]
	v.spawn_row = row
	v.dpcm_fired = false
	
	# NEW EFFECTS
	v.slide_target = note.get("slide_target", null)
	# v.volume_slide_target = note.get("volume_slide_target", -1)
	v.attack = note.get("attack", true)
	voices.append(v)

func note_to_noise_index(note: String) -> int:
	return noise_freq.get(note, 0)

# =========================================================
# VOICE UPDATE (ENVELOPES)
# =========================================================
func update_voices(newrow:bool=false):
	# Track which channels are still active this frame
	var active_channels := {}

	# Iterate safely (don’t remove while looping forward)
	for i in range(voices.size() - 1, -1, -1):
		var v = voices[i]

		if v.instrument == null:
			continue

		# mark channel active
		active_channels[v.channel] = true

		# kill voice if expired
		if v.activity >= v.length:
			voices.remove_at(i)
			continue
		
		if v.activity >= v.release and v.release != -1:
			v.releasing = true
		
		if newrow:
			v.activity += 1
		step_envelope(v)
		apply_voice(v)

	# 🔴 IMPORTANT: turn off channels with no voices
	if !active_channels.has("Square1") and pulse_1:
		pulse_1.set_volume(0)

	if !active_channels.has("Square2") and pulse_2:
		pulse_2.set_volume(0)
	
	if !active_channels.has("Triangle") and triangle:
		triangle.playingSound = false

	if !active_channels.has("Noise") and noise:
		noise.set_volume(0)

# =========================================================
# ENVELOPE ENGINE
# =========================================================
func step_envelope(v):
	var env = v.instrument.get("env", {})
	var hold = v.instrument.get("envHold", {})
	
	
	# volume
	var vol = env.get("volume", [])
	if vol.size() > 0:
		if v.vol_env_index > vol.size()-1 or (v.vol_env_index == hold["volume"][1] and !v.releasing):
			if hold["volume"][0] == -1:
				v.volume = vol.get(vol.size()-1)
			else:
				if !v.releasing:
					v.vol_env_index = hold["volume"][0]
					v.volume = vol[v.vol_env_index]
		else:
			v.volume = vol.get(v.vol_env_index)
	if v.vol_env_index < hold["volume"][1] and v.releasing:
		v.vol_env_index = hold["volume"][1]
	
	
	# duty
	var duty_env = env.get("duty", [])

	if duty_env.size() > 0:
		if v.dut_env_index > duty_env.size()-1 or (v.dut_env_index == hold["duty"][1] and !v.releasing):
			if hold["duty"][0] == -1:
				v.duty = duty_env[duty_env.size()-1]
			else:
				if !v.releasing:
					v.duty = duty_env[hold["duty"][0]]
					v.dut_env_index = hold["duty"][0]
		else:
			v.duty = duty_env[v.dut_env_index]
	else:
		# fallback to channel duty
		match v.channel:
			"Square1":
				v.duty = dut_pulse1
			"Square2":
				v.duty = dut_pulse2
			"Noise":
				v.duty = dut_noise
	if v.dut_env_index < hold["duty"][1] and v.releasing:
		v.dut_env_index = hold["duty"][1]

	# pitch
	var pitch = env.get("pitch", [])
	if pitch.size() > 0:
		if v.pit_env_index > pitch.size()-1 or (v.pit_env_index == hold["pitch"][1] and !v.releasing):
			if hold["pitch"][0] == -1:
				v.pitch = pitch.get(pitch.size()-1)
			else:
				if !v.releasing:
					v.pitch = pitch.get(hold["pitch"][0])
					v.pit_env_index = hold["pitch"][0]
		else:
			v.pitch = pitch[v.pit_env_index]
	if v.pit_env_index < hold["pitch"][1] and v.releasing:
		v.pit_env_index = hold["pitch"][1]
	
	
	var arp = env.get("arp", [])
	if arp.size() > 0:
		if v.arp_env_index > arp.size()-1 or (v.arp_env_index == hold["arp"][1] and !v.releasing):
			if hold["arp"][0] == -1:
				v.arp = arp.get(arp.size()-1)
			else:
				if !v.releasing:
					v.arp = arp.get(hold["arp"][0])
					v.arp_env_index = hold["arp"][0]
		else:
			v.arp = arp[v.arp_env_index]
	if v.arp_env_index < hold["arp"][1] and v.releasing:
		v.arp_env_index = hold["arp"][1]
	
	
	v.vol_env_index += 1
	v.dut_env_index += 1
	v.pit_env_index += 1
	v.arp_env_index += 1

# =========================================================
# APPLY TO AUDIO NODES
# =========================================================
func apply_voice(v):
	var freq = v.base_freq * pow(2.0, v.arp / 12.0)
	
	# --- Slide handling ---
	if v.slide_target != null:
		var target = note_freq.get(v.slide_target, v.base_freq)
		v.base_freq = lerp(v.base_freq, target, 0.2)
	
	if v.volume_slide_target != -1:
		v.volume = lerp(v.volume, v.volume_slide_target, 0.1)
	
	match v.channel:

		"Square1":
			if pulse_1:
				pulse_1.set_frequency(freq/2)
				pulse_1.set_volume(v.volume*vol_pulse1/15)
				pulse_1.set_duty(v.duty)

		"Square2":
			if pulse_2:
				pulse_2.set_frequency(freq/2)
				pulse_2.set_volume(v.volume*vol_pulse2/15)
				pulse_2.set_duty(v.duty)

		"Triangle":
			if triangle:
				triangle.set_frequency(v.base_freq / 2)
				triangle.apply_pitch_offset(v.arp)

		"Noise":
			var offset = v.base_noise - v.arp
			
			while offset < 0:
				offset += 16
			noise.short = bool(fmod(v.duty,2))
			noise.set_note(offset)
			noise.set_volume(v.volume * vol_noise / 15)

# =========================================================
# LOAD SONG
# =========================================================
func load_song(song := "Menu Theme"):
	var file_path = "user://cache/music.json"

	if !FileAccess.file_exists(file_path):
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	file.close()

	song_data = json[song]
	song_meta = song_data["meta"]

	tempo = float(song_meta["FamiTrackerTempo"])
	speed = int(song_meta["FamiTrackerSpeed"])
	pattern_length = int(song_meta["PatternLength"])

	channel_state.clear()

	var channels = song_data["channels"]

	for c in channels.keys():
		var ch = channels[c]

		channel_state[c] = {
			"order": ch.get("order", []),
			"patterns": ch.get("patterns", {}),
			"instruments": ch.get("instruments", {}),
			"pattern_index": 0
		}

	row = 0
	tick_time = (speed * 60.0) / (tempo * 24.0)

# =========================================================
# NOTE TABLE
# =========================================================
func build_note_table():
	var notes = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
	var A4 = 440.0
	var A4_INDEX = 57

	for i in range(128):
		var freq = A4 * pow(2.0, (i - A4_INDEX) / 12.0)

		var octave = int(i / 12) - 1
		var notename = notes[i % 12] + str(octave)
		if octave > 7:
			return
		note_freq[notename] = freq

func build_noise_table():
	var notes = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]

	for i in range(128):

		var octave = int(i / 12)
		var notename = notes[i % 12] + str(octave)
		if octave > 7:
			return
		noise_freq[notename] = 15 - (fmod(i+1,16))
