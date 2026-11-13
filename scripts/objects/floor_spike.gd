@tool
extends Area2D
class_name FloorSpike

const SPIKE_SHEET_PATH := "res://assets/sprites/objects/floor_spike_sheet.png"

@export_range(1, 16) var width_tiles: int = 2:
	set(v):
		width_tiles = maxi(1, v)
		if is_node_ready():
			_rebuild_visuals()

@export_range(0, 2) var variant_index: int = 0:
	set(v):
		variant_index = clampi(v, 0, 2)
		if is_node_ready():
			_rebuild_visuals()

@export var damage: float = 20.0

var _col_shape: CollisionShape2D = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 2
	_rebuild_visuals()
	if not Engine.is_editor_hint():
		if not body_entered.is_connected(_on_body_entered):
			body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, "spike")


func _rebuild_visuals() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var tex: Texture2D = load(SPIKE_SHEET_PATH)
	for i in range(width_tiles):
		var sp := Sprite2D.new()
		sp.name = "SpikeTile_%d" % i
		sp.centered = false
		sp.position = Vector2(float(i) * 16.0, 0.0)
		sp.texture = tex
		sp.hframes = 3
		sp.frame = variant_index
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sp)

	_col_shape = CollisionShape2D.new()
	_col_shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width_tiles * 16.0 - 4.0, 10.0)
	_col_shape.shape = rect
	_col_shape.position = Vector2(width_tiles * 8.0, 10.0)
	add_child(_col_shape)
