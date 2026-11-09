@tool
extends StaticBody2D
class_name CompanionCrate

const TILESET_PNG_PATH := "res://resources/tilesets/tileset.png"

@export_enum("Plain:0", "OrangeCore:1", "BlueCore:2") var crate_variant: int = 0:
	set(v):
		crate_variant = clampi(v, 0, 2)
		if is_node_ready():
			_rebuild_visuals()

var _sprite: Sprite2D = null


func _ready() -> void:
	_rebuild_visuals()


func _rebuild_visuals() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var tile_tex: Texture2D = load(TILESET_PNG_PATH)
	if not tile_tex:
		return

	_sprite = Sprite2D.new()
	_sprite.name = "CrateSprite"
	_sprite.centered = false
	var at := AtlasTexture.new()
	at.atlas = tile_tex
	var tx: int = 7 + clampi(crate_variant, 0, 2)
	at.region = Rect2(tx * 16, 13 * 16, 16, 16)
	_sprite.texture = at
	add_child(_sprite)

	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16.0, 16.0)
	col.shape = rect
	col.position = Vector2(8.0, 8.0)
	add_child(col)
