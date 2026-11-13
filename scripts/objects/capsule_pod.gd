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

var _activated: bool = false
var _status_label: Label = null
var _sprite: Sprite2D = null


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
		if not _activated:
			_activated = true
			if is_instance_valid(_sprite):
				_sprite.modulate = Color(0.55, 1.0, 0.78, 1.0)
			if is_instance_valid(_status_label):
				_status_label.visible = true


func _rebuild_visuals() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var tile_tex: Texture2D = load(TILESET_PNG_PATH)
	if not tile_tex:
		return

	_sprite = Sprite2D.new()
	_sprite.name = "CapsuleSprite"
	_sprite.centered = false
	var at := AtlasTexture.new()
	at.atlas = tile_tex
	var ty: int = 0 if capsule_color == 0 else 2
	at.region = Rect2(10 * 16, ty * 16, 16, 16)
	_sprite.texture = at
	add_child(_sprite)

	_status_label = Label.new()
	_status_label.name = "CheckpointLabel"
	_status_label.text = "CHECKPOINT AKTIF"
	_status_label.position = Vector2(-28.0, -14.0)
	_status_label.add_theme_font_size_override("font_size", 8)
	_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.65))
	_status_label.visible = false
	add_child(_status_label)

	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16.0, 16.0)
	col.shape = rect
	col.position = Vector2(8.0, 8.0)
	add_child(col)
