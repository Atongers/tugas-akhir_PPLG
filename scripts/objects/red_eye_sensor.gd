@tool
extends Node2D
class_name RedEyeSensor

const TILESET_PNG_PATH := "res://assets/tilesets/tileset.png"
const EYE_TX := [7, 8, 9, 8, 7, 8, 9, 8]

@export var is_active: bool = true:
	set(v):
		is_active = v
		_apply_step(_last_step if is_active else 0)

var _sprite: Sprite2D = null
var _atlas_cache: Dictionary = {}
var _last_step: int = -1


func _ready() -> void:
	_rebuild_visuals()
	_apply_step(0)


func _process(_delta: float) -> void:
	if not is_active:
		return
	var step := int(Time.get_ticks_msec() / 100.0) % 8
	if step != _last_step:
		_last_step = step
		_apply_step(step)


func _rebuild_visuals() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	_sprite = Sprite2D.new()
	_sprite.name = "EyeSprite"
	_sprite.centered = false
	add_child(_sprite)
	_apply_step(_last_step if _last_step >= 0 else 0)


func _apply_step(step: int) -> void:
	if not is_instance_valid(_sprite):
		return
	var tile_tex: Texture2D = load(TILESET_PNG_PATH)
	if not tile_tex:
		return
	var tx: int = EYE_TX[posmod(step, 8)] if is_active else 7
	if not _atlas_cache.has(tx):
		var at := AtlasTexture.new()
		at.atlas = tile_tex
		at.region = Rect2(tx * 16, 6 * 16, 16, 16)
		_atlas_cache[tx] = at
	_sprite.texture = _atlas_cache[tx]
