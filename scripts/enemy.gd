extends CharacterBody2D

@export var speed: float = 80.0
@export var max_health: int = 20
@export var contact_damage: int = 10
@export var damage_interval: float = 0.5
@export var xp_value: int = 1
@export var gem_drop_count: int = 1
@export var radius: float = 12.0
@export var color: Color = Color(0.85, 0.2, 0.25)
@export var is_boss: bool = false
@export var sprite_id: String = "enemy1"
@export var sprite_idle_count: int = 6
@export var sprite_walk_count: int = 8
@export var sprite_walk_prefix: String = "walk"
@export var sprite_scale: float = 0.4

var health: int
var damage_cd: float = 0.0
var player: Node2D
var _hit_flash_time: float = 0.0
var _sprite: AnimatedSprite2D

const XPGem = preload("res://scenes/xp_gem.tscn")
const DeathBurst = preload("res://scenes/death_burst.tscn")
const DamageNumber = preload("res://scenes/damage_number.tscn")

func _ready() -> void:
	health = max_health
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")
	_setup_sprite()

func _setup_sprite() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteCache.get_frames(sprite_id, sprite_idle_count, sprite_walk_count, sprite_walk_prefix)
	_sprite.scale = Vector2.ONE * sprite_scale
	_sprite.play("walk")
	add_child(_sprite)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var dir := (player.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

	if _sprite != null and absf(dir.x) > 0.01:
		_sprite.flip_h = dir.x < 0.0

	damage_cd -= delta
	if damage_cd <= 0.0 and global_position.distance_to(player.global_position) < 16.0 + radius:
		if player.has_method("take_damage"):
			player.take_damage(contact_damage)
			damage_cd = damage_interval

	if _hit_flash_time > 0.0:
		_hit_flash_time -= delta
		if _hit_flash_time <= 0.0 and _sprite != null:
			_sprite.modulate = Color.WHITE

func take_damage(amount: int) -> void:
	health -= amount
	_hit_flash_time = 0.08
	if _sprite != null:
		_sprite.modulate = Color(2.0, 2.0, 2.0)
	SFX.play("hit", -10.0, randf_range(0.9, 1.1))
	_spawn_damage_number(amount)
	if health <= 0:
		_die()

func _spawn_damage_number(amount: int) -> void:
	var dn = DamageNumber.instantiate()
	dn.amount = amount
	dn.global_position = global_position + Vector2(0, -radius - 4)
	get_tree().current_scene.add_child(dn)

func _die() -> void:
	_spawn_death_burst()
	if is_boss:
		SFX.play("boss_death", 0.0)
		if is_instance_valid(player) and player.has_method("shake_camera"):
			player.shake_camera(15.0, 0.4)
	else:
		SFX.play("kill", -8.0, randf_range(0.85, 1.15))
	for i in range(gem_drop_count):
		var gem = XPGem.instantiate()
		var offset: Vector2 = Vector2.ZERO
		if gem_drop_count > 1:
			offset = Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
		gem.global_position = global_position + offset
		gem.xp_value = xp_value
		get_tree().current_scene.add_child.call_deferred(gem)
	queue_free()

func _spawn_death_burst() -> void:
	var burst = DeathBurst.instantiate()
	burst.global_position = global_position
	if is_boss:
		burst.max_radius = 90.0
		burst.duration = 0.5
		burst.thickness = 6.0
		burst.color = Color(1.0, 0.4, 1.0)
	else:
		burst.max_radius = radius * 2.5
		burst.duration = 0.25
		burst.thickness = 3.0
		burst.color = color.lightened(0.4)
	get_tree().current_scene.add_child.call_deferred(burst)
