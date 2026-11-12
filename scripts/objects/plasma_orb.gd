extends Area2D
class_name PlasmaOrb

signal hit_player(player: Node2D)

const ORB_TEX_PATH := "res://assets/sprites/objects/turret_plasma_orb.png"

@export var speed: float = 140.0
@export var lifetime: float = 4.0

var direction: Vector2 = Vector2.RIGHT
var _time_alive: float = 0.0
var _sprite: Sprite2D = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 2 # World (1) and Player (2)
	body_entered.connect(_on_body_entered)

	_sprite = Sprite2D.new()
	_sprite.name = "OrbSprite"
	if ResourceLoader.exists(ORB_TEX_PATH):
		_sprite.texture = load(ORB_TEX_PATH)
	_sprite.centered = true
	add_child(_sprite)

	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	cs.shape = circle
	add_child(cs)


func _process(delta: float) -> void:
	global_position += direction * speed * delta
	_time_alive += delta

	# Gentle pulse effect
	if is_instance_valid(_sprite):
		var s := 1.0 + sin(_time_alive * 16.0) * 0.15
		_sprite.scale = Vector2(s, s)

	if _time_alive >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D or body.name.to_lower().contains("dex"):
		hit_player.emit(body)
	# Destroy on contact with world or player
	queue_free()
