extends Area2D

@export var damage: int = 8
@export var hit_cooldown: float = 0.4

var _hit_cooldowns: Dictionary = {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 8, Color(0.6, 0.4, 1.0))
	draw_circle(Vector2.ZERO, 8, Color(0.95, 0.85, 1.0), false, 1.5)

func _process(delta: float) -> void:
	var to_remove: Array = []
	for k in _hit_cooldowns.keys():
		var t: float = _hit_cooldowns[k]
		t -= delta
		if t <= 0.0:
			to_remove.append(k)
		else:
			_hit_cooldowns[k] = t
	for k in to_remove:
		_hit_cooldowns.erase(k)

func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("enemy"):
			_try_hit(body)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		_try_hit(body)

func _try_hit(body: Node) -> void:
	if _hit_cooldowns.has(body):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
		_hit_cooldowns[body] = hit_cooldown
