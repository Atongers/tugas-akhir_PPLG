@tool
extends CharacterBody2D
class_name DexController

signal health_changed(current_hp: float, max_hp: float)
signal energy_changed(current_energy: float, max_energy: float)
signal player_damaged(amount: float, source: String)
signal player_died()
signal player_respawned()

const DEFAULT_SKIN_PATH := "res://assets/sprites/characters/dex_skin_default.png"
const VFX_DUST_PATH := "res://assets/sprites/vfx/vfx_dust_cyan.png"
const VFX_SPRINT_TRAIL_PATH := "res://assets/sprites/vfx/vfx_sprint_trail.png"
const CELL_SIZE: int = 32

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
var _was_on_floor: bool = false
var _sprint_dust_timer: float = 0.0
var _hurt_anim_timer: float = 0.0
var _camera_trauma: float = 0.0
var _hit_flash_timer: float = 0.0
var _trail_color: Color = Color("#38bdf8")
var _trail_frames: Array[AtlasTexture] = []
var _trail_frame_idx: int = 0

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera_2d: Camera2D = get_node_or_null("Camera2D")


func _ready() -> void:
	add_to_group("player")
	checkpoint_position = global_position
	health = max_health
	energy = max_energy
	_load_sprint_trail_frames()
	_setup_dex_sprite_frames()
	if not Engine.is_editor_hint() and has_node("/root/SaveManager"):
		var sm := get_node("/root/SaveManager")
		if sm.has_signal("skin_changed") and not sm.skin_changed.is_connected(_on_skin_changed):
			sm.skin_changed.connect(_on_skin_changed)
	health_changed.emit(health, max_health)
	energy_changed.emit(energy, max_energy)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# Camera trauma decay
	if is_instance_valid(camera_2d):
		if _camera_trauma > 0.0 and not VfxBurst.reduce_screen_shake:
			_camera_trauma = maxf(0.0, _camera_trauma - delta * 1.8)
			var shake := _camera_trauma * _camera_trauma * 10.0
			camera_2d.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
		else:
			_camera_trauma = 0.0
			camera_2d.offset = Vector2.ZERO

	# Squash & stretch + hit flash recovery
	if anim_sprite:
		anim_sprite.scale = anim_sprite.scale.lerp(Vector2.ONE, minf(1.0, delta * 14.0))
		if _hit_flash_timer > 0.0:
			_hit_flash_timer -= delta
			anim_sprite.modulate = Color(2.2, 2.2, 2.2, 1.0)
			if _hit_flash_timer <= 0.0:
				anim_sprite.modulate = Color.WHITE

	# Invulnerability frames handling
	if is_invulnerable:
		_iframe_timer -= delta
		if anim_sprite and _hit_flash_timer <= 0.0:
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

	# Landing squash & dust VFX
	if not _was_on_floor and is_on_floor():
		if anim_sprite:
			anim_sprite.scale = Vector2(1.18, 0.84)
		VfxBurst.spawn_burst(get_parent(), VFX_DUST_PATH, global_position, 3, 22.0, -14.0)
	_was_on_floor = is_on_floor()

	# Sprint trail VFX (vfx_sprint_trail.png tinted per active skin)
	if is_sprinting and is_on_floor():
		_sprint_dust_timer -= delta
		if _sprint_dust_timer <= 0.0:
			_sprint_dust_timer = 0.075
			_spawn_sprint_trail()
	else:
		_sprint_dust_timer = 0.0

	if _hurt_anim_timer > 0.0:
		_hurt_anim_timer = maxf(0.0, _hurt_anim_timer - delta)

	_update_animation(direction, is_sprinting)

	# Safe respawn at checkpoint if falling out of bounds
	if global_position.y > 500.0:
		take_damage(50.0, "void")
		if health > 0.0:
			respawn_at_checkpoint()


func add_camera_trauma(amount: float) -> void:
	if VfxBurst.reduce_screen_shake:
		return
	_camera_trauma = minf(1.0, _camera_trauma + maxf(0.0, amount))


func take_damage(amount: float, source: String = "") -> void:
	if is_invulnerable or health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	is_invulnerable = true
	_iframe_timer = iframe_duration
	_hurt_anim_timer = 0.25
	if not VfxBurst.reduce_flash:
		_hit_flash_timer = 0.09
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


func _update_animation(direction: float, is_sprinting: bool = false) -> void:
	if not anim_sprite or not anim_sprite.sprite_frames:
		return
	var target_anim := "idle"
	if _hurt_anim_timer > 0.0:
		target_anim = "hurt"
	elif not is_on_floor():
		target_anim = "jump" if velocity.y < 0.0 else "fall"
	elif not is_zero_approx(direction):
		target_anim = "sprint" if is_sprinting else "walk"

	if anim_sprite.animation != target_anim or not anim_sprite.is_playing():
		anim_sprite.play(target_anim)


func _on_skin_changed(_skin_id: String) -> void:
	_setup_dex_sprite_frames()


func _load_sprint_trail_frames() -> void:
	_trail_frames.clear()
	if not ResourceLoader.exists(VFX_SPRINT_TRAIL_PATH):
		return
	var tex: Texture2D = load(VFX_SPRINT_TRAIL_PATH)
	if not tex:
		return
	for i in range(4):
		_trail_frames.append(_make_atlas(tex, i * 16, 0, 16, 16))


func _spawn_sprint_trail() -> void:
	if _trail_frames.is_empty() or not get_parent():
		return
	var sp := Sprite2D.new()
	sp.texture = _trail_frames[_trail_frame_idx % _trail_frames.size()]
	_trail_frame_idx += 1
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.modulate = _trail_color
	var facing_sign := -1.0 if (anim_sprite and anim_sprite.flip_h) else 1.0
	sp.flip_h = facing_sign < 0.0
	sp.global_position = global_position + Vector2(-facing_sign * 8.0, -7.0)
	sp.z_index = z_index - 1
	get_parent().add_child(sp)
	var tw := sp.create_tween()
	tw.set_parallel(true)
	tw.tween_property(sp, "modulate:a", 0.0, 0.20)
	tw.tween_property(sp, "position:y", sp.position.y - 4.0, 0.20)
	tw.chain().tween_callback(sp.queue_free)


func _setup_dex_sprite_frames() -> void:
	if not anim_sprite:
		anim_sprite = get_node_or_null("AnimatedSprite2D")
	if not anim_sprite:
		return

	var sheet_path := DEFAULT_SKIN_PATH
	_trail_color = Color("#38bdf8")
	if not Engine.is_editor_hint() and has_node("/root/SaveManager"):
		var sm := get_node("/root/SaveManager")
		var meta: Dictionary = sm.call("get_skin_metadata", sm.get("active_skin"))
		sheet_path = str(meta.get("sheet_path", DEFAULT_SKIN_PATH))
		var tc: Variant = meta.get("trail_color", Color("#38bdf8"))
		if tc is Color:
			_trail_color = tc

	var tex: Texture2D = load(sheet_path)
	if not tex:
		tex = load(DEFAULT_SKIN_PATH)
	if not tex:
		return

	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var specs := [
		{"name": "idle", "row": 0, "count": 4, "fps": 6.0, "loop": true},
		{"name": "walk", "row": 1, "count": 8, "fps": 10.0, "loop": true},
		{"name": "sprint", "row": 2, "count": 6, "fps": 14.0, "loop": true},
		{"name": "jump", "row": 3, "count": 2, "fps": 8.0, "loop": false},
		{"name": "fall", "row": 4, "count": 2, "fps": 8.0, "loop": false},
		{"name": "hurt", "row": 5, "count": 2, "fps": 10.0, "loop": false},
	]
	for spec in specs:
		var anim_name: String = str(spec["name"])
		var row_idx: int = int(spec["row"])
		var count: int = int(spec["count"])
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, bool(spec["loop"]))
		frames.set_animation_speed(anim_name, float(spec["fps"]))
		for col in range(count):
			frames.add_frame(anim_name, _make_atlas(tex, col * CELL_SIZE, row_idx * CELL_SIZE, CELL_SIZE, CELL_SIZE))

	anim_sprite.sprite_frames = frames
	anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anim_sprite.offset = Vector2(0.0, -16.0)
	anim_sprite.play("idle")


func _make_atlas(tex: Texture2D, x: int, y: int, w: int, h: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(x, y, w, h)
	atlas.filter_clip = true
	return atlas
