@tool
extends Node2D
class_name ElevatorPlatform

const TILESET_PNG_PATH := "res://resources/tilesets/tileset.png"
const CHAR_SHEET_PATH := "res://assets/sprites/characters/characters.png"

@export var is_active: bool = true:
	set(v):
		is_active = v
		_apply_step(_last_step if is_active else 0)

@export var show_passenger_robot: bool = true:
	set(v):
		show_passenger_robot = v
		if is_node_ready():
			_rebuild_visuals()

@export_range(0, 8) var passenger_robot_row: int = 4:
	set(v):
		passenger_robot_row = clampi(v, 0, 8)
		if is_node_ready():
			_rebuild_visuals()

@export var passenger_flip_h: bool = true:
	set(v):
		passenger_flip_h = v
		if is_node_ready():
			_rebuild_visuals()

@export var show_cables: bool = true:
	set(v):
		show_cables = v
		if is_node_ready():
			_rebuild_visuals()

@export var cable_top_offset_px: float = -72.0:
	set(v):
		cable_top_offset_px = v
		if is_node_ready():
			_rebuild_visuals()

@export_range(1, 24) var cable_height_tiles: int = 12:
	set(v):
		cable_height_tiles = maxi(1, v)
		if is_node_ready():
			_rebuild_visuals()

@export var step_offsets: Array[float] = [0.0, 8.0, 16.0, 24.0, 16.0, 8.0, 0.0, -8.0]

var _platform_body: StaticBody2D = null
var _passenger_sprite: AnimatedSprite2D = null
var _cables_root: Node2D = null
var _last_step: int = -1


func _ready() -> void:
	_rebuild_visuals()
	_apply_step(0)


func _process(_delta: float) -> void:
	var step := int(Time.get_ticks_msec() / 100.0) % 8
	if step != _last_step:
		_last_step = step
		_apply_step(step)


func set_active(active: bool) -> void:
	is_active = active


func _apply_step(step: int) -> void:
	var idx := posmod(step, 8)
	var dy: float = 0.0
	if is_active and step_offsets.size() > 0:
		dy = float(step_offsets[idx % step_offsets.size()])
	if is_instance_valid(_platform_body):
		_platform_body.position = Vector2(0.0, dy)
	if is_instance_valid(_passenger_sprite):
		_passenger_sprite.frame = idx


func _rebuild_visuals() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	_platform_body = null
	_passenger_sprite = null
	_cables_root = null

	var tile_tex: Texture2D = load(TILESET_PNG_PATH)
	var char_tex: Texture2D = load(CHAR_SHEET_PATH)
	if not tile_tex:
		return

	if show_cables:
		_cables_root = Node2D.new()
		_cables_root.name = "Cables"
		add_child(_cables_root)
		var left_at := AtlasTexture.new()
		left_at.atlas = tile_tex
		left_at.region = Rect2(6 * 16, 9 * 16, 16, 16)
		var right_at := AtlasTexture.new()
		right_at.atlas = tile_tex
		right_at.region = Rect2(7 * 16, 9 * 16, 16, 16)
		for i in range(cable_height_tiles):
			var cy := cable_top_offset_px + i * 16.0
			var sp_l := Sprite2D.new()
			sp_l.centered = false
			sp_l.texture = left_at
			sp_l.position = Vector2(0.0, cy)
			_cables_root.add_child(sp_l)
			var sp_r := Sprite2D.new()
			sp_r.centered = false
			sp_r.texture = right_at
			sp_r.position = Vector2(32.0, cy)
			_cables_root.add_child(sp_r)

	_platform_body = StaticBody2D.new()
	_platform_body.name = "PlatformBody"
	add_child(_platform_body)

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(44.0, 6.0)
	col.shape = rect
	col.position = Vector2(24.0, 19.0)
	col.one_way_collision = true
	_platform_body.add_child(col)

	if show_passenger_robot and char_tex:
		_passenger_sprite = AnimatedSprite2D.new()
		_passenger_sprite.name = "PassengerRobot"
		_passenger_sprite.centered = false
		_passenger_sprite.flip_h = passenger_flip_h
		_passenger_sprite.sprite_frames = _build_robot_frames(char_tex, passenger_robot_row)
		_passenger_sprite.animation = "loop"
		_passenger_sprite.position = Vector2(17.0, -16.0)
		_platform_body.add_child(_passenger_sprite)

	var plat_sp := Sprite2D.new()
	plat_sp.name = "PlatformSprite"
	plat_sp.centered = false
	var plat_at := AtlasTexture.new()
	plat_at.atlas = tile_tex
	plat_at.region = Rect2(7 * 16, 7 * 16, 48, 32)
	plat_sp.texture = plat_at
	_platform_body.add_child(plat_sp)


func _build_robot_frames(tex: Texture2D, row_idx: int) -> SpriteFrames:
	var y_start: int = 0 if row_idx == 0 else (row_idx * 32 - 2)
	var fh_px: int = 30 if row_idx == 0 else 32
	var sf := SpriteFrames.new()
	sf.add_animation("loop")
	sf.set_animation_loop("loop", true)
	sf.set_animation_speed("loop", 10.0)
	for step_i in range(8):
		var col: int = step_i % 4
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(2 + col * 16, y_start, 16, fh_px)
		sf.add_frame("loop", at)
	return sf
