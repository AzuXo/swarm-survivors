extends Node2D

@export var orb_count: int = 0
@export var radius: float = 70.0
@export var rotation_speed: float = 3.0
@export var orb_damage: int = 8

const Orb = preload("res://scenes/orb.tscn")

func _ready() -> void:
	rebuild()

func _process(delta: float) -> void:
	rotation += rotation_speed * delta

func rebuild() -> void:
	for child in get_children():
		child.queue_free()
	if orb_count <= 0:
		return
	for i in range(orb_count):
		var orb = Orb.instantiate()
		orb.damage = orb_damage
		var angle: float = TAU * float(i) / float(orb_count)
		orb.position = Vector2.RIGHT.rotated(angle) * radius
		add_child(orb)
