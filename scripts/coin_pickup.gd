extends Area2D

@export var value: int = 1
@export var pull_speed: float = 350.0
@export var pull_radius: float = 90.0

var player: Node2D

func _ready() -> void:
	add_to_group("coin_pickup")
	body_entered.connect(_on_body_entered)
	player = get_tree().get_first_node_in_group("player")

func _draw() -> void:
	draw_circle(Vector2.ZERO, 8, Color(1.0, 0.85, 0.2))
	draw_circle(Vector2.ZERO, 8, Color(1.0, 1.0, 0.6), false, 1.5)
	draw_circle(Vector2.ZERO, 3, Color(1.0, 1.0, 0.85))

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var to_player := player.global_position - global_position
	if to_player.length() < pull_radius:
		global_position += to_player.normalized() * pull_speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		Meta.add_currency(value)
		SFX.play("pickup", -8.0, 1.4)
		queue_free()
