extends Node2D

@export var pickup_scene: PackedScene
@export var spawn_interval: float = 12.0
@export var min_distance: float = 200.0
@export var max_distance: float = 400.0

var time_to_spawn: float
var player: Node2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	time_to_spawn = spawn_interval

func _process(delta: float) -> void:
	time_to_spawn -= delta
	if time_to_spawn <= 0.0:
		_spawn()
		time_to_spawn = spawn_interval

func _spawn() -> void:
	if not is_instance_valid(player) or pickup_scene == null:
		return
	var pickup = pickup_scene.instantiate()
	var angle := randf() * TAU
	var dist := randf_range(min_distance, max_distance)
	pickup.global_position = player.global_position + Vector2.RIGHT.rotated(angle) * dist
	get_tree().current_scene.add_child(pickup)
