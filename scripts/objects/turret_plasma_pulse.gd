@tool
extends Node2D
class_name TurretPlasmaPulse

signal state_changed(is_active: bool)
signal projectile_fired()

const BASE_PATH := "res://assets/sprites/objects/turret_heavy_base.png"
const HEAD_PATH := "res://assets/sprites/objects/turret_heavy_head.png"
const ORB_SCENE_PATH := "res://scenes/objects/programmable/plasma_orb.tscn"

enum MountOrientation { FLOOR = 0, CEILING = 1, WALL_LEFT = 2, WALL_RIGHT = 3 }

@export var is_active: bool = true:
	set(v):
		is_active = v
		state_changed.emit(is_active)

@export var mount_orientation: MountOrientation = MountOrientation.FLOOR:
	set(v):
		mount_orientation = v
		if is_node_ready():
			_rebuild_visuals()

@export_range(-180.0, 180.0, 1.0) var aim_angle_deg: float = 0.0:
	set(v):
		aim_angle_deg = v
		if is_instance_valid(_head_pivot):
			_head_pivot.rotation_degrees = aim_angle_deg

@export_range(0.4, 10.0, 0.1) var fire_interval: float = 1.6
@export_range(50.0, 400.0, 10.0) var projectile_speed: float = 130.0

var _base_sprite: Sprite2D = null
var _head_pivot: Node2D = null
var _head_sprite: Sprite2D = null
var _muzzle_marker: Marker2D = null

var _time_since_shot: float = 0.0
var _recoil_offset: float = 0.0


func _ready() -> void:
	_rebuild_visuals()


func _process(delta: float) -> void:
	# Recoil recovery
	if _recoil_offset > 0.0:
		_recoil_offset = maxf(0.0, _recoil_offset - delta * 18.0)
		if is_instance_valid(_head_sprite):
			_head_sprite.position.x = -11.0 - _recoil_offset

	if not is_active or Engine.is_editor_hint():
		return

	_time_since_shot += delta
	if _time_since_shot >= fire_interval:
		_time_since_shot = 0.0
		_fire_projectile()


func _rebuild_visuals() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	# 1. Heavy Base Sprite
	_base_sprite = Sprite2D.new()
	_base_sprite.name = "HeavyBaseSprite"
	_base_sprite.texture = load(BASE_PATH)
	_base_sprite.centered = true
	add_child(_base_sprite)

	match mount_orientation:
		MountOrientation.FLOOR: rotation_degrees = 0.0
		MountOrientation.CEILING: rotation_degrees = 180.0
		MountOrientation.WALL_LEFT: rotation_degrees = 90.0
		MountOrientation.WALL_RIGHT: rotation_degrees = -90.0

	# 2. Head Pivot Node (Socket ball at Vector2(0, -6))
	_head_pivot = Node2D.new()
	_head_pivot.name = "HeadPivot"
	_head_pivot.position = Vector2(0, -6)
	_head_pivot.rotation_degrees = aim_angle_deg
	add_child(_head_pivot)

	# 3. Heavy Head Sprite (pivot at 11, 10)
	_head_sprite = Sprite2D.new()
	_head_sprite.name = "HeavyHeadSprite"
	_head_sprite.texture = load(HEAD_PATH)
	_head_sprite.centered = false
	_head_sprite.position = Vector2(-11, -10)
	_head_pivot.add_child(_head_sprite)

	# 4. Muzzle Marker (At end of barrel: x = 26, y = 0)
	_muzzle_marker = Marker2D.new()
	_muzzle_marker.name = "MuzzleMarker"
	_muzzle_marker.position = Vector2(26, 0)
	_head_pivot.add_child(_muzzle_marker)

	# 5. Base Solid Collision
	var sb := StaticBody2D.new()
	sb.name = "BaseCollider"
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(26.0, 10.0)
	cs.shape = rect
	cs.position = Vector2(0, 3)
	sb.add_child(cs)
	add_child(sb)


func _fire_projectile() -> void:
	if not ResourceLoader.exists(ORB_SCENE_PATH):
		return

	var orb_scene: PackedScene = load(ORB_SCENE_PATH)
	if not orb_scene:
		return

	var orb: PlasmaOrb = orb_scene.instantiate() as PlasmaOrb
	if not orb:
		return

	# Add projectile to level root so its position isn't tied to moving turret
	var spawn_pos: Vector2 = _muzzle_marker.global_position if is_instance_valid(_muzzle_marker) else global_position
	var fire_dir: Vector2 = Vector2.RIGHT.rotated(_head_pivot.global_rotation)

	orb.global_position = spawn_pos
	orb.direction = fire_dir
	orb.speed = projectile_speed
	orb.rotation = _head_pivot.global_rotation

	get_tree().current_scene.add_child(orb)

	# Trigger visual recoil
	_recoil_offset = 4.0
	projectile_fired.emit()


# Python Terminal API
func matikan_tembakan() -> void:
	is_active = false


func nyalakan_tembakan() -> void:
	is_active = true


func set_interval(detik: float) -> void:
	fire_interval = maxf(0.3, detik)


func set_sudut(derajat: float) -> void:
	aim_angle_deg = derajat


func set_kecepatan(px_per_sec: float) -> void:
	projectile_speed = maxf(30.0, px_per_sec)
