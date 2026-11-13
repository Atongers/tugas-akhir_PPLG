@tool
extends Area2D
class_name LaserBeam

const TILESET_PNG_PATH := "res://assets/tilesets/tileset.png"

# Exact 8-frame patterns per cell index (0, 1, 2) for Orange and Blue lasers
const ORANGE_PATTERNS := [
	[[0,0,0], [1,1,1], [2,1,1], [0,0,1], [1,0,1], [0,1,0], [0,0,0], [0,1,1]],
	[[2,1,1], [2,0,1], [0,0,1], [2,0,0], [0,1,1], [2,0,0], [2,1,0], [2,0,0]],
	[[1,0,0], [0,1,1], [1,0,0], [1,1,1], [2,1,0], [1,1,1], [1,0,0], [1,1,0]],
]

const BLUE_VERT_PATTERNS := [
	[[4,1,1], [3,0,1], [5,1,1], [3,0,0], [4,1,1], [3,1,1], [4,1,1], [3,0,1]],
	[[3,0,1], [4,1,1], [3,1,0], [5,1,1], [3,0,1], [4,0,0], [5,1,1], [4,1,0]],
	[[5,1,0], [5,1,1], [4,0,0], [4,0,1], [5,1,0], [5,0,0], [3,0,0], [5,0,1]],
]

const BLUE_HORIZ_PATTERNS := [
	[[3,0,1], [5,0,0], [4,0,1], [5,0,0], [3,1,1], [3,0,1], [5,0,1], [4,0,1]],
	[[4,1,1], [3,1,1], [3,1,0], [4,1,0], [4,0,1], [4,1,1], [3,1,0], [5,1,0]],
	[[5,0,1], [4,0,1], [5,1,1], [3,0,0], [5,1,1], [5,0,1], [4,1,0], [3,1,1]],
]

@export_enum("Orange:0", "Blue:1") var laser_color: int = 0:
	set(v):
		laser_color = v
		if is_node_ready():
			_rebuild_visuals()

@export_enum("Vertical:0", "Horizontal:1") var orientation: int = 0:
	set(v):
		orientation = v
		if is_node_ready():
			_rebuild_visuals()

@export_range(1, 24) var length_tiles: int = 3:
	set(v):
		length_tiles = maxi(1, v)
		if is_node_ready():
			_rebuild_visuals()

@export var is_active: bool = true:
	set(v):
		is_active = v
		_update_active_state()

@export var cyclic_enabled: bool = false
@export_range(0.3, 6.0, 0.1) var cycle_on_duration: float = 1.6
@export_range(0.3, 6.0, 0.1) var cycle_off_duration: float = 1.4
@export var cycle_phase_offset: float = 0.0

var _segment_sprites: Array[Sprite2D] = []
var _col_shape: CollisionShape2D = null
var _atlas_cache: Dictionary = {}
var _last_step: int = -1
var _cycle_timer: float = 0.0
var _permanently_disabled: bool = false


func _ready() -> void:
	_rebuild_visuals()
	_cycle_timer = cycle_phase_offset
	_update_active_state()
	_apply_step(0)
	if not Engine.is_editor_hint():
		if not body_entered.is_connected(_on_body_entered):
			body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if not Engine.is_editor_hint() and cyclic_enabled and not _permanently_disabled:
		_cycle_timer += delta
		var total_period := maxf(0.2, cycle_on_duration + cycle_off_duration)
		var phase := fposmod(_cycle_timer, total_period)
		var should_be_active := phase < cycle_on_duration
		if should_be_active != is_active:
			is_active = should_be_active

	if not is_active:
		return
	var step := int(Time.get_ticks_msec() / 100.0) % 8
	if step != _last_step:
		_last_step = step
		_apply_step(step)


func set_active(active: bool) -> void:
	if not active:
		_permanently_disabled = true
		cyclic_enabled = false
	else:
		_permanently_disabled = false
	is_active = active


func _update_active_state() -> void:
	for sp in _segment_sprites:
		if is_instance_valid(sp):
			sp.visible = is_active
	if is_instance_valid(_col_shape):
		_col_shape.set_deferred("disabled", not is_active)


func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return
	if body.has_method("take_damage"):
		body.take_damage(25.0, "laser")
	elif body.has_method("respawn_at_checkpoint"):
		body.respawn_at_checkpoint()


func _get_tile_tex(tile_tex: Texture2D, tx: int) -> AtlasTexture:
	if _atlas_cache.has(tx):
		return _atlas_cache[tx]
	var at := AtlasTexture.new()
	at.atlas = tile_tex
	at.region = Rect2(tx * 16, 8 * 16, 16, 16)
	_atlas_cache[tx] = at
	return at


func _rebuild_visuals() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	_segment_sprites.clear()
	_col_shape = null

	var tile_tex: Texture2D = load(TILESET_PNG_PATH)
	if not tile_tex:
		return

	var is_horiz := (orientation == 1)
	for i in range(length_tiles):
		var sp := Sprite2D.new()
		sp.name = "Segment_%d" % i
		sp.centered = true
		if is_horiz:
			sp.position = Vector2(i * 16.0 + 8.0, 8.0)
		else:
			sp.position = Vector2(8.0, i * 16.0 + 8.0)
		add_child(sp)
		_segment_sprites.append(sp)

	_col_shape = CollisionShape2D.new()
	_col_shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	if is_horiz:
		rect.size = Vector2(length_tiles * 16.0, 6.0)
		_col_shape.position = Vector2(length_tiles * 8.0, 8.0)
	else:
		rect.size = Vector2(6.0, length_tiles * 16.0)
		_col_shape.position = Vector2(8.0, length_tiles * 8.0)
	_col_shape.shape = rect
	add_child(_col_shape)

	_update_active_state()
	_apply_step(_last_step if _last_step >= 0 else 0)


func _apply_step(step: int) -> void:
	var tile_tex: Texture2D = load(TILESET_PNG_PATH)
	if not tile_tex:
		return
	var idx := posmod(step, 8)
	var is_horiz := (orientation == 1)
	var patterns: Array = ORANGE_PATTERNS
	if laser_color == 1:
		patterns = BLUE_HORIZ_PATTERNS if is_horiz else BLUE_VERT_PATTERNS

	for i in range(_segment_sprites.size()):
		var sp := _segment_sprites[i]
		if not is_instance_valid(sp):
			continue
		var pat_row: Array = patterns[i % patterns.size()]
		var cell_state: Array = pat_row[idx]
		var tx := int(cell_state[0])
		var fh := int(cell_state[1]) != 0
		var fv := int(cell_state[2]) != 0
		sp.texture = _get_tile_tex(tile_tex, tx)
		if not is_horiz:
			sp.rotation = 0.0
			sp.scale = Vector2(1.0, 1.0)
			sp.flip_h = fh
			sp.flip_v = fv
		else:
			sp.rotation = PI * 0.5
			sp.scale = Vector2(1.0, -1.0)
			sp.flip_h = fv
			sp.flip_v = fh
