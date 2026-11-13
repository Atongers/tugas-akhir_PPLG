extends Node2D
class_name VfxBurst

## Lightweight one-shot 4-frame VFX particle burst + hit-stop helper.

static var reduce_screen_shake: bool = false
static var reduce_flash: bool = false

var _sprite: Sprite2D = null
var _vel: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _frame_duration: float = 0.075
var _total_frames: int = 4


func setup(tex: Texture2D, vel: Vector2 = Vector2.ZERO, fps: float = 14.0, total_frames: int = 4) -> void:
	_vel = vel
	_total_frames = maxi(1, total_frames)
	_frame_duration = 1.0 / maxf(1.0, fps)

	_sprite = Sprite2D.new()
	_sprite.texture = tex
	_sprite.hframes = _total_frames
	_sprite.frame = 0
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)


func _process(delta: float) -> void:
	_elapsed += delta
	position += _vel * delta
	_vel *= maxf(0.0, 1.0 - 4.0 * delta)

	var frame_idx := int(_elapsed / _frame_duration)
	if frame_idx >= _total_frames:
		queue_free()
		return
	if is_instance_valid(_sprite):
		_sprite.frame = frame_idx


static func spawn_burst(
	parent: Node,
	texture_path: String,
	world_pos: Vector2,
	count: int = 4,
	spread: float = 28.0,
	upward_bias: float = -24.0
) -> void:
	if not is_instance_valid(parent):
		return
	var tex: Texture2D = load(texture_path)
	if not tex:
		return
	for i in range(count):
		var burst := VfxBurst.new()
		burst.z_index = 25
		var offset := Vector2(randf_range(-6.0, 6.0), randf_range(-4.0, 4.0))
		burst.global_position = world_pos + offset
		var vel := Vector2(randf_range(-spread, spread), randf_range(upward_bias - spread * 0.5, upward_bias * 0.25))
		burst.setup(tex, vel, randf_range(12.0, 17.0), 4)
		parent.add_child(burst)


static func trigger_hit_stop(tree: SceneTree, duration: float = 0.04) -> void:
	if not tree or duration <= 0.0 or reduce_flash:
		return
	if Engine.time_scale < 0.9:
		return
	Engine.time_scale = 0.05
	var timer := tree.create_timer(duration, true, false, true)
	timer.timeout.connect(func() -> void:
		Engine.time_scale = 1.0
	)
