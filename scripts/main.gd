extends Node2D

@onready var player: Node = $Player
@onready var level_up_menu: CanvasLayer = $LevelUpMenu
@onready var hp_label: Label = $HUD/HPLabel
@onready var xp_label: Label = $HUD/XPLabel
@onready var time_label: Label = $HUD/TimeLabel
@onready var game_over_label: Label = $HUD/GameOverLabel
@onready var restart_button: Button = $HUD/RestartButton

var elapsed_time: float = 0.0

func _ready() -> void:
	SFX.play_game_music()
	player.health_changed.connect(_on_health_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.leveled_up.connect(_on_leveled_up)
	player.died.connect(_on_player_died)
	level_up_menu.upgrade_chosen.connect(_on_upgrade_chosen)
	restart_button.pressed.connect(_on_restart_pressed)
	game_over_label.visible = false
	restart_button.visible = false
	_update_time_label()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _process(delta: float) -> void:
	elapsed_time += delta
	_update_time_label()

func _update_time_label() -> void:
	var mm: int = int(elapsed_time / 60.0)
	var ss: int = int(elapsed_time) % 60
	time_label.text = "Time: %d:%02d" % [mm, ss]

func _on_health_changed(cur: int, maximum: int) -> void:
	hp_label.text = "HP: %d / %d" % [cur, maximum]

func _on_xp_changed(cur: int, to_next: int, lvl: int) -> void:
	xp_label.text = "Lv %d   XP: %d / %d" % [lvl, cur, to_next]

func _on_leveled_up() -> void:
	get_tree().paused = true
	SFX.play("level_up", -2.0)
	level_up_menu.show_choices(Upgrades.random_three(player))

func _on_upgrade_chosen(upgrade) -> void:
	Upgrades.apply(upgrade.id, player)
	player.pending_level_ups -= 1
	if player.pending_level_ups > 0:
		level_up_menu.show_choices(Upgrades.random_three(player))
	else:
		get_tree().paused = false

func _on_player_died() -> void:
	get_tree().paused = true
	var is_new_best: bool = Meta.submit_score(elapsed_time)
	var mm: int = int(elapsed_time / 60.0)
	var ss: int = int(elapsed_time) % 60
	var bm: int = int(Meta.best_time / 60.0)
	var bs: int = int(Meta.best_time) % 60
	var text: String = "GAME OVER\nSurvived %d:%02d\nBest: %d:%02d" % [mm, ss, bm, bs]
	if is_new_best:
		text += "\nNEW BEST!"
	game_over_label.text = text
	game_over_label.visible = true
	restart_button.visible = true
