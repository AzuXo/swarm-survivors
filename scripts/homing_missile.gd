extends Area2D

@export var damage: int = 35
@export var speed: float = 350.0
@export var turn_rate_deg: float = 360.0
@export var lifetime: float = 4.0

var velocity: Vector2 = Vector2.ZERO
var target: Node2D

func _ready() -> void:
	add_to_group("missile")
	body_entered.connect(_on_body_entered)
	if velocity == Vector2.ZERO and target != null:
		velocity = (target.global_position - global_position).normalized() * speed

func _draw() -> void:
	var pts := PackedVector2Array([
		Vector2(8, 0),
		Vector2(-4, -4),
		Vector2(-2, 0),
		Vector2(-4, 4),
	])
	draw_colored_polygon(pts, Color(1.0, 0.5, 0.2))
	draw_circle(Vector2(-2, 0), 2.0, Color(1.0, 0.95, 0.6))

func _physics_process(delta: float) -> void:
	if is_instance_valid(target):
		var desired := target.global_position - global_position
		var max_turn := deg_to_rad(turn_rate_deg) * delta
		var ang := velocity.angle_to(desired)
		velocity = velocity.rotated(clampf(ang, -max_turn, max_turn))
	global_position += velocity * delta
	rotation = velocity.angle()
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		body.take_damage(damage)
		queue_free()
