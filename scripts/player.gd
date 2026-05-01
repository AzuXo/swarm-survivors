extends CharacterBody2D

@export var speed: float = 250.0
@export var max_health: int = 100
@export var fire_rate: float = 1.5
@export var projectile_damage: int = 10
@export var projectile_speed: float = 500.0

@export var power_fire_rate_mult: float = 2.0
@export var power_damage_mult: float = 1.5
@export var power_spread_count: int = 3
@export var power_spread_arc_deg: float = 30.0

@export var missile_count: int = 0
@export var missile_fire_rate: float = 0.5
@export var missile_damage: int = 35
@export var missile_speed: float = 350.0

var health: int
var xp: int = 0
var level: int = 1
var xp_to_next_level: int = 5
var fire_cooldown: float = 0.0
var missile_cooldown: float = 0.0
var power_time: float = 0.0
var pending_level_ups: int = 0
var _was_powered: bool = false
var _hit_flash_time: float = 0.0
var _shake_time: float = 0.0
var _shake_max_time: float = 0.0
var _shake_intensity: float = 0.0

const Projectile = preload("res://scenes/projectile.tscn")
const OrbitingWeapon = preload("res://scenes/orbiting_weapon.tscn")
const DamageAura = preload("res://scenes/damage_aura.tscn")
const HomingMissile = preload("res://scenes/homing_missile.tscn")
const SPRITE_SCALE := 0.4

var _sprite: AnimatedSprite2D

var orbiting_weapon: Node2D
var damage_aura: Area2D

signal health_changed(current, maximum)
signal xp_changed(current, to_next, level)
signal leveled_up
signal died

func _ready() -> void:
	_apply_meta_upgrades()
	health = max_health
	add_to_group("player")
	_setup_sprite()
	orbiting_weapon = OrbitingWeapon.instantiate()
	orbiting_weapon.name = "OrbitingWeapon"
	add_child(orbiting_weapon)
	damage_aura = DamageAura.instantiate()
	damage_aura.name = "DamageAura"
	add_child(damage_aura)
	_apply_meta_starting_weapons()
	health_changed.emit(health, max_health)
	xp_changed.emit(xp, xp_to_next_level, level)

func _setup_sprite() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteCache.get_frames("player", 6, 8)
	_sprite.scale = Vector2.ONE * SPRITE_SCALE
	_sprite.play("idle")
	add_child(_sprite)

func _apply_meta_upgrades() -> void:
	max_health += Meta.get_level("max_hp") * 10
	speed *= 1.0 + float(Meta.get_level("speed")) * 0.05
	projectile_damage += Meta.get_level("damage")

func _apply_meta_starting_weapons() -> void:
	if Meta.get_level("start_orb") > 0:
		orbiting_weapon.orb_count = 1
		orbiting_weapon.rebuild()
	if Meta.get_level("start_aura") > 0:
		damage_aura.active = true
		damage_aura.refresh()
	if Meta.get_level("start_missile") > 0:
		missile_count = 1

func _physics_process(delta: float) -> void:
	var input_dir := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	).normalized()
	velocity = input_dir * speed
	move_and_slide()

	if input_dir.length_squared() > 0.0:
		if _sprite.animation != &"walk":
			_sprite.play("walk")
		if absf(input_dir.x) > 0.01:
			_sprite.flip_h = input_dir.x < 0.0
	else:
		if _sprite.animation != &"idle":
			_sprite.play("idle")

	if power_time > 0.0:
		power_time -= delta
	var is_powered := power_time > 0.0
	if is_powered != _was_powered:
		_was_powered = is_powered

	if _hit_flash_time > 0.0:
		_hit_flash_time -= delta
	_update_sprite_modulate(is_powered)

	if _shake_time > 0.0:
		_shake_time -= delta
		var cam: Camera2D = $Camera
		if _shake_time > 0.0:
			var amp: float = _shake_intensity * (_shake_time / _shake_max_time)
			cam.offset = Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
		else:
			cam.offset = Vector2.ZERO

	fire_cooldown -= delta
	if fire_cooldown <= 0.0:
		var target := _find_nearest_enemy()
		if target:
			_fire_at(target)
			var rate_mult := power_fire_rate_mult if is_powered else 1.0
			fire_cooldown = 1.0 / (fire_rate * rate_mult)

	if missile_count > 0:
		missile_cooldown -= delta
		if missile_cooldown <= 0.0:
			_fire_missiles()
			missile_cooldown = 1.0 / missile_fire_rate

func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist_sq := INF
	for e in get_tree().get_nodes_in_group("enemy"):
		var d: float = global_position.distance_squared_to(e.global_position)
		if d < nearest_dist_sq:
			nearest_dist_sq = d
			nearest = e
	return nearest

func _fire_at(target: Node2D) -> void:
	var dir := (target.global_position - global_position).normalized()
	if power_time > 0.0:
		var dmg := int(projectile_damage * power_damage_mult)
		var n := maxi(1, power_spread_count)
		var arc := deg_to_rad(power_spread_arc_deg)
		for i in range(n):
			var t := 0.0 if n == 1 else float(i) / float(n - 1) - 0.5
			_spawn_projectile(dir.rotated(t * arc), dmg)
	else:
		_spawn_projectile(dir, projectile_damage)

func _spawn_projectile(dir: Vector2, dmg: int) -> void:
	var p = Projectile.instantiate()
	p.global_position = global_position
	p.velocity = dir * projectile_speed
	p.damage = dmg
	get_tree().current_scene.add_child(p)
	SFX.play("shoot", -22.0, randf_range(0.95, 1.05))

func _fire_missiles() -> void:
	var enemies: Array = _find_n_nearest_enemies(missile_count)
	for i in range(missile_count):
		var m = HomingMissile.instantiate()
		m.damage = missile_damage
		m.speed = missile_speed
		if i < enemies.size():
			m.target = enemies[i]
		else:
			m.velocity = Vector2.RIGHT.rotated(randf() * TAU) * missile_speed
		m.global_position = global_position
		get_tree().current_scene.add_child(m)
	SFX.play("missile", -10.0)

func _find_n_nearest_enemies(n: int) -> Array:
	var enemies: Array = get_tree().get_nodes_in_group("enemy").duplicate()
	var pos := global_position
	enemies.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return pos.distance_squared_to(a.global_position) < pos.distance_squared_to(b.global_position)
	)
	var k: int = mini(n, enemies.size())
	return enemies.slice(0, k)

func activate_power(duration: float) -> void:
	power_time = maxf(power_time, duration)

func take_damage(amount: int) -> void:
	health -= amount
	_hit_flash_time = 0.1
	shake_camera(4.0, 0.15)
	SFX.play("player_hit", -2.0)
	health_changed.emit(health, max_health)
	if health <= 0:
		died.emit()

func _update_sprite_modulate(is_powered: bool) -> void:
	if _sprite == null:
		return
	if _hit_flash_time > 0.0:
		_sprite.modulate = Color(1.6, 0.5, 0.5)
	elif is_powered:
		_sprite.modulate = Color(1.3, 0.95, 0.65)
	else:
		_sprite.modulate = Color.WHITE

func shake_camera(intensity: float, duration: float) -> void:
	if duration > _shake_time or intensity > _shake_intensity:
		_shake_time = duration
		_shake_max_time = duration
		_shake_intensity = intensity

func heal(amount: int) -> void:
	if health <= 0:
		return
	health = mini(health + amount, max_health)
	health_changed.emit(health, max_health)

func add_xp(amount: int) -> void:
	xp += amount
	var was_zero: bool = pending_level_ups == 0
	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level += 1
		xp_to_next_level = int(xp_to_next_level * 1.4)
		pending_level_ups += 1
	xp_changed.emit(xp, xp_to_next_level, level)
	if was_zero and pending_level_ups > 0:
		leveled_up.emit()
