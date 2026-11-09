@tool
extends Area2D
class_name CodeTerminal

signal terminal_interacted(terminal: CodeTerminal)
signal player_entered_range(terminal: CodeTerminal)
signal player_exited_range(terminal: CodeTerminal)

const TILESET_PNG_PATH := "res://resources/tilesets/tileset.png"
const BLINK_PATTERNS := [
	[10, 10, 11, 11, 11, 11, 10, 10],
	[11, 11, 10, 10, 10, 10, 11, 11],
	[11, 11, 11, 11, 10, 10, 10, 10],
]

@export var terminal_id: String = "Terminal_1"

@export_enum("Standing:0", "Hanging:1") var terminal_style: int = 0:
	set(v):
		terminal_style = v
		if is_node_ready():
			_rebuild_visuals()

@export_range(0, 2) var blink_pattern_index: int = 0:
	set(v):
		blink_pattern_index = clampi(v, 0, 2)
		if is_node_ready():
			_apply_step(_last_step if _last_step >= 0 else 0)

@export var show_hanging_cable: bool = false:
	set(v):
		show_hanging_cable = v
		if is_node_ready():
			_rebuild_visuals()

@export_range(1, 12) var hanging_cable_tiles: int = 3:
	set(v):
		hanging_cable_tiles = maxi(1, v)
		if is_node_ready():
			_rebuild_visuals()

var _top_screen_sprite: Sprite2D = null
var _bot_screen_sprite: Sprite2D = null
var _prompt_label: Label = null
var _atlas_cache: Dictionary = {}
var _last_step: int = -1
var _player_in_range: bool = false


func _ready() -> void:
	_rebuild_visuals()
	_apply_step(0)
	if not Engine.is_editor_hint():
		if not body_entered.is_connected(_on_body_entered):
			body_entered.connect(_on_body_entered)
		if not body_exited.is_connected(_on_body_exited):
			body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	var step := int(Time.get_ticks_msec() / 100.0) % 8
	if step != _last_step:
		_last_step = step
		_apply_step(step)


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if _player_in_range and event.is_action_pressed("interact"):
		terminal_interacted.emit(self)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_in_range = true
		if is_instance_valid(_prompt_label):
			_prompt_label.visible = true
		player_entered_range.emit(self)


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_in_range = false
		if is_instance_valid(_prompt_label):
			_prompt_label.visible = false
		player_exited_range.emit(self)


func _get_tile_tex(tile_tex: Texture2D, tx: int, ty: int) -> AtlasTexture:
	var key := Vector2i(tx, ty)
	if _atlas_cache.has(key):
		return _atlas_cache[key]
	var at := AtlasTexture.new()
	at.atlas = tile_tex
	at.region = Rect2(tx * 16, ty * 16, 16, 16)
	_atlas_cache[key] = at
	return at


func _rebuild_visuals() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	_top_screen_sprite = null
	_bot_screen_sprite = null
	_prompt_label = null

	var tile_tex: Texture2D = load(TILESET_PNG_PATH)
	if not tile_tex:
		return

	if terminal_style == 1 and show_hanging_cable:
		for i in range(hanging_cable_tiles):
			var c_sp := Sprite2D.new()
			c_sp.centered = false
			c_sp.texture = _get_tile_tex(tile_tex, 6, 11)
			c_sp.position = Vector2(0.0, -(hanging_cable_tiles - 1 - i) * 16.0)
			add_child(c_sp)

	_top_screen_sprite = Sprite2D.new()
	_top_screen_sprite.name = "TopScreen"
	_top_screen_sprite.centered = false
	add_child(_top_screen_sprite)

	_bot_screen_sprite = Sprite2D.new()
	_bot_screen_sprite.name = "BottomPart"
	_bot_screen_sprite.centered = false
	_bot_screen_sprite.position = Vector2(0.0, 16.0)
	if terminal_style == 0:
		_bot_screen_sprite.texture = _get_tile_tex(tile_tex, 11, 13)
	add_child(_bot_screen_sprite)

	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(36.0, 36.0)
	col.shape = rect
	col.position = Vector2(8.0, 16.0)
	add_child(col)

	_prompt_label = Label.new()
	_prompt_label.name = "Prompt"
	_prompt_label.text = "[E]"
	_prompt_label.scale = Vector2(0.5, 0.5)
	_prompt_label.position = Vector2(-2.0, -12.0)
	_prompt_label.visible = false
	add_child(_prompt_label)

	_apply_step(_last_step if _last_step >= 0 else 0)


func _apply_step(step: int) -> void:
	var tile_tex: Texture2D = load(TILESET_PNG_PATH)
	if not tile_tex:
		return
	var idx := posmod(step, 8)
	var pat: Array = BLINK_PATTERNS[clampi(blink_pattern_index, 0, 2)]
	var tx: int = int(pat[idx])
	if terminal_style == 0:
		if is_instance_valid(_top_screen_sprite):
			_top_screen_sprite.texture = _get_tile_tex(tile_tex, tx, 12)
	else:
		if is_instance_valid(_top_screen_sprite):
			_top_screen_sprite.texture = _get_tile_tex(tile_tex, tx, 10)
		if is_instance_valid(_bot_screen_sprite):
			_bot_screen_sprite.texture = _get_tile_tex(tile_tex, tx, 11)
