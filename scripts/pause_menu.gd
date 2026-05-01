extends CanvasLayer

const SETTINGS_PATH := "user://settings.cfg"
const MASTER_BUS := 0

@onready var resume_button: Button = $Panel/VBox/ResumeButton
@onready var quit_button: Button = $Panel/VBox/QuitButton
@onready var volume_slider: HSlider = $Panel/VBox/HBox/VolumeSlider
@onready var volume_percent: Label = $Panel/VBox/HBox/VolumePercent
@onready var music_slider: HSlider = $Panel/VBox/MusicHBox/MusicSlider
@onready var music_percent: Label = $Panel/VBox/MusicHBox/MusicPercent

func _ready() -> void:
	visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	var current_db: float = AudioServer.get_bus_volume_db(MASTER_BUS)
	var pct: float = clampf(db_to_linear(current_db) * 100.0, 0.0, 100.0)
	volume_slider.value = pct
	volume_percent.text = "%d%%" % int(pct)
	volume_slider.value_changed.connect(_on_volume_changed)
	var music_pct: float = SFX.get_music_volume_pct()
	music_slider.value = music_pct
	music_percent.text = "%d%%" % int(music_pct)
	music_slider.value_changed.connect(_on_music_changed)

func _on_music_changed(value: float) -> void:
	SFX.set_music_volume_pct(value)
	music_percent.text = "%d%%" % int(value)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _can_toggle():
			_toggle()
			get_viewport().set_input_as_handled()

func _can_toggle() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	if scene.has_node("LevelUpMenu"):
		var lum: CanvasLayer = scene.get_node("LevelUpMenu")
		if lum.visible:
			return false
	if scene.has_node("HUD/GameOverLabel"):
		var gol: Label = scene.get_node("HUD/GameOverLabel")
		if gol.visible:
			return false
	return true

func _toggle() -> void:
	if visible:
		_hide_menu()
	else:
		_show_menu()

func _show_menu() -> void:
	visible = true
	get_tree().paused = true

func _hide_menu() -> void:
	visible = false
	get_tree().paused = false

func _on_resume_pressed() -> void:
	_hide_menu()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")

func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(MASTER_BUS, _percent_to_db(value))
	volume_percent.text = "%d%%" % int(value)
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", value)
	cfg.save(SETTINGS_PATH)

func _percent_to_db(percent: float) -> float:
	if percent <= 0.0:
		return -80.0
	return linear_to_db(percent / 100.0)
