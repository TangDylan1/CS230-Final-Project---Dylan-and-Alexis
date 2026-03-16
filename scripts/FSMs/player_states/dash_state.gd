extends State
class_name DashState

@export var dash_duration: float = 0.18

var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var dash_speed: float = 0.0

func enter() -> void:
	print("Entering player DashState")

	var character := fsm.get_parent() as Player

	if character == null:
		return

	dash_speed = character.DASH_SPEED
	character.dash_cooldown = 1.0

	# Save the dash direction
	dash_direction = character.get_input_direction().normalized()

	# If no input direction, just dash in the current mouse direction
	if dash_direction == Vector2.ZERO:
		dash_direction = (character.get_global_mouse_position() - character.global_position).normalized()
		dash_speed *= 0.7 # I think that without movement, friction isnt strong enough, so reduce dash speed to match dash with movement

	dash_timer = dash_duration

	character.dash_velocity = dash_direction * dash_speed


func exit() -> void:
	print("Exiting player DashState")
	var character := fsm.get_parent() as Player

	if character == null:
		return

	character.dash_velocity = Vector2.ZERO


func physics_update(delta: float) -> void:
	var character := fsm.get_parent() as Player

	if character == null:
		return

	dash_timer -= delta

	# Keep moving in the locked dash direction
	character.dash_velocity = dash_direction * dash_speed

	if dash_timer <= 0.0:
		if character.get_input_direction() == Vector2.ZERO:
			fsm.change_state("idlestate")
		else:
			fsm.change_state("walkstate")
