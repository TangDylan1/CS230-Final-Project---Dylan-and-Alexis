extends Node2D

@export var speed := 900.0
@export var lifetime := 1.2

@onready var body: RigidBody2D = $RigidBody2D
@onready var star_animation: AnimationPlayer = $RigidBody2D/AnimationPlayer

const WORLD_LAYER := 1
const PLAYER_LAYER := 2
const ENEMY_LAYER := 3
const FURNITURE_LAYER := 4
const PROJECTILE_LAYER := 5

func _ready() -> void:
	body.set_collision_layer_value(PROJECTILE_LAYER, true)
	body.set_collision_mask_value(WORLD_LAYER, true)
	body.set_collision_mask_value(PLAYER_LAYER, false)
	body.set_collision_mask_value(ENEMY_LAYER, true)
	body.set_collision_mask_value(FURNITURE_LAYER, false)

	body.contact_monitor = true
	body.max_contacts_reported = 1
	body.body_entered.connect(_on_body_entered)

	star_animation.play("spinning")
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func launch(dir: Vector2) -> void:
	dir = dir.normalized()
	rotation = dir.angle()
	body.linear_velocity = dir * speed

func _on_body_entered(hit_body: Node) -> void:
	print("Hit body: ", hit_body)
	if hit_body is EnemyBase:
		hit_body.apply_damage(GameManager.get_star_damage())
		queue_free()
	elif hit_body.has_method("apply_damage"):
		hit_body.apply_damage(GameManager.get_star_damage())
		queue_free()
	elif not hit_body.is_in_group("player"):
		queue_free()
