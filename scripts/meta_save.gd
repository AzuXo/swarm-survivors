extends Node

const SAVE_PATH := "user://meta.cfg"

const UPGRADES := {
	"max_hp": {
		"name": "Max HP",
		"desc": "+10 max HP per level",
		"max_level": 5,
		"costs": [5, 10, 20, 35, 60],
	},
	"speed": {
		"name": "Move Speed",
		"desc": "+5% per level",
		"max_level": 5,
		"costs": [5, 10, 20, 35, 60],
	},
	"damage": {
		"name": "Base Damage",
		"desc": "+1 projectile damage per level",
		"max_level": 5,
		"costs": [5, 10, 20, 35, 60],
	},
	"start_orb": {
		"name": "Start with Orb",
		"desc": "Begin runs with 1 orbiting orb",
		"max_level": 1,
		"costs": [40],
	},
	"start_aura": {
		"name": "Start with Aura",
		"desc": "Begin runs with damage aura active",
		"max_level": 1,
		"costs": [50],
	},
	"start_missile": {
		"name": "Start with Missile",
		"desc": "Begin runs with 1 homing missile",
		"max_level": 1,
		"costs": [60],
	},
}

const MAX_SCORES: int = 10

var currency: int = 0
var levels: Dictionary = {}
var best_time: float = 0.0
var scores: Array = []
var player_name: String = "Player"

func _ready() -> void:
	load_data()

func get_level(id: String) -> int:
	return int(levels.get(id, 0))

func cost_for_next(id: String) -> int:
	var lvl: int = get_level(id)
	var def: Dictionary = UPGRADES[id]
	if lvl >= int(def["max_level"]):
		return -1
	var costs: Array = def["costs"]
	return int(costs[lvl])

func can_afford(id: String) -> bool:
	var c: int = cost_for_next(id)
	return c >= 0 and currency >= c

func purchase(id: String) -> bool:
	if not can_afford(id):
		return false
	currency -= cost_for_next(id)
	levels[id] = get_level(id) + 1
	save_data()
	return true

func add_currency(amount: int) -> void:
	currency += amount
	save_data()

func submit_score(time_seconds: float) -> bool:
	var is_new_best: bool = time_seconds > best_time
	if is_new_best:
		best_time = time_seconds
	scores.append({
		"name": player_name,
		"time": time_seconds,
	})
	scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["time"]) > float(b["time"])
	)
	if scores.size() > MAX_SCORES:
		scores.resize(MAX_SCORES)
	save_data()
	return is_new_best

func set_player_name(new_name: String) -> void:
	var trimmed: String = new_name.strip_edges()
	if trimmed.is_empty():
		return
	player_name = trimmed
	save_data()

func load_data() -> void:
	var cfg := ConfigFile.new()
	var err: int = cfg.load(SAVE_PATH)
	if err != OK:
		return
	currency = int(cfg.get_value("meta", "currency", 0))
	var saved: Variant = cfg.get_value("meta", "levels", {})
	if saved is Dictionary:
		levels = saved
	else:
		levels = {}
	best_time = float(cfg.get_value("meta", "best_time", 0.0))
	var saved_scores: Variant = cfg.get_value("meta", "scores", [])
	if saved_scores is Array:
		scores = saved_scores
	else:
		scores = []
	player_name = String(cfg.get_value("meta", "player_name", "Player"))

func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "currency", currency)
	cfg.set_value("meta", "levels", levels)
	cfg.set_value("meta", "best_time", best_time)
	cfg.set_value("meta", "scores", scores)
	cfg.set_value("meta", "player_name", player_name)
	cfg.save(SAVE_PATH)
