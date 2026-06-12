extends Node

const CACHE_DIR := "user://cache/"
const MUSIC_FILE := CACHE_DIR + "music.json"
const INSTR_FILE := CACHE_DIR + "instruments.json"
const DPCM_FILE := CACHE_DIR + "dpcm.json"

@onready var node_2d: Node2D = $Node2D
@export var song : String = "Select Payment Type"

func _ready():
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)

	if FileAccess.file_exists(MUSIC_FILE) and FileAccess.file_exists(INSTR_FILE):
		print("Cache exists, skipping parse.")
		node_2d.load_song(song)
		return

	var file := FileAccess.open("user://select payment.txt", FileAccess.READ)
	var raw_text = file.get_as_text()
	file.close()

	var data := parse_famistudio(raw_text)

	save_json(MUSIC_FILE, data["songs"])
	save_json(INSTR_FILE, {
		"instruments": data["instruments"],
		"arpeggios": data["arpeggios"]
	})
	save_json(DPCM_FILE, data["dpcm"])
	
	node_2d.load_song(song)
	print("Export complete.")


# -----------------------------
# MAIN PARSER
# -----------------------------
func parse_famistudio(text: String) -> Dictionary:
	var lines := text.split("\n")

	var songs := {}
	var instruments := {}
	var arpeggios := {}
	var dpcm_samples := {}

	var mode := ""
	var current_song := ""
	var current_channel := ""
	var current_pattern := ""
	var current_instr := ""

	for line in lines:
		line = line.strip_edges()
		if line == "":
			continue
	
		# -------- DPCM SAMPLE --------
		if line.begins_with("DPCMSample"):
			mode = "dpcm"

			var name = get_attr(line, "Name")
			var folder = get_attr(line, "Folder")
			var data = get_attr(line, "Data")

			dpcm_samples[name] = {
				"folder": folder,
				"data": data
			}
			continue
	
		# -------- SONG --------
		if line.begins_with("Song "):
			mode = "song"
			current_song = get_attr(line, "Name")

			songs[current_song] = {
				"meta": parse_attrs(line),
				"loopPoint": int(get_attr(line, "LoopPoint", "-1")),
				"channels": {}
			}
			continue

		if mode == "song" and line.begins_with("Channel Type="):
			current_channel = get_attr(line, "Type")

			songs[current_song]["channels"][current_channel] = {
				"patterns": {},
				"order_raw": []
			}
			continue

		if mode == "song" and line.begins_with("Pattern Name="):
			current_pattern = get_attr(line, "Name")
			songs[current_song]["channels"][current_channel]["patterns"][current_pattern] = []
			continue

		if mode == "song" and line.begins_with("PatternInstance"):
			var time = int(get_attr(line, "Time"))
			var pat = get_attr(line, "Pattern")

			songs[current_song]["channels"][current_channel]["order_raw"].append({
				"time": time,
				"pattern": pat
			})
			continue

		if mode == "song" and line.begins_with("Note "):
			songs[current_song]["channels"][current_channel]["patterns"][current_pattern].append(parse_note(line))
			continue

		# -------- INSTRUMENT --------
		if line.begins_with("Instrument"):
			mode = "instrument"
			current_instr = get_attr(line, "Name")

			instruments[current_instr] = {
				"env": {
					"volume": [],
					"duty": [],
					"pitch": [],
					"arp": []
				},
				"envHold": {
					"volume": [-1, -1],
					"duty": [-1, -1],
					"pitch": [-1, -1],
					"arp": [-1, -1]
				},
				"dpcmMap": {}
			}
			continue

		if mode == "instrument" and line.begins_with("Envelope"):
			var env_type = get_attr(line, "Type")
			var values = parse_int_array(get_attr(line, "Values"))

			var loop = int(get_attr(line, "Loop", "-1"))
			var release = int(get_attr(line, "Release", "-1"))

			match env_type:
				"Volume":
					instruments[current_instr]["env"]["volume"] = values
					instruments[current_instr]["envHold"]["volume"] = [loop, release]

				"DutyCycle":
					instruments[current_instr]["env"]["duty"] = values
					instruments[current_instr]["envHold"]["duty"] = [loop, release]

				"Pitch":
					instruments[current_instr]["env"]["pitch"] = values
					instruments[current_instr]["envHold"]["pitch"] = [loop, release]

				"Arpeggio":
					instruments[current_instr]["env"]["arp"] = values
					instruments[current_instr]["envHold"]["arp"] = [loop, release]

			continue

		if mode == "instrument" and line.begins_with("DPCMMapping"):
			var note = get_attr(line, "Note")
			var sample = get_attr(line, "Sample")
			var pitch = int(get_attr(line, "Pitch", "0"))
			var loop = get_attr(line, "Loop", "False") == "True"

			instruments[current_instr]["dpcmMap"][note] = [
				sample,
				loop,
				pitch
			]
			continue

		# -------- ARPEGGIO --------
		if line.begins_with("Arpeggio"):
			var name = get_attr(line, "Name")
			arpeggios[name] = {"notes":parse_int_array(get_attr(line, "Values")),"loop":get_attr(line, "Loop")}
			continue

	# -------- FLATTEN PATTERN ORDER --------
	for song_name in songs.keys():
		for ch in songs[song_name]["channels"].keys():

			var raw = songs[song_name]["channels"][ch]["order_raw"]

			var max_time = 0
			for r in raw:
				if r["time"] > max_time:
					max_time = r["time"]

			var order = []
			order.resize(max_time + 1)

			for i in range(order.size()):
				order[i] = 0

			for r in raw:
				order[r["time"]] = r["pattern"]

			songs[song_name]["channels"][ch]["order"] = order
			songs[song_name]["channels"][ch].erase("order_raw")

	return {
		"songs": songs,
		"instruments": instruments,
		"arpeggios": arpeggios,
		"dpcm": dpcm_samples
	}


# -----------------------------
# HELPERS
# -----------------------------
func parse_note(line: String) -> Dictionary:
	var value = get_attr(line, "Value", "")
	
	var note := {
		"time": int(get_attr(line, "Time")),
		"value": value,
		"duration": int(get_attr(line, "Duration", "0")),
		"instrument": get_attr(line, "Instrument", ""),
		"arpeggio": get_attr(line, "Arpeggio", ""),

		"volume": int(get_attr(line, "Volume", "-1")),
		"duty": int(get_attr(line, "DutyCycle", "-1")),
		
		"attack": get_attr(line, "Attack", "True") != "False",
		"slide_target": null,
		"release": int(get_attr(line, "Release", "-1")),
		"fine_pitch": int(get_attr(line, "FinePitch", "0")),
		"volume_slide_target": null,

		# IMPORTANT
		"is_effect_only": value == ""
	}

	# optional fields
	var slide = get_attr(line, "SlideTarget", "")
	if slide != "":
		note["slide_target"] = slide

	var vol_slide = get_attr(line, "VolumeSlideTarget", "")
	if vol_slide != "":
		note["volume_slide_target"] = int(vol_slide)

	return note


func get_attr(line: String, key: String, default := "") -> String:
	var pattern := key + "=\""
	var start := line.find(pattern)
	if start == -1:
		return default
	start += pattern.length()
	var end := line.find("\"", start)
	if end == -1:
		return default
	return line.substr(start, end - start)


func parse_attrs(line: String) -> Dictionary:
	var out := {}
	var parts := line.split(" ")
	for p in parts:
		if p.find("=") != -1:
			var k := p.split("=")[0]
			var v := get_attr(line, k)
			out[k] = v
	return out


func parse_int_array(string: String) -> Array:
	var out := []
	for s in string.split(","):
		if s.strip_edges() != "":
			out.append(int(s))
	return out


func save_json(path: String, data):
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
