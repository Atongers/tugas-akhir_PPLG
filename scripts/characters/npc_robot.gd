@tool
extends Node2D
class_name NpcRobot

const CHAR_SHEET_PATH := "res://assets/sprites/characters/characters.png"
const BUBBLE_PATHS := {
	1: "res://assets/ui/bubble_helo_dave.png",
	2: "res://assets/ui/bubble_meow.png",
	3: "res://assets/ui/bubble_binary.png",
}

@export_range(0, 8) var robot_row: int = 0:
	set(v):
		robot_row = clampi(v, 0, 8)
		if is_node_ready():
			_rebuild_visuals()

@export var flip_h: bool = false:
	set(v):
		flip_h = v
		if is_instance_valid(_anim_sprite):
			_anim_sprite.flip_h = flip_h

@export var frame_columns: Array[int] = [0, 1, 2, 3, 0, 1, 2, 3]:
	set(v):
		frame_columns = v
		if is_node_ready():
			_rebuild_visuals()

@export_enum("None:0", "HeloDave:1", "Meow:2", "Binary:3") var speech_bubble: int = 0:
	set(v):
		speech_bubble = clampi(v, 0, 3)
		if is_node_ready():
			_rebuild_visuals()

@export var bubble_offset: Vector2 = Vector2(15.0, -7.0):
	set(v):
		bubble_offset = v
		if is_instance_valid(_bubble_sprite):
			_bubble_sprite.position = bubble_offset

var _anim_sprite: AnimatedSprite2D = null
var _bubble_sprite: Sprite2D = null
var _last_step: int = -1


func _ready() -> void:
	_rebuild_visuals()
	_apply_step(0)


func _process(_delta: float) -> void:
	var step := int(Time.get_ticks_msec() / 100.0) % 8
	if step != _last_step:
		_last_step = step
		_apply_step(step)


func _apply_step(step: int) -> void:
	if is_instance_valid(_anim_sprite):
		_anim_sprite.frame = posmod(step, 8)


func _rebuild_visuals() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	_anim_sprite = null
	_bubble_sprite = null

	var tex: Texture2D = load(CHAR_SHEET_PATH)
	if not tex:
		return

	var y_start: int = 0 if robot_row == 0 else (robot_row * 32 - 2)
	var fh_px: int = 30 if robot_row == 0 else 32
	var cols: Array[int] = frame_columns if frame_columns.size() == 8 else [0, 1, 2, 3, 0, 1, 2, 3]

	var sf := SpriteFrames.new()
	sf.add_animation("loop")
	sf.set_animation_loop("loop", true)
	sf.set_animation_speed("loop", 10.0)
	for col in cols:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(2 + clampi(col, 0, 22) * 16, y_start, 16, fh_px)
		sf.add_frame("loop", at)

	_anim_sprite = AnimatedSprite2D.new()
	_anim_sprite.name = "AnimatedSprite2D"
	_anim_sprite.centered = false
	_anim_sprite.flip_h = flip_h
	_anim_sprite.sprite_frames = sf
	_anim_sprite.animation = "loop"
	add_child(_anim_sprite)

	if BUBBLE_PATHS.has(speech_bubble):
		var b_tex: Texture2D = load(BUBBLE_PATHS[speech_bubble])
		if b_tex:
			_bubble_sprite = Sprite2D.new()
			_bubble_sprite.name = "SpeechBubble"
			_bubble_sprite.centered = false
			_bubble_sprite.texture = b_tex
			_bubble_sprite.position = bubble_offset
			add_child(_bubble_sprite)
