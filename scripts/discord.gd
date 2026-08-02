extends Node


# ATTENTION: Replace DotEnv.read_int("APPLICATION_ID") with your application ID.
# This only exist so I don't accidentally git push my ID.
var application_id: int = 1525345754959319040

var client := DiscordClient.new()

var start_time : int = Time.get_unix_time_from_system()

func _ready() -> void:
	client.set_application_id(application_id)
	client.add_log_callback(_on_log, DiscordLoggingSeverity.INFO)
	
	
	var activity := DiscordActivity.new()
	activity.set_type(DiscordActivityTypes.PLAYING)
	
	
	var timestamps := DiscordActivityTimestamps.new()
	timestamps.set_start(start_time)
	activity.set_timestamps(timestamps)
	
	var assets := DiscordActivityAssets.new()
	assets.set_large_image("surprise")
	assets.set_small_image("happy-face")
	assets.set_invite_cover_image("thumbnail")
	activity.set_assets(assets)
	
	activity.set_status_display_type(DiscordStatusDisplayTypes.STATE)

func _process(_delta: float) -> void:
	Discord.run_callbacks()

func _on_log(message: String, severity: DiscordLoggingSeverity.Enum) -> void:
	var enum_str: String = Discord.enum_to_string(severity, DiscordLoggingSeverity.id)
	
	print("[%s] %s" % [enum_str, message])

func set_activity(details:String="In Game",state:String="",imagekey:String=""):
	client.set_application_id(application_id)
	client.add_log_callback(_on_log, DiscordLoggingSeverity.INFO)
	
	var activity := DiscordActivity.new()
	activity.set_type(DiscordActivityTypes.PLAYING)
	
	activity.set_details(details)
	activity.set_state(state)
	
	if imagekey != "":
		var assets := DiscordActivityAssets.new()
		assets.set_small_image(imagekey.to_lower())
		assets.set_small_text(imagekey.capitalize())
		activity.set_assets(assets)
	
	activity.set_status_display_type(DiscordStatusDisplayTypes.STATE)
	
	var timestamps := DiscordActivityTimestamps.new()
	timestamps.set_start(start_time)
	activity.set_timestamps(timestamps)
