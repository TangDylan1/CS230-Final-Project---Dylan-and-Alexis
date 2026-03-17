extends Node2D

@export var speed := 900.0
@export var lifetime := 1.2

@onready var body: RigidBody2D = $RigidBody2D
@onready var star_animation: AnimationPlayer = $RigidBody2D/AnimationPlayer

func _ready() -> void:
	body.gravity_scale = 0.0
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
	if hit_body is EnemyBase:
		hit_body.apply_damage(GameManager.get_star_damage())
		queue_free()
	elif not hit_body.is_in_group("player"):
		queue_free()