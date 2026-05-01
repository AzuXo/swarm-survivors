class_name Upgrades

const NAMES := {
	"damage": "+15% Damage",
	"fire_rate": "+20% Fire Rate",
	"speed": "+15% Move Speed",
	"health": "+25 Max Health",
	"proj_speed": "+25% Projectile Speed",
	"orb_add": "+1 Orbiting Orb",
	"orb_damage": "+25% Orb Damage",
	"orbit_speed": "+30% Orbit Speed",
	"aura_unlock": "Damage Aura",
	"aura_damage": "+25% Aura Damage",
	"aura_radius": "+20% Aura Radius",
	"missile_unlock": "+1 Homing Missile",
	"missile_damage": "+25% Missile Damage",
	"missile_rate": "+30% Missile Fire Rate",
}

static func random_three(p: Node) -> Array:
	var pool: Array = NAMES.keys()
	var has_orbs: bool = p != null and p.orbiting_weapon != null and p.orbiting_weapon.orb_count > 0
	if not has_orbs:
		pool.erase("orb_damage")
		pool.erase("orbit_speed")
	var has_aura: bool = p != null and p.damage_aura != null and p.damage_aura.active
	if not has_aura:
		pool.erase("aura_damage")
		pool.erase("aura_radius")
	var has_missiles: bool = p != null and p.missile_count > 0
	if not has_missiles:
		pool.erase("missile_damage")
		pool.erase("missile_rate")
	pool.shuffle()
	var result: Array = []
	for id in pool.slice(0, 3):
		result.append({"id": id, "name": NAMES[id]})
	return result

static func apply(id: String, p: Node) -> void:
	match id:
		"damage":
			p.projectile_damage = int(p.projectile_damage * 1.15) + 1
		"fire_rate":
			p.fire_rate *= 1.20
		"speed":
			p.speed *= 1.15
		"health":
			p.max_health += 25
			p.health = mini(p.health + 25, p.max_health)
			p.health_changed.emit(p.health, p.max_health)
		"proj_speed":
			p.projectile_speed *= 1.25
		"orb_add":
			if p.orbiting_weapon:
				p.orbiting_weapon.orb_count += 1
				p.orbiting_weapon.rebuild()
		"orb_damage":
			if p.orbiting_weapon:
				p.orbiting_weapon.orb_damage = int(p.orbiting_weapon.orb_damage * 1.25) + 1
				p.orbiting_weapon.rebuild()
		"orbit_speed":
			if p.orbiting_weapon:
				p.orbiting_weapon.rotation_speed *= 1.30
		"aura_unlock":
			if p.damage_aura:
				if not p.damage_aura.active:
					p.damage_aura.active = true
				else:
					p.damage_aura.damage_per_tick = int(p.damage_aura.damage_per_tick * 1.12) + 1
					p.damage_aura.aura_radius *= 1.05
				p.damage_aura.refresh()
		"aura_damage":
			if p.damage_aura:
				p.damage_aura.damage_per_tick = int(p.damage_aura.damage_per_tick * 1.25) + 1
		"aura_radius":
			if p.damage_aura:
				p.damage_aura.aura_radius *= 1.20
				p.damage_aura.refresh()
		"missile_unlock":
			p.missile_count += 1
		"missile_damage":
			p.missile_damage = int(p.missile_damage * 1.25) + 1
		"missile_rate":
			p.missile_fire_rate *= 1.30
