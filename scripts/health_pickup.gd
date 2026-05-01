extends Area2D

@export var heal_amount: int = 25

func _ready() -> void:
	add_to_group("health_pickup")
	body_entered.connect(_on_body_entered)

func _draw() -> void:
	var bg := Color(1.0, 1.0, 1.0)
	var fg := Color(0.95, 0.15, 0.25)
	draw_rect(Rect2(-11, -11, 22, 22), bg)
	draw_rect(Rect2(-9, -3, 18, 6), fg)
	draw_rect(Rect2(-3, -9, 6, 18), fg)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("heal"):
		body.heal(heal_amount)
		SFX.play("pickup", -6.0, 0.7)
		queue_free()
