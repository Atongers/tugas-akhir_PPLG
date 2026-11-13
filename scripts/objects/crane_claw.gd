@tool
extends Node2D
class_name CraneClaw

const TILESET_PNG_PATH := "res://assets/tilesets/tileset.png"
const CHAR_SHEET_PATH := "res://assets/sprites/characters/characters.png"

const CLAW_Y_OFFSETS: Array[float] = [-16.0, -19.0, -22.0, -23.0, -20.0, -17.0, -14.0, -12.0]
const ROBOT_Y_OFFSETS: Array[float] = [2.0, -2.0, -4.0, -4.0, -2.0, 0.0, 4.0, 7.0]

@export var is_active: bool = true:
	set(v):
		is_active = v
		_apply_step(_last_step if is_active else 0)

@export var has_captured_robot: bool = true:
	set(v):
		has_captured_robot = v
		if is_node_ready():
			_rebuild_visuals()

@export_range(0, 8) var captured_robot_row: int = 4:
	set(v):
		captured_robot_row = clampi(v, 0, 8)
		if is_node_ready():
			_rebuild_visuals()

@export var show_upper_cable: bool = true:
	set(v):
		show_upper_cable = v
		if is_node_ready():
			_rebuild_visuals()

@export_range(1, 16) var cable_tiles_length: int = 7:
	set(v):
		cable_tiles_length = maxi(1, v)
		if is_node_ready():
			_rebuild_visuals()

@export var bug_reverse_mode: bool = false

var _claw_sprite: Sprite2D = null
var _robot_sprite: AnimatedSprite2D = null
var _last_step: int = -1


func _ready() -> void:
	_rebuild_visuals()
	_apply_step(0)


func _process(_delta: float) -> void:
	var step := int(Time.get_ticks_msec() / 100.0) % 8
	if step != _last_step:
		_last_step = step
		_apply_step(step)


func release_robot() -> void:
	bug_reverse_mode = false
	has_captured_robot = false
	if is_instance_valid(_claw_sprite):
		_claw_sprite.position.x = 0.0


func _apply_step(step: int) -> void:
	var idx := posmod(step, 8)
	var claw_dy: float = CLAW_Y_OFFSETS[idx] if is_active else CLAW_Y_OFFSETS[0]
	var rob_dy: float = ROBOT_Y_OFFSETS[idx] if is_active else ROBOT_Y_OFFSETS[0]
	var bug_dx: float = 0.0
	if bug_reverse_mode and is_active:
		bug_dx = -4.0 + (2.0 if idx % 2 == 0 else -2.0)
	if is_instance_valid(_claw_sprite):
		_claw_sprite.position = Vector2(bug_dx, claw_dy)
	if is_instance_valid(_robot_sprite):
		_robot_sprite.position = Vector2(-2.0 + bug_dx, rob_dy)
		_robot_sprite.frame = idx


func _rebuild_visuals() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	_claw_sprite = null
	_robot_sprite = null

	var tile_tex: Texture2D = load(TILESET_PNG_PATH)
	var char_tex: Texture2D = load(CHAR_SHEET_PATH)
	if not tile_tex:
		return

	if show_upper_cable:
		var mount_at := AtlasTexture.new()
		mount_at.atlas = tile_tex
		mount_at.region = Rect2(6 * 16, 10 * 16, 16, 16)
		var cable_at := AtlasTexture.new()
		cable_at.atlas = tile_tex
		cable_at.region = Rect2(6 * 16, 11 * 16, 16, 16)

		var mount_sp := Sprite2D.new()
		mount_sp.centered = false
		mount_sp.texture = mount_at
		mount_sp.position = Vector2(0.0, -cable_tiles_length * 16.0)
		add_child(mount_sp)

		for i in range(1, cable_tiles_length):
			var c_sp := Sprite2D.new()
			c_sp.centered = false
			c_sp.texture = cable_at
			c_sp.position = Vector2(0.0, -(cable_tiles_length - i) * 16.0)
			add_child(c_sp)

	if has_captured_robot and char_tex:
		_robot_sprite = AnimatedSprite2D.new()
		_robot_sprite.name = "CapturedRobot"
		_robot_sprite.centered = false
		_robot_sprite.sprite_frames = _build_flail_frames(char_tex, captured_robot_row)
		_robot_sprite.animation = "loop"
		_robot_sprite.position = Vector2(-2.0, ROBOT_Y_OFFSETS[0])
		add_child(_robot_sprite)

	_claw_sprite = Sprite2D.new()
	_claw_sprite.name = "ClawSprite"
	_claw_sprite.centered = false
	var claw_at := AtlasTexture.new()
	claw_at.atlas = tile_tex
	claw_at.region = Rect2(6 * 16, 11 * 16, 16, 32)
	_claw_sprite.texture = claw_at
	_claw_sprite.position = Vector2(0.0, CLAW_Y_OFFSETS[0])
	add_child(_claw_sprite)


func _build_flail_frames(tex: Texture2D, row_idx: int) -> SpriteFrames:
	var y_start: int = 0 if row_idx == 0 else (row_idx * 32 - 2)
	var fh_px: int = 30 if row_idx == 0 else 32
	var sf := SpriteFrames.new()
	sf.add_animation("loop")
	sf.set_animation_loop("loop", true)
	sf.set_animation_speed("loop", 10.0)
	for step_i in range(8):
		var col: int = 5 + step_i
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(2 + col * 16, y_start, 16, fh_px)
		sf.add_frame("loop", at)
	return sf
