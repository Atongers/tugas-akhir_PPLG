@tool
extends Area2D
class_name ExitGate

signal player_reached_exit

@export var is_unlocked: bool = false:
	set(v):
		is_unlocked = v
		_update_visual_state()

var _beam_left: ColorRect = null
var _beam_right: ColorRect = null
var _portal_fill: ColorRect = null
var _status_label: Label = null
var _pulse_time: float = 0.0


func _ready() -> void:
	_rebuild_visuals()
	_update_visual_state()
	if not Engine.is_editor_hint():
		if not body_entered.is_connected(_on_body_entered):
			body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_pulse_time += delta * 4.0
	if is_instance_valid(_portal_fill):
		var alpha := 0.28 + 0.15 * sin(_pulse_time)
		if is_unlocked:
			_portal_fill.color = Color(0.15, 0.95, 0.45, alpha)
		else:
			_portal_fill.color = Color(0.95, 0.2, 0.25, alpha * 0.7)


func set_unlocked(unlocked: bool) -> void:
	is_unlocked = unlocked


func _on_body_entered(body: Node2D) -> void:
	if not is_unlocked:
		return
	if body is CharacterBody2D:
		player_reached_exit.emit()


func _rebuild_visuals() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	_portal_fill = ColorRect.new()
	_portal_fill.name = "PortalFill"
	_portal_fill.position = Vector2(2.0, -16.0)
	_portal_fill.size = Vector2(28.0, 44.0)
	_portal_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portal_fill)

	_beam_left = ColorRect.new()
	_beam_left.name = "BeamLeft"
	_beam_left.position = Vector2(0.0, -16.0)
	_beam_left.size = Vector2(2.0, 44.0)
	_beam_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_beam_left)

	_beam_right = ColorRect.new()
	_beam_right.name = "BeamRight"
	_beam_right.position = Vector2(30.0, -16.0)
	_beam_right.size = Vector2(2.0, 44.0)
	_beam_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_beam_right)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.scale = Vector2(0.4, 0.4)
	_status_label.position = Vector2(-6.0, -28.0)
	add_child(_status_label)

	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28.0, 40.0)
	col.shape = rect
	col.position = Vector2(16.0, 6.0)
	add_child(col)


func _update_visual_state() -> void:
	if is_instance_valid(_beam_left) and is_instance_valid(_beam_right):
		var c := Color(0.2, 1.0, 0.5, 0.95) if is_unlocked else Color(1.0, 0.25, 0.25, 0.9)
		_beam_left.color = c
		_beam_right.color = c
	if is_instance_valid(_status_label):
		_status_label.text = "EXIT [BUKA]" if is_unlocked else "EXIT [KUNCI]"
		_status_label.modulate = Color(0.35, 1.0, 0.55) if is_unlocked else Color(1.0, 0.45, 0.45)
