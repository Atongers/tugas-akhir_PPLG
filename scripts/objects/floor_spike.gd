@tool
extends Area2D
class_name FloorSpike

@export_range(1, 16) var width_tiles: int = 2:
	set(v):
		width_tiles = maxi(1, v)
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

	var base_plate := ColorRect.new()
	base_plate.name = "SpikeBase"
	base_plate.position = Vector2(0.0, 12.0)
	base_plate.size = Vector2(width_tiles * 16.0, 4.0)
	base_plate.color = Color(0.22, 0.25, 0.32, 1.0)
	add_child(base_plate)

	# Two 8px-wide metallic spikes per 16px tile
	for i in range(width_tiles * 2):
		var x0 := float(i) * 8.0
		var spike := Polygon2D.new()
		spike.name = "Spike_%d" % i
		spike.polygon = PackedVector2Array([
			Vector2(x0 + 1.0, 12.0),
			Vector2(x0 + 4.0, 2.0),
			Vector2(x0 + 7.0, 12.0),
		])
		spike.color = Color(0.75, 0.82, 0.9, 1.0)
		add_child(spike)

		var tip := Polygon2D.new()
		tip.name = "SpikeTip_%d" % i
		tip.polygon = PackedVector2Array([
			Vector2(x0 + 2.8, 6.0),
			Vector2(x0 + 4.0, 2.0),
			Vector2(x0 + 5.2, 6.0),
		])
		tip.color = Color(0.95, 0.28, 0.28, 1.0)
		add_child(tip)

	_col_shape = CollisionShape2D.new()
	_col_shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width_tiles * 16.0 - 4.0, 10.0)
	_col_shape.shape = rect
	_col_shape.position = Vector2(width_tiles * 8.0, 10.0)
	add_child(_col_shape)
