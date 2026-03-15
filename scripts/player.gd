class_name Player
extends CharacterBody2D
## Simple placeholder player — a white circle that moves with WASD or
## arrow keys and collides with wall tiles.

const MAX_SPEED := 300

@export var FRICTION := 0.1
@export var ACCELERATION := 50

var direction := Vector2.ZERO

@onready var sprite := $AnimatedSprite2D

# Set to true during room transitions to prevent movement.
var frozen := false

func _physics_process(_delta: float) -> void:
	if frozen:
		velocity = Vector2.ZERO
		return

	move()
	move_and_slide()
	velocity = lerp(velocity, Vector2.ZERO, FRICTION)

func move() -> void:
	direction = Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		direction.x -= 1
		sprite.flip_h = true
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		direction.x += 1
		sprite.flip_h = false
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		direction.y += 1

	direction = direction.normalized()
	velocity += direction * ACCELERATION
	# clamp velocity, by vector2d parts
	velocity = Vector2(
		clamp(velocity.x, -MAX_SPEED, MAX_SPEED),
		clamp(velocity.y, -MAX_SPEED, MAX_SPEED)
	)