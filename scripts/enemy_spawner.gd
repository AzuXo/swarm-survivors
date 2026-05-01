extends Node2D

@export var spawn_interval: float = 0.4
@export var spawn_distance: float = 600.0
@export var min_interval: float = 0.05
@export var ramp_per_second: float = 0.008
@export var hp_scale_per_second: float = 0.025
@export var boss_interval: float = 120.0

const Grunt = preload("res://scenes/enemy.tscn")
const Swarmer = preload("res://scenes/enemy_swarmer.tscn")
const Brute = preload("res://scenes/enemy_brute.tscn")
const Boss = preload("res://scenes/boss.tscn")

var _spawn_table: Array = [
	{"scene": Grunt,   "weight": 5, "min_elapsed": 0.0},
	{"scene": Swarmer, "weight": 3, "min_elapsed": 15.0},
	{"scene": Brute,   "weight": 1, "min_elapsed": 45.0},
]

var time_to_spawn: float = 0.0
var elapsed: float = 0.0
var player: Node2D
var _next_boss_at: float
var _bosses_spawned: int = 0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	_next_boss_at = boss_interval

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= _next_boss_at:
		_spawn_boss()
		_next_boss_at += boss_interval
	time_to_spawn -= delta
	if time_to_spawn <= 0.0:
		_spawn()
		time_to_spawn = maxf(min_interval, spawn_interval - elapsed * ramp_per_second)

func _spawn() -> void:
	if not is_instance_valid(player):
		return
	var scene := _pick_enemy_scene()
	var enemy = scene.instantiate()
	var angle := randf() * TAU
	enemy.global_position = player.global_position + Vector2.RIGHT.rotated(angle) * spawn_distance
	enemy.max_health = int(enemy.max_health * (1.0 + elapsed * hp_scale_per_second))
	get_tree().current_scene.add_child(enemy)

func _spawn_boss() -> void:
	if not is_instance_valid(player):
		return
	_bosses_spawned += 1
	var boss = Boss.instantiate()
	var angle := randf() * TAU
	boss.global_position = player.global_position + Vector2.RIGHT.rotated(angle) * spawn_distance
	boss.max_health = int(boss.max_health * _bosses_spawned * (1.0 + elapsed * hp_scale_per_second))
	get_tree().current_scene.add_child(boss)

func _pick_enemy_scene() -> PackedScene:
	var total_weight: int = 0
	for e in _spawn_table:
		if elapsed >= float(e["min_elapsed"]):
			total_weight += int(e["weight"])
	if total_weight == 0:
		return Grunt
	var r: int = randi() % total_weight
	for e in _spawn_table:
		if elapsed >= float(e["min_elapsed"]):
			r -= int(e["weight"])
			if r < 0:
				return e["scene"] as PackedScene
	return Grunt
