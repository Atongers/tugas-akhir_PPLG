@tool
extends Node2D
class_name Turret

signal state_changed(is_active: bool)
signal target_detected(target: Node2D)
signal target_lost()

const BASE_PATH := "res://assets/sprites/objects/turret_base.png"
const HEAD_CYAN_PATH := "res://assets/sprites/objects/turret_head_cyan.png"
const HEAD_RED_PATH := "res://assets/sprites/objects/turret_head_red.png"
const HEAD_FIRE_PATH := "res://assets/sprites/objects/turret_head_fire.png"

const COLOR_CYAN_LASER := Color(0.22, 0.75, 0.98, 0.75)
const COLOR_RED_LASER := Color(0.94, 0.27, 0.27, 0.85)

enum MountOrientation {
	FLOOR = 0,
	CEILING = 1,
	WALL_LEFT = 2,
	WALL_RIGHT = 3,
}

enum AimMode {
	FIXED = 0,
	SWEEP_SCAN = 1,
	TRACK_TARGET = 2,
}

enum ColorTheme {
	CYAN_BLUE = 0,
	ALERT_RED = 1,
}

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

@export var aim_mode: AimMode = AimMode.SWEEP_SCAN:
	set(v):
		aim_mode = v

@export_range(-180.0, 180.0, 1.0) var fixed_angle_deg: float = 0.0:
	set(v):
		fixed_angle_deg = v

@export_range(-90.0, 90.0, 1.0) var sweep_angle_min_deg: float = -40.0
@export_range(-90.0, 90.0, 1.0) var sweep_angle_max_deg: float = 40.0
@export_range(0.1, 5.0, 0.1) var sweep_speed: float = 1.0

@export var has_laser_sight: bool = true:
	set(v):
		has_laser_sight = v
		if is_instance_valid(_laser_line):
			_laser_line.visible = is_active and has_laser_sight

@export var theme_color: ColorTheme = ColorTheme.CYAN_BLUE:
	set(v):
		theme_color = v
		_update_head_texture()

@export_range(50.0, 500.0, 10.0) var laser_range: float = 220.0
@export_range(50.0, 400.0, 10.0) var detection_radius: float = 180.0

var _base_sprite: Sprite2D = null
var _head_pivot: Node2D = null
var _head_sprite: Sprite2D = null
var _laser_line: Line2D = null
var _raycast: RayCast2D = null
var _static_body: StaticBody2D = null
var _detect_area: Area2D = null

var _tracked_target: Node2D = null
var _current_aim_angle: float = 0.0
var _sweep_time: float = 0.0


func _ready() -> void:
	_rebuild_visuals()
	_update_state()


func _process(delta: float) -> void:
	if not is_active:
		if is_instance_valid(_head_pivot):
			# Lower barrel to rest angle when deactivated
			_head_pivot.rotation = lerp_angle(_head_pivot.rotation, deg_to_rad(15.0), delta * 4.0)
		if is_instance_valid(_laser_line):
			_laser_line.visible = false
		return

	_update_aim(delta)
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
	_base_sprite.position = Vector2(0, 0)
	add_child(_base_sprite)

	# Apply orientation rotation
	match mount_orientation:
		MountOrientation.FLOOR:
			rotation_degrees = 0.0
		MountOrientation.CEILING:
			rotation_degrees = 180.0
		MountOrientation.WALL_LEFT:
			rotation_degrees = 90.0
		MountOrientation.WALL_RIGHT:
			rotation_degrees = -90.0

	# 2. Head Pivot Node (placed at swivel ball: Vector2(0, -6))
	_head_pivot = Node2D.new()
	_head_pivot.name = "HeadPivot"
	_head_pivot.position = Vector2(0, -6)
	add_child(_head_pivot)

	# 3. Head Sprite (attached to pivot, offset so (10, 9) in sprite aligns with pivot (0, 0))
	_head_sprite = Sprite2D.new()
	_head_sprite.name = "HeadSprite"
	_head_sprite.centered = false
	_head_sprite.position = Vector2(-10, -9)
	_head_pivot.add_child(_head_sprite)
	_update_head_texture()

	# 4. Laser Sight Line
	_laser_line = Line2D.new()
	_laser_line.name = "LaserLine"
	_laser_line.width = 1.5
	_laser_line.default_color = COLOR_CYAN_LASER if theme_color == ColorTheme.CYAN_BLUE else COLOR_RED_LASER
	_laser_line.add_point(Vector2(24, 0)) # from muzzle tip
	_laser_line.add_point(Vector2(24 + laser_range, 0))
	_laser_line.visible = is_active and has_laser_sight
	_head_pivot.add_child(_laser_line)

	# 5. RayCast2D for laser collision (only active in game)
	_raycast = RayCast2D.new()
	_raycast.name = "LaserRayCast"
	_raycast.position = Vector2(24, 0)
	_raycast.target_position = Vector2(laser_range, 0)
	_raycast.enabled = not Engine.is_editor_hint()
	_raycast.collision_mask = 1 # World & player collision
	_head_pivot.add_child(_raycast)

	# 6. Base Static Collision (Player can stand on top / bump base)
	_static_body = StaticBody2D.new()
	_static_body.name = "BaseCollision"
	var col_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24.0, 10.0)
	col_shape.shape = rect
	col_shape.position = Vector2(0, 3)
	_static_body.add_child(col_shape)
	add_child(_static_body)

	# 7. Detection Area (for target tracking)
	if not Engine.is_editor_hint():
		_detect_area = Area2D.new()
		_detect_area.name = "DetectArea"
		_detect_area.collision_layer = 0
		_detect_area.collision_mask = 2 # Characters layer
		var circle := CircleShape2D.new()
		circle.radius = detection_radius
		var det_col := CollisionShape2D.new()
		det_col.shape = circle
		_detect_area.add_child(det_col)
		_detect_area.body_entered.connect(_on_body_entered)
		_detect_area.body_exited.connect(_on_body_exited)
		add_child(_detect_area)


func _update_head_texture() -> void:
	if not is_instance_valid(_head_sprite):
		return
	var path := HEAD_CYAN_PATH if theme_color == ColorTheme.CYAN_BLUE else HEAD_RED_PATH
	if ResourceLoader.exists(path):
		_head_sprite.texture = load(path)
	if is_instance_valid(_laser_line):
		_laser_line.default_color = COLOR_CYAN_LASER if theme_color == ColorTheme.CYAN_BLUE else COLOR_RED_LASER


func _update_state() -> void:
	_update_head_texture()
	if is_instance_valid(_laser_line):
		_laser_line.visible = is_active and has_laser_sight
	if is_instance_valid(_raycast):
		_raycast.enabled = is_active and not Engine.is_editor_hint()


func _update_aim(delta: float) -> void:
	if not is_instance_valid(_head_pivot):
		return

	var target_angle_rad: float = 0.0

	match aim_mode:
		AimMode.FIXED:
			target_angle_rad = deg_to_rad(fixed_angle_deg)
		AimMode.SWEEP_SCAN:
			_sweep_time += delta * sweep_speed
			var t := (sin(_sweep_time) + 1.0) * 0.5
			var angle_deg := lerpf(sweep_angle_min_deg, sweep_angle_max_deg, t)
			target_angle_rad = deg_to_rad(angle_deg)
		AimMode.TRACK_TARGET:
			if is_instance_valid(_tracked_target):
				var diff := _tracked_target.global_position - _head_pivot.global_position
				target_angle_rad = diff.angle() - global_rotation
			else:
				# Fallback to sweep scan when target is lost
				_sweep_time += delta * sweep_speed
				var t := (sin(_sweep_time) + 1.0) * 0.5
				target_angle_rad = deg_to_rad(lerpf(sweep_angle_min_deg, sweep_angle_max_deg, t))

	_current_aim_angle = lerp_angle(_current_aim_angle, target_angle_rad, delta * 6.0)
	_head_pivot.rotation = _current_aim_angle


func _update_laser() -> void:
	if not is_instance_valid(_laser_line) or not has_laser_sight or not is_active:
		return

	_laser_line.visible = true
	var hit_dist: float = laser_range

	if not Engine.is_editor_hint() and is_instance_valid(_raycast) and _raycast.is_colliding():
		var col_pt := _raycast.get_collision_point()
		hit_dist = _raycast.global_position.distance_to(col_pt)

	_laser_line.set_point_position(0, Vector2(24, 0))
	_laser_line.set_point_position(1, Vector2(24 + hit_dist, 0))


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D or body.name.to_lower().contains("dex"):
		_tracked_target = body
		theme_color = ColorTheme.ALERT_RED
		target_detected.emit(body)


func _on_body_exited(body: Node2D) -> void:
	if body == _tracked_target:
		_tracked_target = null
		theme_color = ColorTheme.CYAN_BLUE
		target_lost.emit()


# Python / Terminal Callable API
func deactivate() -> void:
	is_active = false


func activate() -> void:
	is_active = true


func matikan_turret() -> void:
	deactivate()


func nyalakan_turret() -> void:
	activate()


func set_aim_angle(degrees: float) -> void:
	aim_mode = AimMode.FIXED
	fixed_angle_deg = degrees


func set_sweep(min_deg: float, max_deg: float, speed: float = 1.0) -> void:
	aim_mode = AimMode.SWEEP_SCAN
	sweep_angle_min_deg = min_deg
	sweep_angle_max_deg = max_deg
	sweep_speed = speed
