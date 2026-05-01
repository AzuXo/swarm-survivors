extends Area2D

@export var xp_value: int = 1
@export var pull_speed: float = 400.0
@export var pull_radius: float = 100.0

var player: Node2D

func _ready() -> void:
	add_to_group("xp_gem")
	body_entered.connect(_on_body_entered)
	player = get_tree().get_first_node_in_group("player")

func _draw() -> void:
	var pts := PackedVector2Array([
		Vector2(0, -7), Vector2(7, 0), Vector2(0, 7), Vector2(-7, 0)
	])
	draw_colored_polygon(pts, Color(0.3, 0.7, 1.0))

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var to_player := player.global_position - global_position
	if to_player.length() < pull_radius:
		global_position += to_player.normalized() * pull_speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.add_xp(xp_value)
		SFX.play("pickup", -18.0, 1.6)
		queue_free()
