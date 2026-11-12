@tool
extends Node2D
class_name TurretLaserSentry

signal state_changed(is_active: bool)
signal player_tripped(player: Node2D)

const BASE_PATH := "res://assets/sprites/objects/turret_base.png"
const HEAD_CYAN_PATH := "res://assets/sprites/objects/turret_head_cyan.png"
const HEAD_RED_PATH := "res://assets/sprites/objects/turret_head_red.png"

const COLOR_CYAN_LASER := Color(0.22, 0.75, 0.98, 0.8)
const COLOR_RED_LASER := Color(0.95, 0.25, 0.25, 0.9)

enum MountOrientation { FLOOR = 0, CEILING = 1, WALL_LEFT = 2, WALL_RIGHT = 3 }
enum AimMode { FIXED = 0, SWEEP_SCAN = 1, TRACK_PLAYER = 2 }

@export var is_active: bool = true:
	set(v):
		is_active = v
		_update_state()
		state_changed.emit(is_active)

@export var mount_orientation: MountOrientation = MountOrientation.FLOOR:
	set(v):
		mount_orientation = v
		if is_node_ready():
			_rebuild_visuals()

@export var aim_mode: AimMode = AimMode.SWEEP_SCAN
@export_range(-180.0, 180.0, 1.0) var fixed_angle_deg: float = 0.0
@export_range(-90.0, 90.0, 1.0) var sweep_min_deg: float = -45.0
@export_range(-90.0, 90.0, 1.0) var sweep_max_deg: float = 45.0
@export_range(0.1, 4.0, 0.1) var sweep_speed: float = 1.0
@export_range(50.0, 600.0, 10.0) var max_laser_length: float = 300.0

var _base_sprite: Sprite2D = null
var _head_pivot: Node2D = null
var _head_sprite: Sprite2D = null
var _laser_line: Line2D = null
var _raycast: RayCast2D = null
var _tracked_body: Node2D = null

var _sweep_time: float = 0.0
var _current_angle: float = 0.0


func _ready() -> void:
	_rebuild_visuals()
	_update_state()


func _process(delta: float) -> void:
	if not is_active:
		if is_instance_valid(_head_pivot):
			_head_pivot.rotation = lerp_angle(_head_pivot.rotation, deg_to_rad(15.0), delta * 4.0)
		if is_instance_valid(_laser_line):
			_laser_line.visible = false
		return

	_update_rotation(delta)
	_update_laser()


func _rebuild_visuals() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	# 1. Base Sprite
	_base_sprite = Sprite2D.new()
	_base_sprite.name = "BaseSprite"
	_base_sprite.texture = load(BASE_PATH)
	_base_sprite.centered = true
	add_child(_base_sprite)

	match mount_orientation:
		MountOrientation.FLOOR: rotation_degrees = 0.0
		MountOrientation.CEILING: rotation_degrees = 180.0
		MountOrientation.WALL_LEFT: rotation_degrees = 90.0
		MountOrientation.WALL_RIGHT: rotation_degrees = -90.0

	# 2. Head Pivot
	_head_pivot = Node2D.new()
	_head_pivot.name = "HeadPivot"
	_head_pivot.position = Vector2(0, -6)
	add_child(_head_pivot)

	# 3. Head Sprite
	_head_sprite = Sprite2D.new()
	_head_sprite.name = "HeadSprite"
	_head_sprite.texture = load(HEAD_CYAN_PATH)
	_head_sprite.centered = false
	_head_sprite.position = Vector2(-10, -9)
	_head_pivot.add_child(_head_sprite)

	# 4. Laser Line
	_laser_line = Line2D.new()
	_laser_line.name = "LaserLine"
	_laser_line.width = 2.0
	_laser_line.default_color = COLOR_CYAN_LASER
	_laser_line.add_point(Vector2(24, 0))
	_laser_line.add_point(Vector2(24 + max_laser_length, 0))
	_head_pivot.add_child(_laser_line)

	# 5. RayCast for physical laser tripwire
	_raycast = RayCast2D.new()
	_raycast.name = "LaserRay"
	_raycast.position = Vector2(24, 0)
	_raycast.target_position = Vector2(max_laser_length, 0)
	_raycast.enabled = not Engine.is_editor_hint()
	_raycast.collision_mask = 1 | 2 # World (1) and Players (2)
	_head_pivot.add_child(_raycast)

	# 6. Physical Base Collision
	var sb := StaticBody2D.new()
	sb.name = "BaseCollider"
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24.0, 10.0)
	cs.shape = rect
	cs.position = Vector2(0, 3)
	sb.add_child(cs)
	add_child(sb)


func _update_state() -> void:
	if is_instance_valid(_laser_line):
		_laser_line.visible = is_active
	if is_instance_valid(_raycast):
		_raycast.enabled = is_active and not Engine.is_editor_hint()


func _update_rotation(delta: float) -> void:
	if not is_instance_valid(_head_pivot):
		return

	var target_rad: float = 0.0
	match aim_mode:
		AimMode.FIXED:
			target_rad = deg_to_rad(fixed_angle_deg)
		AimMode.SWEEP_SCAN:
			_sweep_time += delta * sweep_speed
			var t := (sin(_sweep_time) + 1.0) * 0.5
			target_rad = deg_to_rad(lerpf(sweep_min_deg, sweep_max_deg, t))
		AimMode.TRACK_PLAYER:
			if is_instance_valid(_tracked_body):
				var diff := _tracked_body.global_position - _head_pivot.global_position
				target_rad = diff.angle() - global_rotation
			else:
				_sweep_time += delta * sweep_speed
				var t := (sin(_sweep_time) + 1.0) * 0.5
				target_rad = deg_to_rad(lerpf(sweep_min_deg, sweep_max_deg, t))

	_current_angle = lerp_angle(_current_angle, target_rad, delta * 6.0)
	_head_pivot.rotation = _current_angle


func _update_laser() -> void:
	if not is_instance_valid(_laser_line) or not is_active:
		return

	_laser_line.visible = true
	var hit_dist: float = max_laser_length

	if not Engine.is_editor_hint() and is_instance_valid(_raycast) and _raycast.is_colliding():
		var col_pt := _raycast.get_collision_point()
		hit_dist = _raycast.global_position.distance_to(col_pt)
		var collider := _raycast.get_collider()
		if is_instance_valid(collider) and (collider is CharacterBody2D or collider.name.to_lower().contains("dex")):
			if _laser_line.default_color != COLOR_RED_LASER:
				_laser_line.default_color = COLOR_RED_LASER
				if is_instance_valid(_head_sprite):
					_head_sprite.texture = load(HEAD_RED_PATH)
				player_tripped.emit(collider)
		else:
			if _laser_line.default_color != COLOR_CYAN_LASER:
				_laser_line.default_color = COLOR_CYAN_LASER
				if is_instance_valid(_head_sprite):
					_head_sprite.texture = load(HEAD_CYAN_PATH)

	_laser_line.set_point_position(0, Vector2(24, 0))
	_laser_line.set_point_position(1, Vector2(24 + hit_dist, 0))


# Python Terminal API
func matikan_laser() -> void:
	is_active = false


func nyalakan_laser() -> void:
	is_active = true


func set_sudut(derajat: float) -> void:
	aim_mode = AimMode.FIXED
	fixed_angle_deg = derajat


func set_sweep(min_deg: float, max_deg: float, speed: float = 1.0) -> void:
	aim_mode = AimMode.SWEEP_SCAN
	sweep_min_deg = min_deg
	sweep_max_deg = max_deg
	sweep_speed = speed
