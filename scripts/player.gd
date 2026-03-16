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

	move_and_slide()
	velocity = lerp(velocity, Vector2.ZERO, FRICTION)


# Return normalized player input direction
func get_input_direction() -> Vector2:
	var input_direction := Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		input_direction.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		input_direction.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		input_direction.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		input_direction.y += 1

	return input_direction.normalized()
