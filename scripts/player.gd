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

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * SPEED
	move_and_slide()
