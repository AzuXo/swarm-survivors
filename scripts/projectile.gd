extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 10
var lifetime: float = 2.0

func _ready() -> void:
	add_to_group("projectile")
	body_entered.connect(_on_body_entered)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 4, Color(1.0, 0.9, 0.2))

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		body.take_damage(damage)
		queue_free()
