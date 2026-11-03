extends Node
## Device preferences are independent of adventure saves.
var master_volume: float = 0.8
var effects_volume: float = 0.7
var fullscreen: bool = false
var player: AudioStreamPlayer
const SETTINGS_PATH = "user://settings.cfg"

func _ready() -> void:
 if AudioServer.get_bus_index("Effects") < 0:
  AudioServer.add_bus()
  AudioServer.set_bus_name(AudioServer.bus_count - 1, "Effects")
  AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
 player = AudioStreamPlayer.new()
 player.bus = "Effects"
 add_child(player)
 var sample = AudioStreamWAV.new()
 sample.format = AudioStreamWAV.FORMAT_16_BITS
 sample.mix_rate = 22050
 var pcm = PackedByteArray()
 pcm.resize(2206)
 for i in range(1103):
  var t = float(i) / 22050.0
  var envelope = pow(1.0 - float(i) / 1103.0, 2.0)
  pcm.encode_s16(i * 2, int(sin(TAU * 660.0 * t) * envelope * 4500.0))
 sample.data = pcm
 player.stream = sample
 load_settings()

func load_settings(path: String = SETTINGS_PATH) -> void:
 var config = ConfigFile.new()
 if config.load(path) == OK:
  master_volume = clampf(float(config.get_value("audio", "master", 0.8)), 0.0, 1.0)
  effects_volume = clampf(float(config.get_value("audio", "effects", 0.7)), 0.0, 1.0)
  fullscreen = bool(config.get_value("display", "fullscreen", false))
 apply_audio()
 apply_display()

func save_settings(path: String = SETTINGS_PATH) -> Error:
 var config = ConfigFile.new()
 config.set_value("audio", "master", master_volume)
 config.set_value("audio", "effects", effects_volume)
 config.set_value("display", "fullscreen", fullscreen)
 return config.save(path)

func set_volume(channel: String, value: float) -> void:
 if channel == "master": master_volume = clampf(value, 0.0, 1.0)
 else: effects_volume = clampf(value, 0.0, 1.0)
 apply_audio()
 save_settings()

func apply_audio() -> void:
 for entry in [["Master", master_volume], ["Effects", effects_volume]]:
  var index = AudioServer.get_bus_index(entry[0])
  if index < 0: continue
  AudioServer.set_bus_volume_db(index, linear_to_db(maxf(entry[1], 0.0001)))
  AudioServer.set_bus_mute(index, entry[1] <= 0.0)

func apply_display() -> void:
 if DisplayServer.get_name() == "headless": return
 DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func set_fullscreen(enabled: bool) -> void:
 fullscreen = enabled
 apply_display()
 save_settings()

func play_click() -> void:
 if is_instance_valid(player): player.play()
