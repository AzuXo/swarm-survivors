extends Area2D

@export var duration: float = 5.0

func _ready() -> void:
	add_to_group("power_pickup")
	body_entered.connect(_on_body_entered)

func _draw() -> void:
	draw_rect(Rect2(-10, -10, 20, 20), Color(1.0, 0.55, 0.1))
	draw_rect(Rect2(-10, -10, 20, 20), Color(1.0, 0.9, 0.4), false, 2.0)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("activate_power"):
		body.activate_power(duration)
		SFX.play("pickup", -6.0, 1.2)
		queue_free()
