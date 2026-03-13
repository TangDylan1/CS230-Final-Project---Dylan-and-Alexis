class_name Player
extends CharacterBody2D
## Simple placeholder player — a white circle that moves with WASD or
## arrow keys and collides with wall tiles.

const SPEED  := 180.0
const RADIUS := 10.0

# Set to true during room transitions to prevent movement.
var frozen := false


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color.WHITE)


func _physics_process(_delta: float) -> void:
	if frozen:
		velocity = Vector2.ZERO
		return

	var input := Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		input.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		input.x += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		input.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		input.y += 1.0

	velocity = input.limit_length(1.0) * SPEED
	move_and_slide()
