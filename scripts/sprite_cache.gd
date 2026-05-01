class_name SpriteCache
extends Object

static var _cache: Dictionary = {}

static func get_frames(char_id: String, idle_count: int, walk_count: int, walk_prefix: String = "walk") -> SpriteFrames:
	if _cache.has(char_id):
		return _cache[char_id]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	if idle_count > 0:
		sf.add_animation("idle")
		sf.set_animation_loop("idle", true)
		sf.set_animation_speed("idle", 6.0)
		for i in range(idle_count):
			var tex: Texture2D = load("res://assets/sprites/%s/idle_%d.png" % [char_id, i])
			sf.add_frame("idle", tex)
	if walk_count > 0:
		sf.add_animation("walk")
		sf.set_animation_loop("walk", true)
		sf.set_animation_speed("walk", 12.0)
		for i in range(walk_count):
			var tex: Texture2D = load("res://assets/sprites/%s/%s_%d.png" % [char_id, walk_prefix, i])
			sf.add_frame("walk", tex)
	if idle_count == 0 and walk_count > 0:
		sf.add_animation("idle")
		sf.set_animation_loop("idle", true)
		sf.set_animation_speed("idle", 6.0)
		for i in range(walk_count):
			var tex: Texture2D = load("res://assets/sprites/%s/%s_%d.png" % [char_id, walk_prefix, i])
			sf.add_frame("idle", tex)
	_cache[char_id] = sf
	return sf
