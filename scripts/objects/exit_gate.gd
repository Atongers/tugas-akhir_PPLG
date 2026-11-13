@tool
extends Area2D
class_name ExitGate

signal player_reached_exit

const GATE_SHEET_PATH := "res://assets/sprites/objects/exit_gate_sheet.png"
const VFX_SOLVED_PATH := "res://assets/sprites/vfx/vfx_energy_solved.png"

@export var is_unlocked: bool = false:
	set(v):
		var was_unlocked := is_unlocked
		is_unlocked = v
		_update_visual_state()
		if not Engine.is_editor_hint() and is_unlocked and not was_unlocked and is_inside_tree():
			VfxBurst.spawn_burst(get_parent(), VFX_SOLVED_PATH, global_position + Vector2(16.0, 4.0), 10, 42.0, -32.0)

var _gate_sprite: Sprite2D = null
var _status_label: Label = null
var _pulse_time: float = 0.0


func _ready() -> void:
	_rebuild_visuals()
	_update_visual_state()
	if not Engine.is_editor_hint():
		if not body_entered.is_connected(_on_body_entered):
			body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_pulse_time += delta
	if is_instance_valid(_gate_sprite):
		if is_unlocked:
			_gate_sprite.frame = 2
		else:
			_gate_sprite.frame = 1 if int(_pulse_time / 0.45) % 2 == 1 else 0


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

	_gate_sprite = Sprite2D.new()
	_gate_sprite.name = "GateSprite"
	_gate_sprite.centered = false
	_gate_sprite.position = Vector2(0.0, -20.0)
	_gate_sprite.texture = load(GATE_SHEET_PATH)
	_gate_sprite.hframes = 3
	_gate_sprite.frame = 2 if is_unlocked else 0
	_gate_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_gate_sprite)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.scale = Vector2(0.4, 0.4)
	_status_label.position = Vector2(-6.0, -34.0)
	add_child(_status_label)

	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28.0, 40.0)
	col.shape = rect
	col.position = Vector2(16.0, 6.0)
	add_child(col)


func _update_visual_state() -> void:
	if is_instance_valid(_gate_sprite):
		_gate_sprite.frame = 2 if is_unlocked else 0
	if is_instance_valid(_status_label):
		_status_label.text = "EXIT [BUKA]" if is_unlocked else "EXIT [KUNCI]"
		_status_label.modulate = Color(0.35, 1.0, 0.55) if is_unlocked else Color(1.0, 0.45, 0.45)
