extends Area2D

@export var aura_radius: float = 80.0
@export var damage_per_tick: int = 4
@export var tick_interval: float = 0.5
@export var active: bool = false

var _tick_cd: float = 0.0
var _shape: CircleShape2D

func _ready() -> void:
	var col := $Collision as CollisionShape2D
	_shape = col.shape as CircleShape2D
	refresh()

func refresh() -> void:
	if _shape:
		_shape.radius = aura_radius
	monitoring = active
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	draw_circle(Vector2.ZERO, aura_radius, Color(0.4, 0.7, 1.0, 0.15))
	draw_circle(Vector2.ZERO, aura_radius, Color(0.5, 0.85, 1.0, 0.5), false, 2.0)

func _physics_process(delta: float) -> void:
	if not active:
		return
	_tick_cd -= delta
	if _tick_cd <= 0.0:
		_tick_cd = tick_interval
		for body in get_overlapping_bodies():
			if body.is_in_group("enemy") and body.has_method("take_damage"):
				body.take_damage(damage_per_tick)
