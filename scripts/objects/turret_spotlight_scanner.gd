@tool
extends Node2D
class_name TurretSpotlightScanner

signal state_changed(is_active: bool)
signal alarm_triggered(player: Node2D)
signal alarm_cleared()

const TRIPOD_PATH := "res://assets/sprites/objects/turret_tripod_base.png"
const HEAD_CYAN_PATH := "res://assets/sprites/objects/turret_scanner_head.png"
const HEAD_RED_PATH := "res://assets/sprites/objects/turret_scanner_head_red.png"

const COLOR_CONE_CYAN := Color(0.22, 0.75, 0.98, 0.22)
const COLOR_CONE_RED := Color(0.95, 0.2, 0.2, 0.45)

enum MountOrientation { FLOOR = 0, CEILING = 1, WALL_LEFT = 2, WALL_RIGHT = 3 }

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

@export_range(-90.0, 90.0, 1.0) var sweep_min_deg: float = -45.0
@export_range(-90.0, 90.0, 1.0) var sweep_max_deg: float = 45.0
@export_range(0.1, 4.0, 0.1) var sweep_speed: float = 0.8

@export_range(50.0, 400.0, 10.0) var spotlight_range: float = 170.0:
	set(v):
		spotlight_range = v
		_build_cone_geometry()

@export_range(20.0, 90.0, 5.0) var spotlight_angle_deg: float = 50.0:
	set(v):
		spotlight_angle_deg = v
		_build_cone_geometry()

@export var zap_damage: float = 25.0
@export var zap_cooldown: float = 1.2

var _base_sprite: Sprite2D = null
var _head_pivot: Node2D = null
var _head_sprite: Sprite2D = null
var _cone_polygon: Polygon2D = null
var _cone_area: Area2D = null
var _cone_collision: CollisionPolygon2D = null

var _sweep_time: float = 0.0
var _zap_timer: float = 0.0
var _is_alarm_active: bool = false
var _tracked_player: Node2D = null


func _ready() -> void:
	_rebuild_visuals()
	_update_state()


func _process(delta: float) -> void:
	if not is_active:
		if is_instance_valid(_cone_polygon):
			_cone_polygon.visible = false
		if _is_alarm_active:
			_set_alarm(false)
			alarm_cleared.emit()
		_tracked_player = null
		return

	_zap_timer = maxf(0.0, _zap_timer - delta)

	# Sweep scan rotation
	_sweep_time += delta * sweep_speed
	var t := (sin(_sweep_time) + 1.0) * 0.5
	var angle_deg := lerpf(sweep_min_deg, sweep_max_deg, t)
	if is_instance_valid(_head_pivot):
		_head_pivot.rotation_degrees = angle_deg

	if not Engine.is_editor_hint() and is_instance_valid(_tracked_player):
		if _has_line_of_sight(_tracked_player):
			if not _is_alarm_active:
				_set_alarm(true)
				alarm_triggered.emit(_tracked_player)
			if _zap_timer <= 0.0 and _tracked_player.has_method("take_damage"):
				_tracked_player.take_damage(zap_damage, "scanner")
				_zap_timer = zap_cooldown
		elif _is_alarm_active:
			_set_alarm(false)
			alarm_cleared.emit()


func _rebuild_visuals() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	# 1. Tripod Base Sprite
	_base_sprite = Sprite2D.new()
	_base_sprite.name = "TripodBaseSprite"
	_base_sprite.texture = load(TRIPOD_PATH)
	_base_sprite.centered = true
	_base_sprite.position = Vector2(0, 0)
	add_child(_base_sprite)

	match mount_orientation:
		MountOrientation.FLOOR: rotation_degrees = 0.0
		MountOrientation.CEILING: rotation_degrees = 180.0
		MountOrientation.WALL_LEFT: rotation_degrees = 90.0
		MountOrientation.WALL_RIGHT: rotation_degrees = -90.0

	# 2. Scanner Head Pivot (Collar at Vector2(0, -9))
	_head_pivot = Node2D.new()
	_head_pivot.name = "ScannerPivot"
	_head_pivot.position = Vector2(0, -9)
	add_child(_head_pivot)

	# 3. Scanner Head Sprite (pivot at 9, 10)
	_head_sprite = Sprite2D.new()
	_head_sprite.name = "ScannerHeadSprite"
	_head_sprite.texture = load(HEAD_CYAN_PATH)
	_head_sprite.centered = false
	_head_sprite.position = Vector2(-9, -10)
	_head_pivot.add_child(_head_sprite)

	# 4. Volumetric Vision Cone Polygon
	_cone_polygon = Polygon2D.new()
	_cone_polygon.name = "VisionCone"
	_cone_polygon.color = COLOR_CONE_CYAN
	_head_pivot.add_child(_cone_polygon)

	# 5. Detection Area2D inside cone
	if not Engine.is_editor_hint():
		_cone_area = Area2D.new()
		_cone_area.name = "ConeDetectionArea"
		_cone_area.collision_layer = 0
		_cone_area.collision_mask = 1 | 2 # Detect player on layer 1 or 2
		_cone_collision = CollisionPolygon2D.new()
		_cone_area.add_child(_cone_collision)
		_cone_area.body_entered.connect(_on_cone_body_entered)
		_cone_area.body_exited.connect(_on_cone_body_exited)
		_head_pivot.add_child(_cone_area)

	_build_cone_geometry()

	# 6. Tripod Solid Collision
	var sb := StaticBody2D.new()
	sb.name = "TripodCollider"
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24.0, 14.0)
	cs.shape = rect
	cs.position = Vector2(0, 4)
	sb.add_child(cs)
	add_child(sb)


func _build_cone_geometry() -> void:
	if not is_instance_valid(_cone_polygon):
		return

	var half_rad := deg_to_rad(spotlight_angle_deg * 0.5)
	var origin := Vector2(17, 0) # Lens position on head

	var points := PackedVector2Array()
	points.append(origin)

	# Arc segments
	var segments := 12
	for i in range(segments + 1):
		var frac := float(i) / float(segments)
		var cur_angle := lerpf(-half_rad, half_rad, frac)
		var pt := origin + Vector2(cos(cur_angle), sin(cur_angle)) * spotlight_range
		points.append(pt)

	_cone_polygon.polygon = points
	if is_instance_valid(_cone_collision):
		_cone_collision.polygon = points


func _update_state() -> void:
	if is_instance_valid(_cone_polygon):
		_cone_polygon.visible = is_active
	if is_instance_valid(_cone_area):
		_cone_area.monitoring = is_active


func _on_cone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body is CharacterBody2D or body.name.to_lower().contains("dex"):
		_tracked_player = body
		if _has_line_of_sight(body):
			_set_alarm(true)
			alarm_triggered.emit(body)
			if _zap_timer <= 0.0 and body.has_method("take_damage"):
				body.take_damage(zap_damage, "scanner")
				_zap_timer = zap_cooldown


func _has_line_of_sight(target: Node2D) -> bool:
	if not is_instance_valid(_head_pivot) or not is_instance_valid(target):
		return false
	var space := get_world_2d().direct_space_state
	if not space:
		return true
	var from_pos := _head_pivot.global_position
	var to_pos := target.global_position + Vector2(0.0, -10.0)
	var query := PhysicsRayQueryParameters2D.create(from_pos, to_pos, 1)
	query.exclude = [self]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return true
	return hit.get("collider") == target


func _on_cone_body_exited(body: Node2D) -> void:
	if body == _tracked_player:
		_tracked_player = null
		_set_alarm(false)
		alarm_cleared.emit()


func _set_alarm(alert: bool) -> void:
	_is_alarm_active = alert
	if is_instance_valid(_cone_polygon):
		_cone_polygon.color = COLOR_CONE_RED if alert else COLOR_CONE_CYAN
	if is_instance_valid(_head_sprite):
		var path := HEAD_RED_PATH if alert else HEAD_CYAN_PATH
		if ResourceLoader.exists(path):
			_head_sprite.texture = load(path)


# Python Terminal API
func matikan_sensor() -> void:
	is_active = false
	if is_instance_valid(_head_pivot):
		_head_pivot.rotation_degrees = 35.0
	_set_alarm(false)


func nyalakan_sensor() -> void:
	is_active = true


func matikan_alarm() -> void:
	_set_alarm(false)


func set_sweep(min_deg: float, max_deg: float, speed: float = 0.8) -> void:
	sweep_min_deg = min_deg
	sweep_max_deg = max_deg
	sweep_speed = speed


func set_jarak_pandang(px: float) -> void:
	spotlight_range = px
