extends Control

@onready var currency_label: Label = $VBox/CurrencyLabel
@onready var rows_container: VBoxContainer = $VBox/Scroll/Rows
@onready var back_button: Button = $VBox/BackButton

func _ready() -> void:
	SFX.play_menu_music()
	back_button.pressed.connect(_on_back_pressed)
	_build_rows()
	_refresh()

func _build_rows() -> void:
	for child in rows_container.get_children():
		child.queue_free()
	for id in Meta.UPGRADES.keys():
		rows_container.add_child(_make_row(id))

func _make_row(id: String) -> HBoxContainer:
	var def: Dictionary = Meta.UPGRADES[id]
	var hbox := HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 60)
	hbox.add_theme_constant_override("separation", 12)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = def["name"]
	name_label.add_theme_font_size_override("font_size", 18)
	var desc_label := Label.new()
	desc_label.text = def["desc"]
	desc_label.modulate = Color(0.75, 0.75, 0.78)
	info.add_child(name_label)
	info.add_child(desc_label)

	var level_label := Label.new()
	level_label.custom_minimum_size = Vector2(70, 0)
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.name = "LevelLabel"

	var buy_button := Button.new()
	buy_button.custom_minimum_size = Vector2(120, 0)
	buy_button.name = "BuyButton"
	buy_button.pressed.connect(_on_buy_pressed.bind(id))

	hbox.add_child(info)
	hbox.add_child(level_label)
	hbox.add_child(buy_button)
	hbox.set_meta("id", id)
	return hbox

func _on_buy_pressed(id: String) -> void:
	if Meta.purchase(id):
		SFX.play("level_up", -6.0, 1.4)
		_refresh()
	else:
		SFX.play("hit", -14.0, 0.6)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")

func _refresh() -> void:
	currency_label.text = "Coins: %d" % Meta.currency
	for row in rows_container.get_children():
		var id: String = row.get_meta("id")
		var def: Dictionary = Meta.UPGRADES[id]
		var lvl: int = Meta.get_level(id)
		var max_lvl: int = int(def["max_level"])
		var lvl_label := row.get_node("LevelLabel") as Label
		lvl_label.text = "%d / %d" % [lvl, max_lvl]
		var btn := row.get_node("BuyButton") as Button
		if lvl >= max_lvl:
			btn.text = "MAX"
			btn.disabled = true
		else:
			var cost: int = Meta.cost_for_next(id)
			btn.text = "Buy (%d)" % cost
			btn.disabled = Meta.currency < cost
