extends Node
## Device preferences are independent of adventure saves.
const DEFAULT_MASTER_VOLUME = 0.8
const DEFAULT_MUSIC_VOLUME = 1.0
const DEFAULT_EFFECTS_VOLUME = 0.7
var master_volume: float = DEFAULT_MASTER_VOLUME
var music_volume: float = DEFAULT_MUSIC_VOLUME
var effects_volume: float = DEFAULT_EFFECTS_VOLUME
var fullscreen: bool = false
var player: AudioStreamPlayer
var menu_music_player: AudioStreamPlayer
const MENU_MUSIC = preload("res://Game/Assets/Audio/BGM/The+World-Saving+Heroic+Quest.ogg")
const SETTINGS_PATH = "user://settings.cfg"

func _ready() -> void:
 _ensure_audio_bus("Music")
 _ensure_audio_bus("Effects")
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
 # 背景音乐走独立总线，可分别调节背景音乐音量与总音量。
 menu_music_player = AudioStreamPlayer.new()
 menu_music_player.name = "MenuBGM"
 menu_music_player.bus = "Music"
 menu_music_player.volume_db = -12.0
 var music = MENU_MUSIC.duplicate() as AudioStreamOggVorbis
 music.loop = true
 music.loop_offset = 0.0
 menu_music_player.stream = music
 add_child(menu_music_player)
 load_settings()

func _ensure_audio_bus(bus_name: String) -> void:
 if AudioServer.get_bus_index(bus_name) >= 0: return
 AudioServer.add_bus()
 AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
 AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")

func set_menu_music_enabled(enabled: bool) -> void:
 if enabled:
  if not menu_music_player.playing: menu_music_player.play()
 else:
  menu_music_player.stop()

func load_settings(path: String = SETTINGS_PATH) -> void:
 var config = ConfigFile.new()
 if config.load(path) == OK:
  master_volume = clampf(float(config.get_value("audio", "master", DEFAULT_MASTER_VOLUME)), 0.0, 1.0)
  music_volume = clampf(float(config.get_value("audio", "music", DEFAULT_MUSIC_VOLUME)), 0.0, 1.0)
  effects_volume = clampf(float(config.get_value("audio", "effects", DEFAULT_EFFECTS_VOLUME)), 0.0, 1.0)
  fullscreen = bool(config.get_value("display", "fullscreen", false))
 apply_audio()
 apply_display()

func save_settings(path: String = SETTINGS_PATH) -> Error:
 var config = ConfigFile.new()
 config.set_value("audio", "master", master_volume)
 config.set_value("audio", "music", music_volume)
 config.set_value("audio", "effects", effects_volume)
 config.set_value("display", "fullscreen", fullscreen)
 return config.save(path)

func set_volume(channel: String, value: float) -> void:
 match channel:
  "master": master_volume = clampf(value, 0.0, 1.0)
  "music": music_volume = clampf(value, 0.0, 1.0)
  "effects": effects_volume = clampf(value, 0.0, 1.0)
 apply_audio()
 save_settings()

func apply_audio() -> void:
 for entry in [["Master", master_volume], ["Music", music_volume], ["Effects", effects_volume]]:
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

func reset_defaults() -> void:
 master_volume = DEFAULT_MASTER_VOLUME
 music_volume = DEFAULT_MUSIC_VOLUME
 effects_volume = DEFAULT_EFFECTS_VOLUME
 fullscreen = false
 apply_audio()
 apply_display()
 save_settings()

func play_click() -> void:
 if is_instance_valid(player): player.play()
