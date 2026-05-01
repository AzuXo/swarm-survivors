extends Node2D

@export var grid_size: float = 64.0
@export var color: Color = Color(0.13, 0.14, 0.18)
@export var line_width: float = 1.0

var camera: Camera2D

func _ready() -> void:
	z_index = -10

func _process(_delta: float) -> void:
	if camera == null or not is_instance_valid(camera):
		camera = get_viewport().get_camera_2d()
	queue_redraw()

func _draw() -> void:
	if camera == null:
		return
	var cam_pos := camera.get_screen_center_position()
	var viewport := get_viewport_rect().size
	var zoom := camera.zoom
	var half_w: float = (viewport.x * 0.5) / maxf(zoom.x, 0.001)
	var half_h: float = (viewport.y * 0.5) / maxf(zoom.y, 0.001)

	var x_start: float = floor((cam_pos.x - half_w) / grid_size) * grid_size
	var x_end: float = cam_pos.x + half_w + grid_size
	var y_start: float = floor((cam_pos.y - half_h) / grid_size) * grid_size
	var y_end: float = cam_pos.y + half_h + grid_size

	var x: float = x_start
	while x <= x_end:
		draw_line(Vector2(x, y_start), Vector2(x, y_end), color, line_width)
		x += grid_size
	var y: float = y_start
	while y <= y_end:
		draw_line(Vector2(x_start, y), Vector2(x_end, y), color, line_width)
		y += grid_size
