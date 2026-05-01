extends Node2D

@export var duration: float = 0.55
@export var rise_speed: float = 70.0

var amount: int = 0
var _t: float = 0.0

func _ready() -> void:
	z_index = 10
	var label: Label = $Label
	label.text = str(amount)
	position.x += randf_range(-15.0, 15.0)
	position.y += randf_range(-4.0, 4.0)

func _process(delta: float) -> void:
	_t += delta
	position.y -= rise_speed * delta
	modulate.a = clampf(1.0 - _t / duration, 0.0, 1.0)
	if _t >= duration:
		queue_free()
