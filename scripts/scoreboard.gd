extends Control

@onready var rows_container: VBoxContainer = $VBox/Scroll/Rows
@onready var back_button: Button = $VBox/BackButton

func _ready() -> void:
	SFX.play_menu_music()
	back_button.pressed.connect(_on_back_pressed)
	_build()

func _build() -> void:
	for child in rows_container.get_children():
		child.queue_free()
	if Meta.scores.is_empty():
		var lbl := Label.new()
		lbl.text = "No scores yet — survive a run to set one!"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.modulate = Color(0.7, 0.7, 0.75)
		rows_container.add_child(lbl)
		return
	for i in range(Meta.scores.size()):
		rows_container.add_child(_make_row(i))

func _make_row(idx: int) -> HBoxContainer:
	var s: Dictionary = Meta.scores[idx]
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 40)
	row.add_theme_constant_override("separation", 12)

	var rank := Label.new()
	rank.custom_minimum_size = Vector2(60, 0)
	rank.text = "#%d" % (idx + 1)
	rank.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rank.add_theme_font_size_override("font_size", 20)
	if idx == 0:
		rank.modulate = Color(1.0, 0.85, 0.2)

	var name_label := Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text = String(s.get("name", "Player"))
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)

	var time_label := Label.new()
	time_label.custom_minimum_size = Vector2(100, 0)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 18)
	var t: float = float(s["time"])
	var mm: int = int(t / 60.0)
	var ss: int = int(t) % 60
	time_label.text = "%d:%02d" % [mm, ss]

	row.add_child(rank)
	row.add_child(name_label)
	row.add_child(time_label)
	return row

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")
