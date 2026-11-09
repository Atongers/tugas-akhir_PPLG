@tool
extends Node2D

const TILESET_PATH := "res://resources/tilesets/world_1_tileset.tres"
const BUBBLE_HELO_PATH := "res://assets/ui/bubble_helo_dave.png"
const DEX_SPAWN_POS := Vector2(579.0, 96.0)

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
var _bubble_helo_sprite: Sprite2D = null


func _ready() -> void:
	_build_all()
	if not Engine.is_editor_hint():
		_setup_runtime()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and is_instance_valid(_bubble_helo_sprite) and dex:
		_bubble_helo_sprite.visible = dex.global_position.distance_to(DEX_SPAWN_POS) < 28.0


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		_toggle_camera_mode()


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


func _build_all() -> void:
	var ts: TileSet = load(TILESET_PATH)
	if not ts:
		return
	_configure_tileset_collisions(ts)

	bg_layer = get_node_or_null("BgLayer")
	terrain_layer = get_node_or_null("TerrainLayer")
	props_layer = get_node_or_null("PropsLayer")
	dex = get_node_or_null("Dex")

	if bg_layer:
		bg_layer.tile_set = ts
		_populate_bg_layer(bg_layer)
	if terrain_layer:
		terrain_layer.tile_set = ts
		_populate_terrain_layer(terrain_layer)
	if props_layer:
		props_layer.tile_set = ts
		_populate_props_layer(props_layer)

	_setup_dave_bubble()
	_setup_terminals()


func _setup_dave_bubble() -> void:
	var decor_root: Node2D = get_node_or_null("WorldDecor")
	if not decor_root:
		return
	for child in decor_root.get_children():
		decor_root.remove_child(child)
		child.queue_free()

	var b_tex: Texture2D = load(BUBBLE_HELO_PATH)
	if b_tex:
		_bubble_helo_sprite = Sprite2D.new()
		_bubble_helo_sprite.name = "BubbleHeloDave"
		_bubble_helo_sprite.centered = false
		_bubble_helo_sprite.texture = b_tex
		_bubble_helo_sprite.position = Vector2(548.0, 52.0)
		decor_root.add_child(_bubble_helo_sprite)


func _setup_terminals() -> void:
	var terms_root: Node2D = get_node_or_null("Terminals")
	if not terms_root or Engine.is_editor_hint():
		return
	for child in terms_root.get_children():
		if child.has_signal("terminal_interacted"):
			if not child.terminal_interacted.is_connected(_on_terminal_interacted):
				child.terminal_interacted.connect(_on_terminal_interacted)


func _on_terminal_interacted(terminal: Node) -> void:
	if hud_status:
		var t_id: String = terminal.get("terminal_id") if "terminal_id" in terminal else terminal.name
		hud_status.text = "Membuka " + t_id + " (Tekan Tab untuk ganti kamera)"
		hud_status.modulate = Color(0.4, 1.0, 0.55)


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

	# Hanging ceiling wires & brackets (Elevator cables, Crane cable, and Hanging Monitor cable are owned by their reusable components!)
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
	# Orange floor pad in right pit (all other interactive/programmable props are reusable PackedScene instances!)
	layer.set_cell(Vector2i(39, 20), 0, Vector2i(7, 10))
	layer.set_cell(Vector2i(40, 20), 0, Vector2i(9, 10))
