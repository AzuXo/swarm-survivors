extends Control

const SETTINGS_PATH := "user://settings.cfg"
const MASTER_BUS := 0
const DEFAULT_VOLUME_PCT := 80.0

@onready var volume_slider: HSlider = $SettingsPanel/VBox/HBox/VolumeSlider
@onready var volume_percent: Label = $SettingsPanel/VBox/HBox/VolumePercent
@onready var music_slider: HSlider = $SettingsPanel/VBox/MusicHBox/MusicSlider
@onready var music_percent: Label = $SettingsPanel/VBox/MusicHBox/MusicPercent
@onready var name_field: LineEdit = $SettingsPanel/VBox/NameHBox/NameField
@onready var best_time_label: Label = $VBox/BestTimeLabel

func _ready() -> void:
	SFX.play_menu_music()
	$SettingsPanel.visible = false
	_load_settings()
	_load_music_into_slider()
	_update_best_time_label()
	name_field.text = Meta.player_name
	$VBox/StartButton.pressed.connect(_on_start_pressed)
	$VBox/UpgradesButton.pressed.connect(_on_upgrades_pressed)
	$VBox/ScoreboardButton.pressed.connect(_on_scoreboard_pressed)
	$VBox/SettingsButton.pressed.connect(_on_settings_pressed)
	$VBox/QuitButton.pressed.connect(_on_quit_pressed)
	$SettingsPanel/VBox/BackButton.pressed.connect(_on_back_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	music_slider.value_changed.connect(_on_music_changed)
	name_field.text_submitted.connect(_on_name_submitted)
	name_field.focus_exited.connect(_on_name_focus_exited)

func _load_music_into_slider() -> void:
	var pct: float = SFX.get_music_volume_pct()
	music_slider.value = pct
	music_percent.text = "%d%%" % int(pct)

func _on_music_changed(value: float) -> void:
	SFX.set_music_volume_pct(value)
	music_percent.text = "%d%%" % int(value)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_upgrades_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/meta_upgrade_menu.tscn")

func _on_scoreboard_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/scoreboard.tscn")

func _on_settings_pressed() -> void:
	$VBox.visible = false
	$SettingsPanel.visible = true

func _on_back_pressed() -> void:
	$SettingsPanel.visible = false
	$VBox.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_volume_changed(value: float) -> void:
	_apply_volume(value)
	_save_volume(value)

func _on_name_submitted(text: String) -> void:
	Meta.set_player_name(text)
	name_field.text = Meta.player_name
	name_field.release_focus()

func _on_name_focus_exited() -> void:
	Meta.set_player_name(name_field.text)
	name_field.text = Meta.player_name

func _apply_volume(percent: float) -> void:
	AudioServer.set_bus_volume_db(MASTER_BUS, _percent_to_db(percent))
	volume_percent.text = "%d%%" % int(percent)

func _percent_to_db(percent: float) -> float:
	if percent <= 0.0:
		return -80.0
	return linear_to_db(percent / 100.0)

func _update_best_time_label() -> void:
	if Meta.best_time > 0.0:
		var mm: int = int(Meta.best_time / 60.0)
		var ss: int = int(Meta.best_time) % 60
		best_time_label.text = "Best: %d:%02d" % [mm, ss]
	else:
		best_time_label.text = "Best: --"

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	var err: int = cfg.load(SETTINGS_PATH)
	var volume_pct: float = DEFAULT_VOLUME_PCT
	if err == OK:
		volume_pct = float(cfg.get_value("audio", "volume", DEFAULT_VOLUME_PCT))
	volume_slider.value = volume_pct
	_apply_volume(volume_pct)

func _save_volume(volume_pct: float) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", volume_pct)
	cfg.save(SETTINGS_PATH)
