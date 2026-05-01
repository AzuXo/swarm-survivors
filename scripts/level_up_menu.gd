extends CanvasLayer

signal upgrade_chosen(upgrade)

@onready var container: VBoxContainer = $Panel/VBox

func show_choices(choices: Array) -> void:
	visible = true
	for child in container.get_children():
		child.queue_free()
	for c in choices:
		var b := Button.new()
		b.text = c.name
		b.custom_minimum_size = Vector2(300, 50)
		b.pressed.connect(_on_choice.bind(c))
		container.add_child(b)

func _on_choice(c) -> void:
	visible = false
	upgrade_chosen.emit(c)
