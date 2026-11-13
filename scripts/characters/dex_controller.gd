@tool
extends CharacterBody2D
class_name DexController

signal health_changed(current_hp: float, max_hp: float)
signal energy_changed(current_energy: float, max_energy: float)
signal player_damaged(amount: float, source: String)
signal player_died()
signal player_respawned()

const SPRITESHEET_PATH := "res://assets/sprites/characters/characters.png"
## Row 2 in 1-based numbering (index 1: Cyan Antenna Bot)
const DEX_ROW_INDEX: int = 1
const FRAME_Y_START: int = DEX_ROW_INDEX * 32 - 2
const FRAME_HEIGHT: int = 32
const WALK_FRAME_COUNT: int = 8

@export_group("Movement Physics")
@export var move_speed: float = 95.0
@export var acceleration: float = 600.0
@export var friction: float = 700.0
@export var jump_velocity: float = -215.0
@export var gravity_scale: float = 0.62
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

@export_group("Vitality Stats")
@export var max_health: float = 100.0
@export var max_energy: float = 100.0
@export var sprint_speed_multiplier: float = 1.6
@export var sprint_energy_cost: float = 15.0 # per second
@export var passive_energy_regen: float = 8.0 # per second
@export var fast_recharge_rate: float = 80.0 # per second
@export var iframe_duration: float = 1.0 # seconds

var health: float = 100.0
var energy: float = 100.0
var is_invulnerable: bool = false
var is_in_recharge_zone: bool = false
var _iframe_timer: float = 0.0

var checkpoint_position: Vector2 = Vector2.ZERO
var controls_enabled: bool = true

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("player")
	checkpoint_position = global_position
	health = max_health
	energy = max_energy
	_setup_dex_sprite_frames()
	health_changed.emit(health, max_health)
	energy_changed.emit(energy, max_energy)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# Invulnerability frames handling
	if is_invulnerable:
		_iframe_timer -= delta
		if anim_sprite:
			anim_sprite.modulate.a = 0.35 if int(_iframe_timer * 16.0) % 2 == 0 else 1.0
		if _iframe_timer <= 0.0:
			is_invulnerable = false
			if anim_sprite:
				anim_sprite.modulate.a = 1.0

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

	# Sprint and Energy Logic
	var is_sprinting: bool = false
	if controls_enabled and (Input.is_action_pressed("sprint") or Input.is_key_pressed(KEY_SHIFT)):
		if not is_zero_approx(direction) and energy > 0.0:
			is_sprinting = true
			energy = maxf(0.0, energy - sprint_energy_cost * delta)
			energy_changed.emit(energy, max_energy)

	if not is_sprinting and energy < max_energy:
		var regen_rate := fast_recharge_rate if is_in_recharge_zone else passive_energy_regen
		energy = minf(max_energy, energy + regen_rate * delta)
		energy_changed.emit(energy, max_energy)

	var effective_speed := move_speed * (sprint_speed_multiplier if is_sprinting else 1.0)

	if not is_zero_approx(direction):
		velocity.x = move_toward(velocity.x, direction * effective_speed, acceleration * delta)
		if anim_sprite:
			anim_sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	move_and_slide()
	_update_animation(direction)

	# Safe respawn at checkpoint if falling out of bounds
	if global_position.y > 500.0:
		take_damage(50.0, "void")
		if health > 0.0:
			respawn_at_checkpoint()


func take_damage(amount: float, source: String = "") -> void:
	if is_invulnerable or health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	is_invulnerable = true
	_iframe_timer = iframe_duration
	velocity.y = -120.0
	player_damaged.emit(amount, source)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		_handle_death()


func consume_energy(amount: float) -> bool:
	if energy >= amount:
		energy = maxf(0.0, energy - amount)
		energy_changed.emit(energy, max_energy)
		return true
	return false


func add_energy(amount: float) -> void:
	energy = minf(max_energy, energy + amount)
	energy_changed.emit(energy, max_energy)


func _handle_death() -> void:
	player_died.emit()
	respawn_at_checkpoint()
	health = max_health
	energy = max_energy
	health_changed.emit(health, max_health)
	energy_changed.emit(energy, max_energy)


func respawn_at_checkpoint() -> void:
	global_position = checkpoint_position
	velocity = Vector2.ZERO
	is_invulnerable = true
	_iframe_timer = iframe_duration * 0.5
	if anim_sprite:
		anim_sprite.modulate.a = 1.0
	player_respawned.emit()


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
