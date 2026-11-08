@tool
extends Node2D

const TILESET_PATH := "res://resources/tilesets/world_1_tileset.tres"
const TILESET_PNG_PATH := "res://resources/tilesets/tileset.png"
const CHAR_SHEET_PATH := "res://assets/sprites/characters/characters.png"
const BUBBLE_HELO_PATH := "res://assets/ui/bubble_helo_dave.png"
const BUBBLE_MEOW_PATH := "res://assets/ui/bubble_meow.png"
const BUBBLE_BIN_PATH := "res://assets/ui/bubble_binary.png"

const ANIM_FPS := 10.0
const ANIM_STEP_DURATION := 1.0 / ANIM_FPS
const DEX_SPAWN_POS := Vector2(579.0, 96.0)

# Exact 8-frame animation tables extracted 1:1 from map-animation.gif (10 FPS)
const EYE_TX := [7, 8, 9, 8, 7, 8, 9, 8]
const TERM1_TX := [10, 10, 11, 11, 11, 11, 10, 10]
const TERM2_TX := [11, 11, 10, 10, 10, 10, 11, 11]
const TERM3_TX := [11, 11, 11, 11, 10, 10, 10, 10]

const ELEV_Y := [120.0, 128.0, 136.0, 144.0, 136.0, 128.0, 120.0, 112.0]
const CRANE_CLAW_Y := [208.0, 205.0, 202.0, 201.0, 204.0, 207.0, 210.0, 212.0]
const CRANE_ROBOT_Y := [226.0, 222.0, 220.0, 220.0, 222.0, 224.0, 228.0, 231.0]

# Laser animation tables: each entry is [tx, flip_h (0/1), flip_v (0/1)] in row ty=8
const LASER_ORANGE_24_3 := [[0,0,0], [1,1,1], [2,1,1], [0,0,1], [1,0,1], [0,1,0], [0,0,0], [0,1,1]]
const LASER_ORANGE_24_4 := [[2,1,1], [2,0,1], [0,0,1], [2,0,0], [0,1,1], [2,0,0], [2,1,0], [2,0,0]]
const LASER_ORANGE_24_5 := [[1,0,0], [0,1,1], [1,0,0], [1,1,1], [2,1,0], [1,1,1], [1,0,0], [1,1,0]]

const LASER_BLUE_22_16 := [[4,1,1], [3,0,1], [5,1,1], [3,0,0], [4,1,1], [3,1,1], [4,1,1], [3,0,1]]
const LASER_BLUE_22_17 := [[3,0,1], [4,1,1], [3,1,0], [5,1,1], [3,0,1], [4,0,0], [5,1,1], [4,1,0]]
const LASER_BLUE_22_18 := [[5,1,0], [5,1,1], [4,0,0], [4,0,1], [5,1,0], [5,0,0], [3,0,0], [5,0,1]]

const LASER_BLUE_18_19 := [[3,0,1], [5,0,0], [4,0,1], [5,0,0], [3,1,1], [3,0,1], [5,0,1], [4,0,1]]
const LASER_BLUE_19_19 := [[4,1,1], [3,1,1], [3,1,0], [4,1,0], [4,0,1], [4,1,1], [3,1,0], [5,1,0]]
const LASER_BLUE_20_19 := [[5,0,1], [4,0,1], [5,1,1], [3,0,0], [5,1,1], [5,0,1], [4,1,0], [3,1,1]]

@export var rebuild_map_now: bool = false:
	set(_value):
		if is_node_ready():
			call_deferred("_build_all")

@onready var dex: CharacterBody2D = get_node_or_null("Dex")
@onready var bg_layer: TileMapLayer = get_node_or_null("BgLayer")
@onready var terrain_layer: TileMapLayer = get_node_or_null("TerrainLayer")
@onready var props_layer: TileMapLayer = get_node_or_null("PropsLayer")
@onready var overview_cam: Camera2D = get_node_or_null("OverviewCamera")
@onready var hud_status: Label = get_node_or_null("HUD/TopBar/Margin/HBox/StatusLabel")

var _is_overview_cam: bool = true
var _active_terminal_name: String = ""
var _anim_timer: float = 0.0
var _anim_step: int = 0
var _is_built: bool = false

var _tile_atlas_cache: Dictionary = {}
var _eye_sprite: Sprite2D = null
var _term1_sprite: Sprite2D = null
var _term2_top_sprite: Sprite2D = null
var _term2_bot_sprite: Sprite2D = null
var _term3_sprite: Sprite2D = null
var _laser_sprites: Dictionary = {}

var _elevator_body: StaticBody2D = null
var _elevator_robot: AnimatedSprite2D = null
var _crane_claw_sprite: Sprite2D = null
var _crane_robot_sprite: AnimatedSprite2D = null
var _bubble_helo_sprite: Sprite2D = null
var _synced_npcs: Array[AnimatedSprite2D] = []


func _ready() -> void:
	_build_all()
	if not Engine.is_editor_hint():
		_setup_runtime()


func _process(delta: float) -> void:
	if not _is_built:
		_build_all()
	_anim_timer += delta
	if _anim_timer >= ANIM_STEP_DURATION:
		var steps := int(_anim_timer / ANIM_STEP_DURATION)
		_anim_timer -= steps * ANIM_STEP_DURATION
		_anim_step = (_anim_step + steps) % 8
		_apply_animation_step(_anim_step)

	if not Engine.is_editor_hint() and is_instance_valid(_bubble_helo_sprite) and dex:
		_bubble_helo_sprite.visible = dex.global_position.distance_to(DEX_SPAWN_POS) < 28.0


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		_toggle_camera_mode()
	elif event.is_action_pressed("interact") and not _active_terminal_name.is_empty():
		if hud_status:
			hud_status.text = "Membuka " + _active_terminal_name + " (Tekan Tab untuk ganti kamera)"
			hud_status.modulate = Color(0.4, 1.0, 0.55)


func _toggle_camera_mode() -> void:
	_is_overview_cam = not _is_overview_cam
	var dex_cam: Camera2D = dex.get_node_or_null("Camera2D") if dex else null
	if _is_overview_cam and overview_cam:
		overview_cam.enabled = true
		overview_cam.make_current()
		if dex_cam:
			dex_cam.enabled = false
	elif dex_cam:
		dex_cam.enabled = true
		dex_cam.make_current()
		if overview_cam:
			overview_cam.enabled = false


func _setup_runtime() -> void:
	if overview_cam:
		overview_cam.enabled = true
		overview_cam.make_current()
	var dex_cam: Camera2D = dex.get_node_or_null("Camera2D") if dex else null
	if dex_cam:
		dex_cam.enabled = false


func _get_tile_tex(tile_tex: Texture2D, tx: int, ty: int) -> AtlasTexture:
	var key := Vector2i(tx, ty)
	if _tile_atlas_cache.has(key):
		return _tile_atlas_cache[key]
	var at := AtlasTexture.new()
	at.atlas = tile_tex
	at.region = Rect2(tx * 16, ty * 16, 16, 16)
	_tile_atlas_cache[key] = at
	return at


func _build_all() -> void:
	var ts: TileSet = load(TILESET_PATH)
	if not ts:
		return
	_configure_tileset_collisions(ts)

	bg_layer = get_node_or_null("BgLayer")
	terrain_layer = get_node_or_null("TerrainLayer")
	props_layer = get_node_or_null("PropsLayer")
	dex = get_node_or_null("Dex")
	if dex and Engine.is_editor_hint():
		dex.position = DEX_SPAWN_POS

	if bg_layer:
		bg_layer.tile_set = ts
		_populate_bg_layer(bg_layer)
	if terrain_layer:
		terrain_layer.tile_set = ts
		_populate_terrain_layer(terrain_layer)
	if props_layer:
		props_layer.tile_set = ts
		_populate_props_layer(props_layer)

	_populate_npcs_and_bubbles()
	_setup_terminals()
	_anim_step = 0
	_anim_timer = 0.0
	_is_built = true
	_apply_animation_step(0)


func _update_laser_sprite(key: Vector2i, data: Array, transposed: bool) -> void:
	if not _laser_sprites.has(key):
		return
	var sp: Sprite2D = _laser_sprites[key]
	if not is_instance_valid(sp):
		return
	var tile_tex: Texture2D = load(TILESET_PNG_PATH)
	sp.texture = _get_tile_tex(tile_tex, int(data[0]), 8)
	var fh := int(data[1]) != 0
	var fv := int(data[2]) != 0
	if not transposed:
		sp.rotation = 0.0
		sp.scale = Vector2(1.0, 1.0)
		sp.flip_h = fh
		sp.flip_v = fv
	else:
		# Godot TileMap transpose swaps X and Y axes (equivalent to 90-deg CW rotation + vertical flip)
		sp.rotation = PI * 0.5
		sp.scale = Vector2(1.0, -1.0)
		sp.flip_h = fv
		sp.flip_v = fh


func _apply_animation_step(step: int) -> void:
	var tile_tex: Texture2D = load(TILESET_PNG_PATH)
	if not tile_tex:
		return

	if is_instance_valid(_eye_sprite):
		_eye_sprite.texture = _get_tile_tex(tile_tex, EYE_TX[step], 6)

	if is_instance_valid(_term1_sprite):
		_term1_sprite.texture = _get_tile_tex(tile_tex, TERM1_TX[step], 12)
	if is_instance_valid(_term2_top_sprite):
		_term2_top_sprite.texture = _get_tile_tex(tile_tex, TERM2_TX[step], 10)
	if is_instance_valid(_term2_bot_sprite):
		_term2_bot_sprite.texture = _get_tile_tex(tile_tex, TERM2_TX[step], 11)
	if is_instance_valid(_term3_sprite):
		_term3_sprite.texture = _get_tile_tex(tile_tex, TERM3_TX[step], 12)

	# Lasers
	_update_laser_sprite(Vector2i(24, 3), LASER_ORANGE_24_3[step], false)
	_update_laser_sprite(Vector2i(24, 4), LASER_ORANGE_24_4[step], false)
	_update_laser_sprite(Vector2i(24, 5), LASER_ORANGE_24_5[step], false)

	_update_laser_sprite(Vector2i(22, 16), LASER_BLUE_22_16[step], false)
	_update_laser_sprite(Vector2i(22, 17), LASER_BLUE_22_17[step], false)
	_update_laser_sprite(Vector2i(22, 18), LASER_BLUE_22_18[step], false)

	_update_laser_sprite(Vector2i(18, 19), LASER_BLUE_18_19[step], true)
	_update_laser_sprite(Vector2i(19, 19), LASER_BLUE_19_19[step], true)
	_update_laser_sprite(Vector2i(20, 19), LASER_BLUE_20_19[step], true)

	# Elevator Platform + Robot #5 vertical motion
	if is_instance_valid(_elevator_body):
		_elevator_body.position = Vector2(96.0, ELEV_Y[step])
	if is_instance_valid(_elevator_robot):
		_elevator_robot.frame = step

	# Crane Claw + Hanging Robot #5 vertical motion & flailing animation
	if is_instance_valid(_crane_claw_sprite):
		_crane_claw_sprite.position = Vector2(528.0, CRANE_CLAW_Y[step])
	if is_instance_valid(_crane_robot_sprite):
		_crane_robot_sprite.position = Vector2(526.0, CRANE_ROBOT_Y[step])
		_crane_robot_sprite.frame = step

	# Sync all 8-frame NPC sprites to the master 10 FPS clock
	for npc in _synced_npcs:
		if is_instance_valid(npc):
			npc.frame = step


func _configure_tileset_collisions(ts: TileSet) -> void:
	if ts.get_physics_layers_count() == 0:
		ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 1)

	if not ts.has_source(0):
		return
	var atlas: TileSetAtlasSource = ts.get_source(0) as TileSetAtlasSource
	if not atlas:
		return

	# Skip if collisions are already configured on this TileSet resource
	if atlas.has_tile(Vector2i(1, 4)):
		var check_td: TileData = atlas.get_tile_data(Vector2i(1, 4), 0)
		if check_td and check_td.get_collision_polygons_count(0) > 0:
			return

	var full_box := PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
	])
	var top_half := PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 0), Vector2(-8, 0)
	])
	var bottom_half := PackedVector2Array([
		Vector2(-8, 0), Vector2(8, 0), Vector2(8, 8), Vector2(-8, 8)
	])
	var one_way_strip := PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, -2), Vector2(-8, -2)
	])

	var solid_coords: Array[Vector2i] = []
	for ry in range(1, 6):
		for rx in range(0, 7):
			solid_coords.append(Vector2i(rx, ry))
	for rx in range(7, 10):
		solid_coords.append(Vector2i(rx, 4))
	for ry in range(6, 8):
		for rx in range(2, 7):
			solid_coords.append(Vector2i(rx, ry))
	for rx in range(7, 10):
		solid_coords.append(Vector2i(rx, 6))
		solid_coords.append(Vector2i(rx, 13))

	for c in solid_coords:
		if atlas.has_tile(c):
			var td: TileData = atlas.get_tile_data(c, 0)
			if td:
				td.set_collision_polygons_count(0, 1)
				td.set_collision_polygon_points(0, 0, full_box)
				td.set_collision_polygon_one_way(0, 0, false)

	if atlas.has_tile(Vector2i(9, 0)):
		var td90: TileData = atlas.get_tile_data(Vector2i(9, 0), 0)
		td90.set_collision_polygons_count(0, 1)
		td90.set_collision_polygon_points(0, 0, top_half)
	if atlas.has_tile(Vector2i(9, 1)):
		var td91: TileData = atlas.get_tile_data(Vector2i(9, 1), 0)
		td91.set_collision_polygons_count(0, 1)
		td91.set_collision_polygon_points(0, 0, bottom_half)

	var slopes := {
		Vector2i(0, 6): PackedVector2Array([Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]),
		Vector2i(1, 6): PackedVector2Array([Vector2(-8, -8), Vector2(8, 8), Vector2(-8, 8)]),
		Vector2i(0, 7): PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8)]),
		Vector2i(1, 7): PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(-8, 8)]),
	}
	for sc in slopes.keys():
		if atlas.has_tile(sc):
			var tds: TileData = atlas.get_tile_data(sc, 0)
			tds.set_collision_polygons_count(0, 1)
			tds.set_collision_polygon_points(0, 0, slopes[sc])

	var one_way_coords: Array[Vector2i] = [
		Vector2i(7, 0), Vector2i(8, 0),
		Vector2i(7, 2), Vector2i(8, 2), Vector2i(9, 2),
		Vector2i(7, 3), Vector2i(8, 3), Vector2i(9, 3),
		Vector2i(7, 8), Vector2i(8, 8), Vector2i(9, 8),
	]
	for ow in one_way_coords:
		if atlas.has_tile(ow):
			var tdo: TileData = atlas.get_tile_data(ow, 0)
			tdo.set_collision_polygons_count(0, 1)
			tdo.set_collision_polygon_points(0, 0, one_way_strip)
			tdo.set_collision_polygon_one_way(0, 0, true)


func _populate_bg_layer(layer: TileMapLayer) -> void:
	layer.clear()
	for y in range(20, 25):
		for x in range(22, 32):
			layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 11))
	for y in range(17, 21):
		for x in range(39, 41):
			layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 11))

	var vents: Array[Vector2i] = [
		Vector2i(11, 9), Vector2i(13, 9),
		Vector2i(11, 11), Vector2i(13, 11),
		Vector2i(11, 16), Vector2i(13, 16), Vector2i(15, 16),
	]
	for v in vents:
		layer.set_cell(v, 0, Vector2i(3, 12))
		layer.set_cell(v + Vector2i(1, 0), 0, Vector2i(4, 12))
		layer.set_cell(v + Vector2i(0, 1), 0, Vector2i(3, 13))
		layer.set_cell(v + Vector2i(1, 1), 0, Vector2i(4, 13))

	var big_panels: Array[Vector2i] = [
		Vector2i(12, 3), Vector2i(14, 3), Vector2i(10, 4), Vector2i(12, 5),
	]
	for p in big_panels:
		layer.set_cell(p, 0, Vector2i(0, 12))
		layer.set_cell(p + Vector2i(1, 0), 0, Vector2i(1, 12))
		layer.set_cell(p + Vector2i(0, 1), 0, Vector2i(0, 13))
		layer.set_cell(p + Vector2i(1, 1), 0, Vector2i(1, 13))

	var quad_clusters: Array[Vector2i] = [
		Vector2i(31, 10), Vector2i(25, 16), Vector2i(34, 16),
	]
	for qc in quad_clusters:
		for dy in range(2):
			for dx in range(2):
				layer.set_cell(qc + Vector2i(dx, dy), 0, Vector2i(2, 12))

	var small_sq: Array[Vector2i] = [
		Vector2i(16, 4), Vector2i(17, 4), Vector2i(19, 4), Vector2i(19, 5), Vector2i(14, 5),
		Vector2i(17, 12), Vector2i(19, 12), Vector2i(21, 12), Vector2i(23, 12), Vector2i(25, 12), Vector2i(27, 12),
		Vector2i(19, 8), Vector2i(19, 10), Vector2i(21, 8),
	]
	for s in small_sq:
		layer.set_cell(s, 0, Vector2i(2, 11))

	var pillars: Array = [
		[5, 3, 14], [5, 16, 18],
		[9, 3, 14], [9, 16, 18],
		[17, 16, 18], [17, 23, 24],
		[21, 16, 18], [21, 22, 24],
		[24, 11, 14], [24, 16, 18],
		[28, 7, 9],
		[37, 11, 18],
		[44, 10, 12],
	]
	for pil in pillars:
		var px: int = pil[0]
		var y1: int = pil[1]
		var y2: int = pil[2]
		for y in range(y1, y2 + 1):
			var ty: int = 11 + ((y - y1) % 3)
			layer.set_cell(Vector2i(px, y), 0, Vector2i(5, ty))

	# Continuous Elevator cables from ceiling Y=3 to truss bridge Y=14
	for y in range(3, 15):
		layer.set_cell(Vector2i(6, y), 0, Vector2i(6, 9))
		layer.set_cell(Vector2i(8, y), 0, Vector2i(7, 9))

	# Hanging monitor cable & crane stationary upper cable (claw itself is animated in WorldDecor)
	layer.set_cell(Vector2i(26, 11), 0, Vector2i(6, 11))
	layer.set_cell(Vector2i(26, 12), 0, Vector2i(6, 11))
	layer.set_cell(Vector2i(26, 13), 0, Vector2i(6, 11))
	layer.set_cell(Vector2i(33, 7), 0, Vector2i(6, 10))
	for y in range(8, 14):
		layer.set_cell(Vector2i(33, y), 0, Vector2i(6, 11))

	# Hanging ceiling wires & brackets
	layer.set_cell(Vector2i(21, 3), 0, Vector2i(0, 10))
	layer.set_cell(Vector2i(22, 3), 0, Vector2i(1, 10))
	layer.set_cell(Vector2i(26, 3), 0, Vector2i(0, 10))
	layer.set_cell(Vector2i(27, 3), 0, Vector2i(1, 10))
	layer.set_cell(Vector2i(40, 7), 0, Vector2i(0, 10))
	layer.set_cell(Vector2i(41, 7), 0, Vector2i(1, 10))
	layer.set_cell(Vector2i(4, 6), 0, Vector2i(3, 0))
	layer.set_cell(Vector2i(9, 7), 0, Vector2i(2, 0))
	layer.set_cell(Vector2i(28, 10), 0, Vector2i(3, 0))
	layer.set_cell(Vector2i(25, 15), 0, Vector2i(3, 0))
	layer.set_cell(Vector2i(42, 13), 0, Vector2i(2, 0))


func _populate_terrain_layer(layer: TileMapLayer) -> void:
	layer.clear()
	for x in [27, 29, 31, 33, 35, 37]:
		layer.set_cell(Vector2i(x, 1), 0, Vector2i(9, 1))

	layer.set_cell(Vector2i(2, 2), 0, Vector2i(0, 6))
	layer.set_cell(Vector2i(3, 2), 0, Vector2i(0, 4))
	layer.set_cell(Vector2i(4, 2), 0, Vector2i(5, 4))
	layer.set_cell(Vector2i(5, 2), 0, Vector2i(7, 4))
	for x in range(6, 9):
		layer.set_cell(Vector2i(x, 2), 0, Vector2i(8, 4))
	layer.set_cell(Vector2i(9, 2), 0, Vector2i(9, 4))
	layer.set_cell(Vector2i(10, 2), 0, Vector2i(0, 4))
	for x in range(11, 23):
		layer.set_cell(Vector2i(x, 2), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(23, 2), 0, Vector2i(5, 4))
	layer.set_cell(Vector2i(24, 2), 0, Vector2i(4, 4))
	for x in range(25, 38):
		layer.set_cell(Vector2i(x, 2), 0, Vector2i(1, 5))
	layer.set_cell(Vector2i(38, 2), 0, Vector2i(5, 5))

	layer.set_cell(Vector2i(2, 3), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(3, 3), 0, Vector2i(1, 7))
	layer.set_cell(Vector2i(2, 4), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(1, 5), 0, Vector2i(9, 1))
	layer.set_cell(Vector2i(2, 5), 0, Vector2i(6, 3))
	for y in range(6, 9):
		var ty := y - 5
		layer.set_cell(Vector2i(1, y), 0, Vector2i(0, ty))
		layer.set_cell(Vector2i(2, y), 0, Vector2i(1, ty))
		layer.set_cell(Vector2i(3, y), 0, Vector2i(1, ty))
		layer.set_cell(Vector2i(4, y), 0, Vector2i(2, ty))
	layer.set_cell(Vector2i(5, 6), 0, Vector2i(9, 2))
	layer.set_cell(Vector2i(1, 9), 0, Vector2i(0, 7))
	layer.set_cell(Vector2i(2, 9), 0, Vector2i(1, 3))
	layer.set_cell(Vector2i(3, 9), 0, Vector2i(2, 3))
	layer.set_cell(Vector2i(4, 9), 0, Vector2i(9, 2))
	layer.set_cell(Vector2i(2, 10), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(3, 10), 0, Vector2i(9, 0))
	layer.set_cell(Vector2i(2, 11), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(1, 12), 0, Vector2i(9, 1))
	layer.set_cell(Vector2i(2, 12), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(3, 12), 0, Vector2i(9, 1))
	for y in range(13, 16):
		var ty := y - 12
		layer.set_cell(Vector2i(1, y), 0, Vector2i(0, ty))
		layer.set_cell(Vector2i(2, y), 0, Vector2i(1, ty))
		layer.set_cell(Vector2i(3, y), 0, Vector2i(1, ty))
		layer.set_cell(Vector2i(4, y), 0, Vector2i(2, ty))
	layer.set_cell(Vector2i(2, 16), 0, Vector2i(0, 7))
	layer.set_cell(Vector2i(3, 16), 0, Vector2i(1, 3))
	layer.set_cell(Vector2i(4, 16), 0, Vector2i(9, 2))
	layer.set_cell(Vector2i(3, 17), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(3, 18), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(3, 19), 0, Vector2i(0, 7))

	layer.set_cell(Vector2i(37, 3), 0, Vector2i(2, 7))
	layer.set_cell(Vector2i(38, 3), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(37, 4), 0, Vector2i(7, 6))
	layer.set_cell(Vector2i(38, 4), 0, Vector2i(3, 1))
	layer.set_cell(Vector2i(39, 4), 0, Vector2i(9, 1))
	layer.set_cell(Vector2i(37, 5), 0, Vector2i(2, 7))
	layer.set_cell(Vector2i(38, 5), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(39, 5), 0, Vector2i(1, 2))
	layer.set_cell(Vector2i(40, 5), 0, Vector2i(1, 6))

	layer.set_cell(Vector2i(23, 6), 0, Vector2i(9, 1))
	layer.set_cell(Vector2i(24, 6), 0, Vector2i(4, 4))
	for x in range(25, 37):
		layer.set_cell(Vector2i(x, 6), 0, Vector2i(1, 5))
	for x in range(37, 44):
		layer.set_cell(Vector2i(x, 6), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(44, 6), 0, Vector2i(1, 6))

	layer.set_cell(Vector2i(10, 7), 0, Vector2i(0, 4))
	for x in range(11, 23):
		layer.set_cell(Vector2i(x, 7), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(23, 7), 0, Vector2i(5, 4))
	layer.set_cell(Vector2i(10, 8), 0, Vector2i(9, 0))
	layer.set_cell(Vector2i(24, 7), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(24, 8), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(24, 9), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(25, 7), 0, Vector2i(1, 7))

	layer.set_cell(Vector2i(21, 10), 0, Vector2i(7, 2))
	layer.set_cell(Vector2i(22, 10), 0, Vector2i(8, 2))
	layer.set_cell(Vector2i(23, 10), 0, Vector2i(9, 2))
	layer.set_cell(Vector2i(24, 10), 0, Vector2i(0, 4))
	layer.set_cell(Vector2i(25, 10), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(26, 10), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(27, 10), 0, Vector2i(5, 4))
	layer.set_cell(Vector2i(15, 12), 0, Vector2i(7, 2))
	layer.set_cell(Vector2i(16, 12), 0, Vector2i(8, 2))
	layer.set_cell(Vector2i(17, 12), 0, Vector2i(9, 2))
	layer.set_cell(Vector2i(37, 11), 0, Vector2i(7, 3))
	layer.set_cell(Vector2i(38, 11), 0, Vector2i(8, 3))
	layer.set_cell(Vector2i(39, 11), 0, Vector2i(9, 3))

	layer.set_cell(Vector2i(43, 7), 0, Vector2i(0, 7))
	for y in range(7, 10):
		var ty := y - 6
		layer.set_cell(Vector2i(44, y), 0, Vector2i(0, ty))
		layer.set_cell(Vector2i(45, y), 0, Vector2i(1, ty))
		layer.set_cell(Vector2i(46, y), 0, Vector2i(2, ty))
	layer.set_cell(Vector2i(47, 9), 0, Vector2i(9, 1))
	layer.set_cell(Vector2i(44, 10), 0, Vector2i(0, 7))
	for y in range(10, 13):
		var ty := y - 9
		layer.set_cell(Vector2i(45, y), 0, Vector2i(0, ty))
		layer.set_cell(Vector2i(46, y), 0, Vector2i(1, ty))
		layer.set_cell(Vector2i(47, y), 0, Vector2i(2, ty))
	layer.set_cell(Vector2i(42, 13), 0, Vector2i(7, 3))
	for y in range(13, 16):
		var ty := y - 12
		layer.set_cell(Vector2i(43, y), 0, Vector2i(0, ty))
		layer.set_cell(Vector2i(44, y), 0, Vector2i(1, ty))
		layer.set_cell(Vector2i(45, y), 0, Vector2i(2, ty))
	layer.set_cell(Vector2i(46, 13), 0, Vector2i(2, 3))
	layer.set_cell(Vector2i(46, 14), 0, Vector2i(1, 7))
	layer.set_cell(Vector2i(41, 16), 0, Vector2i(0, 6))
	layer.set_cell(Vector2i(42, 16), 0, Vector2i(0, 3))
	layer.set_cell(Vector2i(43, 16), 0, Vector2i(1, 3))
	layer.set_cell(Vector2i(44, 16), 0, Vector2i(2, 3))
	layer.set_cell(Vector2i(41, 17), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(42, 17), 0, Vector2i(3, 1))
	layer.set_cell(Vector2i(41, 18), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(42, 18), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(41, 19), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(42, 19), 0, Vector2i(9, 0))
	layer.set_cell(Vector2i(41, 20), 0, Vector2i(6, 3))

	for x in range(5, 10):
		var tx := 7 + ((x - 5) % 2)
		layer.set_cell(Vector2i(x, 15), 0, Vector2i(tx, 0))
	layer.set_cell(Vector2i(10, 15), 0, Vector2i(0, 4))
	for x in range(11, 21):
		layer.set_cell(Vector2i(x, 15), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(21, 15), 0, Vector2i(5, 4))
	layer.set_cell(Vector2i(22, 15), 0, Vector2i(3, 5))
	layer.set_cell(Vector2i(23, 15), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(24, 15), 0, Vector2i(4, 4))
	layer.set_cell(Vector2i(25, 15), 0, Vector2i(7, 3))
	layer.set_cell(Vector2i(26, 15), 0, Vector2i(8, 3))
	layer.set_cell(Vector2i(27, 15), 0, Vector2i(9, 3))

	layer.set_cell(Vector2i(4, 19), 0, Vector2i(0, 4))
	layer.set_cell(Vector2i(5, 19), 0, Vector2i(3, 4))
	for x in range(6, 16):
		layer.set_cell(Vector2i(x, 19), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(16, 19), 0, Vector2i(5, 4))
	layer.set_cell(Vector2i(17, 19), 0, Vector2i(3, 6))
	layer.set_cell(Vector2i(21, 19), 0, Vector2i(3, 6))
	layer.set_cell(Vector2i(22, 19), 0, Vector2i(3, 4))
	for x in range(23, 37):
		layer.set_cell(Vector2i(x, 19), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(37, 19), 0, Vector2i(5, 4))

	layer.set_cell(Vector2i(38, 18), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(38, 19), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(38, 20), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(36, 20), 0, Vector2i(9, 0))
	layer.set_cell(Vector2i(37, 20), 0, Vector2i(4, 1))
	layer.set_cell(Vector2i(38, 21), 0, Vector2i(7, 4))
	layer.set_cell(Vector2i(39, 21), 0, Vector2i(8, 4))
	layer.set_cell(Vector2i(40, 21), 0, Vector2i(8, 4))
	layer.set_cell(Vector2i(41, 21), 0, Vector2i(9, 4))

	layer.set_cell(Vector2i(17, 20), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(16, 21), 0, Vector2i(0, 6))
	layer.set_cell(Vector2i(17, 21), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(13, 22), 0, Vector2i(0, 4))
	layer.set_cell(Vector2i(14, 22), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(15, 22), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(16, 22), 0, Vector2i(5, 4))
	layer.set_cell(Vector2i(17, 22), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(13, 23), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(13, 24), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(14, 24), 0, Vector2i(1, 6))
	layer.set_cell(Vector2i(21, 20), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(21, 21), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(29, 20), 0, Vector2i(2, 7))
	layer.set_cell(Vector2i(30, 20), 0, Vector2i(2, 7))
	layer.set_cell(Vector2i(31, 20), 0, Vector2i(2, 7))
	layer.set_cell(Vector2i(32, 20), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(33, 20), 0, Vector2i(2, 2))
	layer.set_cell(Vector2i(34, 20), 0, Vector2i(9, 0))
	layer.set_cell(Vector2i(32, 21), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(33, 21), 0, Vector2i(1, 7))
	layer.set_cell(Vector2i(32, 22), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(32, 23), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(31, 24), 0, Vector2i(0, 6))
	layer.set_cell(Vector2i(32, 24), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(13, 25), 0, Vector2i(0, 4))
	for x in range(14, 32):
		layer.set_cell(Vector2i(x, 25), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(32, 25), 0, Vector2i(5, 4))
	for x in [13, 16, 19, 22, 25, 28, 31]:
		layer.set_cell(Vector2i(x, 26), 0, Vector2i(9, 0))


func _populate_props_layer(layer: TileMapLayer) -> void:
	layer.clear()
	# Terminal stands (the blinking monitor screens are Sprite2Ds in WorldDecor)
	layer.set_cell(Vector2i(22, 9), 0, Vector2i(11, 13))
	layer.set_cell(Vector2i(38, 10), 0, Vector2i(11, 13))

	# Capsules
	layer.set_cell(Vector2i(5, 18), 0, Vector2i(10, 2))
	layer.set_cell(Vector2i(24, 14), 0, Vector2i(10, 0))

	# Companion Cubes / Crates
	layer.set_cell(Vector2i(15, 24), 0, Vector2i(8, 13))
	layer.set_cell(Vector2i(27, 24), 0, Vector2i(7, 13))
	layer.set_cell(Vector2i(29, 24), 0, Vector2i(7, 13))
	layer.set_cell(Vector2i(30, 24), 0, Vector2i(7, 13))
	layer.set_cell(Vector2i(30, 23), 0, Vector2i(7, 13))
	layer.set_cell(Vector2i(29, 18), 0, Vector2i(9, 13))
	layer.set_cell(Vector2i(30, 18), 0, Vector2i(9, 13))

	# Orange floor pad in right pit
	layer.set_cell(Vector2i(39, 20), 0, Vector2i(7, 10))
	layer.set_cell(Vector2i(40, 20), 0, Vector2i(9, 10))


func _make_8step_sprite_frames(tex: Texture2D, row_idx: int, cols_8: Array) -> SpriteFrames:
	var y_start: int = 0 if row_idx == 0 else (row_idx * 32 - 2)
	var fh_px: int = 30 if row_idx == 0 else 32
	var sf := SpriteFrames.new()
	sf.add_animation("loop")
	sf.set_animation_loop("loop", true)
	sf.set_animation_speed("loop", ANIM_FPS)
	for col in cols_8:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(2 + int(col) * 16, y_start, 16, fh_px)
		sf.add_frame("loop", at)
	return sf


func _spawn_cell_sprite(parent: Node2D, tile_tex: Texture2D, cell: Vector2i, tx: int, ty: int, centered_flag: bool = false) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.centered = centered_flag
	sp.texture = _get_tile_tex(tile_tex, tx, ty)
	sp.position = Vector2(cell.x * 16 + (8 if centered_flag else 0), cell.y * 16 + (8 if centered_flag else 0))
	parent.add_child(sp)
	return sp


func _populate_npcs_and_bubbles() -> void:
	var npcs_root: Node2D = get_node_or_null("WorldDecor")
	if not npcs_root:
		return
	for child in npcs_root.get_children():
		npcs_root.remove_child(child)
		child.queue_free()

	_synced_npcs.clear()
	_laser_sprites.clear()
	_eye_sprite = null
	_term1_sprite = null
	_term2_top_sprite = null
	_term2_bot_sprite = null
	_term3_sprite = null
	_elevator_body = null
	_elevator_robot = null
	_crane_claw_sprite = null
	_crane_robot_sprite = null
	_bubble_helo_sprite = null

	var tex: Texture2D = load(CHAR_SHEET_PATH)
	var tile_tex: Texture2D = load(TILESET_PNG_PATH)
	if not tex or not tile_tex:
		return

	# 0. Animated Tiles as lightweight Sprite2D nodes (Red Eye, 3 Terminal Monitors, 9 Laser cells)
	_eye_sprite = _spawn_cell_sprite(npcs_root, tile_tex, Vector2i(37, 4), 7, 6, false)
	_term1_sprite = _spawn_cell_sprite(npcs_root, tile_tex, Vector2i(22, 8), 10, 12, false)
	_term2_top_sprite = _spawn_cell_sprite(npcs_root, tile_tex, Vector2i(26, 13), 11, 10, false)
	_term2_bot_sprite = _spawn_cell_sprite(npcs_root, tile_tex, Vector2i(26, 14), 11, 11, false)
	_term3_sprite = _spawn_cell_sprite(npcs_root, tile_tex, Vector2i(38, 9), 11, 12, false)

	var laser_cells: Array[Vector2i] = [
		Vector2i(24, 3), Vector2i(24, 4), Vector2i(24, 5),
		Vector2i(22, 16), Vector2i(22, 17), Vector2i(22, 18),
		Vector2i(18, 19), Vector2i(19, 19), Vector2i(20, 19),
	]
	for lc in laser_cells:
		_laser_sprites[lc] = _spawn_cell_sprite(npcs_root, tile_tex, lc, 0, 8, true)

	# 1. Moving Left Elevator Platform + Robot #5 (Row 4)
	_elevator_body = StaticBody2D.new()
	_elevator_body.name = "ElevatorPlatform"
	_elevator_body.position = Vector2(96.0, ELEV_Y[0])
	npcs_root.add_child(_elevator_body)

	var elev_col := CollisionShape2D.new()
	var elev_rect := RectangleShape2D.new()
	elev_rect.size = Vector2(44.0, 6.0)
	elev_col.shape = elev_rect
	elev_col.position = Vector2(24.0, 19.0)
	elev_col.one_way_collision = true
	_elevator_body.add_child(elev_col)

	_elevator_robot = AnimatedSprite2D.new()
	_elevator_robot.name = "ElevatorRobot"
	_elevator_robot.centered = false
	_elevator_robot.flip_h = true
	_elevator_robot.sprite_frames = _make_8step_sprite_frames(tex, 4, [0, 1, 2, 3, 0, 1, 2, 3])
	_elevator_robot.animation = "loop"
	_elevator_robot.position = Vector2(17.0, -16.0)
	_elevator_body.add_child(_elevator_robot)

	var elev_sp := Sprite2D.new()
	elev_sp.name = "PlatformSprite"
	elev_sp.centered = false
	var elev_at := AtlasTexture.new()
	elev_at.atlas = tile_tex
	elev_at.region = Rect2(7 * 16, 7 * 16, 48, 32)
	elev_sp.texture = elev_at
	_elevator_body.add_child(elev_sp)

	# 2. Moving Crane Claw + Flailing Robot #5 (Row 4, columns 5..12) at X=33
	_crane_robot_sprite = AnimatedSprite2D.new()
	_crane_robot_sprite.name = "CraneRobot"
	_crane_robot_sprite.centered = false
	_crane_robot_sprite.flip_h = false
	_crane_robot_sprite.sprite_frames = _make_8step_sprite_frames(tex, 4, [5, 6, 7, 8, 9, 10, 11, 12])
	_crane_robot_sprite.animation = "loop"
	_crane_robot_sprite.position = Vector2(526.0, CRANE_ROBOT_Y[0])
	npcs_root.add_child(_crane_robot_sprite)

	_crane_claw_sprite = Sprite2D.new()
	_crane_claw_sprite.name = "CraneClaw"
	_crane_claw_sprite.centered = false
	var claw_at := AtlasTexture.new()
	claw_at.atlas = tile_tex
	claw_at.region = Rect2(6 * 16, 11 * 16, 16, 32)
	_crane_claw_sprite.texture = claw_at
	_crane_claw_sprite.position = Vector2(528.0, CRANE_CLAW_Y[0])
	npcs_root.add_child(_crane_claw_sprite)

	# 3. All 7 Static-Position NPC Robots with exact 1x top-left coordinates & 8-frame sequences from map-animation.gif
	var npc_defs: Array = [
		[0, Vector2(59.0, 66.0), false, [2, 3, 0, 1, 2, 3, 0, 1]],
		[2, Vector2(625.0, 144.0), true, [0, 1, 2, 3, 0, 1, 2, 3]],
		[3, Vector2(305.0, 368.0), true, [0, 1, 2, 3, 0, 1, 2, 3]],
		[5, Vector2(433.0, 352.0), true, [0, 1, 2, 3, 0, 1, 2, 3]],
		[6, Vector2(690.0, 176.0), true, [0, 1, 2, 3, 0, 1, 2, 3]],
		[7, Vector2(415.0, 128.0), false, [0, 1, 2, 1, 0, 1, 2, 1]],
		[8, Vector2(100.0, 272.0), true, [1, 2, 3, 0, 1, 2, 3, 0]],
	]
	for item in npc_defs:
		var r_idx: int = item[0]
		var top_left: Vector2 = item[1]
		var fh: bool = item[2]
		var cols: Array = item[3]

		var anim := AnimatedSprite2D.new()
		anim.centered = false
		anim.flip_h = fh
		anim.sprite_frames = _make_8step_sprite_frames(tex, r_idx, cols)
		anim.animation = "loop"
		anim.position = top_left
		npcs_root.add_child(anim)
		_synced_npcs.append(anim)

	# 4. Pixel-art Speech Bubbles extracted 1:1 from map-animation.gif
	var bubbles: Array = [
		["BubbleHeloDave", BUBBLE_HELO_PATH, Vector2(548.0, 52.0)],
		["BubbleMeow", BUBBLE_MEOW_PATH, Vector2(430.0, 121.0)],
		["BubbleBinary", BUBBLE_BIN_PATH, Vector2(115.0, 262.0)],
	]
	for b in bubbles:
		var b_tex: Texture2D = load(b[1])
		if b_tex:
			var b_sp := Sprite2D.new()
			b_sp.name = b[0]
			b_sp.centered = false
			b_sp.texture = b_tex
			b_sp.position = b[2]
			npcs_root.add_child(b_sp)
			if b[0] == "BubbleHeloDave":
				_bubble_helo_sprite = b_sp


func _setup_terminals() -> void:
	var terms_root: Node2D = get_node_or_null("Terminals")
	if not terms_root or Engine.is_editor_hint():
		return
	for area in terms_root.get_children():
		if area is Area2D:
			if not area.body_entered.is_connected(_on_terminal_entered):
				area.body_entered.connect(_on_terminal_entered.bind(area))
			if not area.body_exited.is_connected(_on_terminal_exited):
				area.body_exited.connect(_on_terminal_exited.bind(area))


func _on_terminal_entered(body: Node2D, area: Area2D) -> void:
	if body == dex:
		_active_terminal_name = area.name
		var lbl: Label = area.get_node_or_null("Prompt")
		if lbl:
			lbl.visible = true


func _on_terminal_exited(body: Node2D, area: Area2D) -> void:
	if body == dex:
		if _active_terminal_name == area.name:
			_active_terminal_name = ""
		var lbl: Label = area.get_node_or_null("Prompt")
		if lbl:
			lbl.visible = false
