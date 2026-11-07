@tool
extends CharacterBody2D
class_name DexController

const SPRITESHEET_PATH := "res://assets/sprites/characters/characters.png"
## Row 2 in 1-based numbering (index 1: Cyan Antenna Bot)
const DEX_ROW_INDEX: int = 1
const FRAME_Y_START: int = DEX_ROW_INDEX * 32 - 2
const FRAME_HEIGHT: int = 32
const WALK_FRAME_COUNT: int = 8

@export_group("Movement Physics")
@export var move_speed: float = 240.0
@export var acceleration: float = 1200.0
@export var friction: float = 1400.0
@export var jump_velocity: float = -460.0
@export var gravity_scale: float = 1.0
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

var checkpoint_position: Vector2 = Vector2.ZERO
var controls_enabled: bool = true

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	checkpoint_position = global_position
	_setup_dex_sprite_frames()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0) * gravity_scale

	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)
		velocity.y += gravity * delta

	if controls_enabled and Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0

	if controls_enabled and Input.is_action_just_released("jump") and velocity.y < jump_velocity * 0.5:
		velocity.y = jump_velocity * 0.5

	var direction: float = 0.0
	if controls_enabled:
		direction = Input.get_axis("move_left", "move_right")

	if not is_zero_approx(direction):
		velocity.x = move_toward(velocity.x, direction * move_speed, acceleration * delta)
		if anim_sprite:
			anim_sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	move_and_slide()
	_update_animation(direction)

	# Safe respawn at checkpoint if falling into a pit (GDD: Gagal itu aman)
	if global_position.y > 750.0:
		respawn_at_checkpoint()


func respawn_at_checkpoint() -> void:
	global_position = checkpoint_position
	velocity = Vector2.ZERO


func _update_animation(direction: float) -> void:
	if not anim_sprite or not anim_sprite.sprite_frames:
		return
	var target_anim := "idle"
	if not is_on_floor():
		target_anim = "jump" if velocity.y < 0.0 else "fall"
	elif not is_zero_approx(direction):
		target_anim = "walk"

	if anim_sprite.animation != target_anim or not anim_sprite.is_playing():
		anim_sprite.play(target_anim)


func _setup_dex_sprite_frames() -> void:
	if not anim_sprite:
		anim_sprite = get_node_or_null("AnimatedSprite2D")
	if not anim_sprite:
		return

	var tex: Texture2D = load(SPRITESHEET_PATH)
	if not tex:
		return

	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	# Idle animation (columns 0..3)
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 6.0)
	for col in range(4):
		frames.add_frame("idle", _make_atlas(tex, 2 + col * 16, FRAME_Y_START, 16, FRAME_HEIGHT))

	# Walk animation (columns 5..12)
	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 10.0)
	for i in range(WALK_FRAME_COUNT):
		var col := 5 + i
		frames.add_frame("walk", _make_atlas(tex, 2 + col * 16, FRAME_Y_START, 16, FRAME_HEIGHT))

	# Jump & Fall poses
	frames.add_animation("jump")
	frames.set_animation_loop("jump", false)
	frames.set_animation_speed("jump", 5.0)
	frames.add_frame("jump", _make_atlas(tex, 2 + 6 * 16, FRAME_Y_START, 16, FRAME_HEIGHT))

	frames.add_animation("fall")
	frames.set_animation_loop("fall", false)
	frames.set_animation_speed("fall", 5.0)
	frames.add_frame("fall", _make_atlas(tex, 2 + 8 * 16, FRAME_Y_START, 16, FRAME_HEIGHT))

	anim_sprite.sprite_frames = frames
	anim_sprite.offset = Vector2(0.0, -FRAME_HEIGHT * 0.5)
	anim_sprite.play("idle")


func _make_atlas(tex: Texture2D, x: int, y: int, w: int, h: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(x, y, w, h)
	atlas.filter_clip = true
	return atlas
