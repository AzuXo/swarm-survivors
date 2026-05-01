extends Node2D

@export var max_radius: float = 30.0
@export var duration: float = 0.25
@export var color: Color = Color(1.0, 1.0, 1.0)
@export var thickness: float = 3.0

var _t: float = 0.0

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var progress: float = _t / duration
	var r: float = max_radius * progress
	var c := color
	c.a = 1.0 - progress
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, c, thickness)
