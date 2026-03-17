class_name EnemyBase
extends CharacterBody2D

signal died(enemy: EnemyBase)

enum EnemyType { SOLDIER, RANGED, FLYING, TANK }

@export var enemy_type: EnemyType = EnemyType.SOLDIER
@export var max_health: int = 3
@export var move_speed: float = 80.0
@export var aggro_range: float = 425.0
@export var attack_range: float = 40.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.0
@export var coin_min: int = 4
@export var coin_max: int = 6
@export var draw_color: Color = Color.RED
@export var draw_radius: float = 10.0
@export var draw_circles: bool = true
@export var draw_attack_range: bool = false
@export var attack_range_color: Color = Color(1.0, 0.35, 0.2, 0.7)
@export var contact_hit_idle_cooldown: float = 0.5

# Wobble for flying enemies
@export var wobble_amplitude: float = 0.0
@export var wobble_speed: float = 5.0

var current_health: int
var attack_timer: float = 0.0
var contact_hit_idle_timer: float = 0.0
var frozen: bool = false
var _wobble_time: float = 0.0
var _is_dead: bool = false
var been_attacked: bool = false

const COIN_SCENE_PATH := "res://scenes/coin.tscn"
const WORLD_LAYER := 1
const PLAYER_LAYER := 3
const ENEMY_LAYER := 4

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")
	set_collision_layer_value(ENEMY_LAYER, true)
	set_collision_mask_value(WORLD_LAYER, true)
	set_collision_mask_value(PLAYER_LAYER, true)
	set_collision_mask_value(ENEMY_LAYER, true)
	_wobble_time = randf() * TAU


func _draw() -> void:
	if draw_circles:
		draw_circle(Vector2.ZERO, draw_radius, draw_color)
	if draw_attack_range:
		draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 64, attack_range_color, 2.0)


func get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Node2D
	return null


func distance_to_player() -> float:
	var player := get_player()
	if player:
		return global_position.distance_to(player.global_position)
	return INF


func direction_to_player() -> Vector2:
	var player := get_player()
	if player:
		return (player.global_position - global_position).normalized()
	return Vector2.ZERO


func apply_damage(amount: int) -> void:
	been_attacked = true
	if _is_dead:
		return
	current_health -= amount
	_flash_damage()
	if current_health <= 0:
		_die()


func _flash_damage() -> void:
	modulate = Color(10, 10, 10)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)


func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	_spawn_coins()
	died.emit(self)
	set_physics_process(false)
	set_process(false)

	# Brief shrink animation then free
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(queue_free)


func _spawn_coins() -> void:
	var coin_count := randi_range(coin_min, coin_max)
	for i in coin_count:
		var coin_scene: PackedScene = load(COIN_SCENE_PATH)
		if coin_scene == null:
			return
		var coin := coin_scene.instantiate()
		get_tree().current_scene.add_child(coin)
		coin.global_position = global_position
		# Scatter offset
		var angle := randf() * TAU
		var dist := randf_range(12.0, 36.0)
		var offset := Vector2(cos(angle), sin(angle)) * dist
		var tw := coin.create_tween()
		tw.tween_property(coin, "global_position", global_position + offset, 0.25) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
