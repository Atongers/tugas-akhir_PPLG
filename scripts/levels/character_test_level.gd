extends Node2D

@onready var dex: DexController = $Dex
@onready var prompt_label: Label = $TerminalArea/PromptLabel
@onready var feedback_label: Label = $HUD/PanelContainer/MarginContainer/VBoxContainer/FeedbackLabel

var _near_terminal: bool = false


func _ready() -> void:
	var term_area: Area2D = $TerminalArea
	if term_area:
		term_area.body_entered.connect(_on_terminal_body_entered)
		term_area.body_exited.connect(_on_terminal_body_exited)

	if prompt_label:
		prompt_label.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if _near_terminal and event.is_action_pressed("interact"):
		if feedback_label:
			feedback_label.text = "Status: [E] Terminal 1/1 berhasil diakses oleh Dex!"
			feedback_label.modulate = Color(0.4, 1.0, 0.5)


func _on_terminal_body_entered(body: Node2D) -> void:
	if body == dex:
		_near_terminal = true
		if prompt_label:
			prompt_label.visible = true


func _on_terminal_body_exited(body: Node2D) -> void:
	if body == dex:
		_near_terminal = false
		if prompt_label:
			prompt_label.visible = false
