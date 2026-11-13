@tool
extends AnimatableBody2D
class_name CollapsingPlatform

## Collapsing platform for Low-Power Corridor: shakes briefly when stepped on,
## drops/fades out, then respawns automatically to prevent soft-locks.

const TILESET_PNG_PATH := "res://assets/tilesets/tileset.png"

@export_range(1, 8) var width_tiles: int = 3:
	set(v):
		width_tiles = maxi(1, v)
		if is_node_ready():
			_rebuild_visuals()

@export_range(0.2, 2.0, 0.05) var collapse_delay: float = 0.55
@export_range(0.8, 5.0, 0.1) var respawn_delay: float = 1.8

var _visual_root: Node2D = null
var _col_shape: CollisionShape2D = null
var _trigger_area: Area2D = null
var _state: int = 0 # 0 = idle, 1 = shaking, 2 = collapsed
var _timer: float = 0.0


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	_rebuild_visuals()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if _state == 1:
		_timer -= delta
		if is_instance_valid(_visual_root):
			_visual_root.position = Vector2(randf_range(-1.5, 1.5), randf_range(-1.0, 1.0))
		if _timer <= 0.0:
			_set_collapsed(true)
	elif _state == 2:
		_timer -= delta
		if _timer <= 0.0:
			_set_collapsed(false)


func _set_collapsed(collapsed: bool) -> void:
	if collapsed:
		_state = 2
		_timer = respawn_delay
		if is_instance_valid(_visual_root):
			_visual_root.position = Vector2.ZERO
			_visual_root.modulate.a = 0.2
		if is_instance_valid(_col_shape):
			_col_shape.disabled = true
	else:
		_state = 0
		if is_instance_valid(_visual_root):
			_visual_root.position = Vector2.ZERO
			_visual_root.modulate.a = 1.0
		if is_instance_valid(_col_shape):
			_col_shape.disabled = false


func _on_trigger_body_entered(body: Node2D) -> void:
	if _state != 0:
		return
	if body is CharacterBody2D or body.is_in_group("player"):
		_state = 1
		_timer = collapse_delay


func _rebuild_visuals() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	_visual_root = Node2D.new()
	_visual_root.name = "VisualRoot"
	add_child(_visual_root)

	var tile_tex: Texture2D = load(TILESET_PNG_PATH)
	if tile_tex:
		for i in range(width_tiles):
			var tx := 8
			if i == 0:
				tx = 7
			elif i == width_tiles - 1:
				tx = 9
			var sp := Sprite2D.new()
			sp.centered = false
			sp.position = Vector2(float(i) * 16.0, 0.0)
			sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var at := AtlasTexture.new()
			at.atlas = tile_tex
			at.region = Rect2(tx * 16, 2 * 16, 16, 16)
			sp.texture = at
			sp.modulate = Color(1.0, 0.72, 0.45, 1.0)
			_visual_root.add_child(sp)

	_col_shape = CollisionShape2D.new()
	_col_shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width_tiles * 16.0, 8.0)
	_col_shape.shape = rect
	_col_shape.position = Vector2(width_tiles * 8.0, 4.0)
	_col_shape.one_way_collision = true
	_col_shape.one_way_collision_margin = 4.0
	add_child(_col_shape)

	_trigger_area = Area2D.new()
	_trigger_area.name = "StepTrigger"
	_trigger_area.collision_layer = 0
	_trigger_area.collision_mask = 1 | 2
	var t_col := CollisionShape2D.new()
	var t_rect := RectangleShape2D.new()
	t_rect.size = Vector2(width_tiles * 16.0 - 2.0, 6.0)
	t_col.shape = t_rect
	t_col.position = Vector2(width_tiles * 8.0, -2.0)
	_trigger_area.add_child(t_col)
	if not Engine.is_editor_hint():
		_trigger_area.body_entered.connect(_on_trigger_body_entered)
	add_child(_trigger_area)
