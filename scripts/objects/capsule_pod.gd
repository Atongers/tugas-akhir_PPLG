@tool
extends Area2D
class_name CapsulePod

const TILESET_PNG_PATH := "res://assets/tilesets/tileset.png"

@export_enum("Orange:0", "Blue:1") var capsule_color: int = 0:
	set(v):
		capsule_color = clampi(v, 0, 1)
		if is_node_ready():
			_rebuild_visuals()

@export var is_checkpoint: bool = true


func _ready() -> void:
	_rebuild_visuals()
	if not Engine.is_editor_hint():
		if not body_entered.is_connected(_on_body_entered):
			body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not is_checkpoint:
		return
	if "checkpoint_position" in body:
		body.checkpoint_position = global_position + Vector2(8.0, 16.0)


func _rebuild_visuals() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var tile_tex: Texture2D = load(TILESET_PNG_PATH)
	if not tile_tex:
		return

	var sp := Sprite2D.new()
	sp.name = "CapsuleSprite"
	sp.centered = false
	var at := AtlasTexture.new()
	at.atlas = tile_tex
	var ty: int = 0 if capsule_color == 0 else 2
	at.region = Rect2(10 * 16, ty * 16, 16, 16)
	sp.texture = at
	add_child(sp)

	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16.0, 16.0)
	col.shape = rect
	col.position = Vector2(8.0, 8.0)
	add_child(col)
